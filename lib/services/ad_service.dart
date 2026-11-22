import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

class AdConfig {
  static const String appId = '20469430';

  // Real Yandex Mobile Ads Unit IDs (used in release/profile builds)
  static const String prodBannerUnitId = 'R-M-20469430-3';
  static const String prodRewardedUnitId = 'R-M-20469430-2';
  static const String prodInterstitialUnitId = 'R-M-20469430-1';

  // Official Yandex demo Unit IDs (used in debug mode for reliable local testing)
  static const String demoBannerUnitId = 'demo-banner-yandex';
  static const String demoRewardedUnitId = 'demo-rewarded-yandex';
  static const String demoInterstitialUnitId = 'demo-interstitial-yandex';

  static String get bannerUnitId =>
      kDebugMode ? demoBannerUnitId : prodBannerUnitId;

  static String get rewardedUnitId =>
      kDebugMode ? demoRewardedUnitId : prodRewardedUnitId;

  static String get interstitialUnitId =>
      kDebugMode ? demoInterstitialUnitId : prodInterstitialUnitId;
}

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;
  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  InterstitialAdLoader? _interstitialLoader;
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

  RewardedAdLoader? _rewardedLoader;
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  int _completedSessionsCount = 0;
  DateTime? _lastInterstitialShownAt;

  bool get isRewardedReady => _rewardedAd != null;

  Future<void> initialize() async {
    if (_initialized || !isSupportedPlatform) return;
    _initialized = true;

    try {
      // Request iOS App Tracking Transparency cleanly when app is active
      if (Platform.isIOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await Future.delayed(const Duration(milliseconds: 600));
          final nextStatus =
              await AppTrackingTransparency.requestTrackingAuthorization();
          await YandexAds.setUserConsent(
            nextStatus == TrackingStatus.authorized,
          );
        } else {
          await YandexAds.setUserConsent(status == TrackingStatus.authorized);
        }
      }

      if (kDebugMode) {
        await YandexAds.setLogging(true);
      }
      await YandexAds.initialize();

      _interstitialLoader = InterstitialAdLoader();
      _rewardedLoader = RewardedAdLoader();

      unawaited(preloadInterstitial());
      unawaited(preloadRewarded());
    } on MissingPluginException {
      // Safe fallback in unit/widget test environments
    } catch (e) {
      debugPrint('YandexAds init error: $e');
    }
  }

  Future<void> preloadInterstitial() async {
    if (!isSupportedPlatform ||
        _interstitialLoader == null ||
        _isLoadingInterstitial ||
        _interstitialAd != null) {
      return;
    }
    _isLoadingInterstitial = true;
    try {
      _interstitialAd = await _interstitialLoader!.loadAd(
        adRequest: AdRequest(
          adUnitId: AdConfig.interstitialUnitId,
          preferredTheme: AdTheme.dark,
        ),
      );
    } catch (e) {
      debugPrint('Interstitial preload failed: $e');
    } finally {
      _isLoadingInterstitial = false;
    }
  }

  Future<void> preloadRewarded() async {
    if (!isSupportedPlatform ||
        _rewardedLoader == null ||
        _isLoadingRewarded ||
        _rewardedAd != null) {
      return;
    }
    _isLoadingRewarded = true;
    try {
      _rewardedAd = await _rewardedLoader!.loadAd(
        adRequest: AdRequest(
          adUnitId: AdConfig.rewardedUnitId,
          preferredTheme: AdTheme.dark,
        ),
      );
    } catch (e) {
      debugPrint('Rewarded preload failed: $e');
    } finally {
      _isLoadingRewarded = false;
    }
  }

  /// Called after finishing a Flashcard or Quiz session.
  /// Shows an interstitial every 2nd session with at least a 45s cooldown.
  Future<void> onSessionCompleted() async {
    if (!isSupportedPlatform) return;
    _completedSessionsCount++;

    final now = DateTime.now();
    final cooldownPassed = _lastInterstitialShownAt == null ||
        now.difference(_lastInterstitialShownAt!).inSeconds >= 45;

    if (_completedSessionsCount % 2 != 0 || !cooldownPassed) {
      unawaited(preloadInterstitial());
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      unawaited(preloadInterstitial());
      return;
    }

    _interstitialAd = null;
    try {
      await ad.setAdEventListener(
        eventListener: InterstitialAdEventListener(
          onAdDismissed: () {},
          onAdFailedToShow: (_) {},
        ),
      );
      await ad.show();
      await ad.waitForDismiss();
      _lastInterstitialShownAt = DateTime.now();
    } catch (e) {
      debugPrint('Interstitial show error: $e');
    } finally {
      await ad.destroy();
      unawaited(preloadInterstitial());
    }
  }

  /// Shows a user-initiated rewarded ad. Returns true if the user earned the reward.
  Future<bool> showRewardedAd() async {
    if (!isSupportedPlatform) return false;

    RewardedAd? ad = _rewardedAd;
    _rewardedAd = null;

    if (ad == null && _rewardedLoader != null) {
      try {
        ad = await _rewardedLoader!.loadAd(
          adRequest: AdRequest(
            adUnitId: AdConfig.rewardedUnitId,
            preferredTheme: AdTheme.dark,
          ),
        );
      } catch (e) {
        debugPrint('Rewarded on-demand load failed: $e');
        return false;
      }
    }

    if (ad == null) return false;

    bool earned = false;
    try {
      await ad.setAdEventListener(
        eventListener: RewardedAdEventListener(
          onRewarded: (_) => earned = true,
          onAdDismissed: () {},
          onAdFailedToShow: (_) {},
        ),
      );
      await ad.show();
      final reward = await ad.waitForDismiss();
      if (reward != null) earned = true;
    } catch (e) {
      debugPrint('Rewarded show error: $e');
    } finally {
      await ad.destroy();
      unawaited(preloadRewarded());
    }
    return earned;
  }
}
