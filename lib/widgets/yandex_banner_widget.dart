import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

class YandexBannerWidget extends StatefulWidget {
  const YandexBannerWidget({super.key});

  @override
  State<YandexBannerWidget> createState() => _YandexBannerWidgetState();
}

class _YandexBannerWidgetState extends State<YandexBannerWidget> {
  BannerAd? _banner;
  StreamSubscription<BannerAdLoadState>? _sub;
  bool _isLoaded = false;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted && AdService().isSupportedPlatform) {
      _loadStarted = true;
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    try {
      final width = MediaQuery.of(context).size.width.round().clamp(300, 728);
      final banner = BannerAd(
        adSize: BannerAdSize.sticky(width: width),
      );

      _sub = banner.loadStateStream.listen((state) {
        if (!mounted) return;
        if (state is BannerAdLoadStateLoaded) {
          setState(() => _isLoaded = true);
        } else if (state is BannerAdLoadStateError) {
          setState(() => _isLoaded = false);
        }
      });

      _banner = banner;
      await banner.load(
        AdRequest(
          adUnitId: AdConfig.bannerUnitId,
          preferredTheme: AdTheme.dark,
        ),
      );
    } on MissingPluginException {
      // Safe fallback in test environment
    } catch (e) {
      debugPrint('Banner load error: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _banner?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null || !AdService().isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppColors.bgSecondary,
      alignment: Alignment.center,
      child: Visibility(
        visible: _isLoaded,
        maintainState: true,
        child: AdWidget(bannerAd: banner),
      ),
    );
  }
}
