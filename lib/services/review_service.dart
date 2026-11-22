import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Store–compliant rating service using Apple's native SKStoreReviewController
/// (via `in_app_review`) with no custom rating-gating or review filtering.
class ReviewService {
  static const String appStoreId = '6837854604';
  static const String _kLastPromptAt = '@english_words_last_review_prompt_at';
  static const int _minSessionsBeforePrompt = 2;
  static const int _cooldownDays = 90;

  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  /// Requests the native iOS/Android in-app review sheet after a completed
  /// learning session, respecting session threshold and cooldown.
  Future<void> maybeRequestReview({required int totalCompletedSessions}) async {
    if (kIsWeb || totalCompletedSessions < _minSessionsBeforePrompt) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRaw = prefs.getString(_kLastPromptAt);
      if (lastRaw != null) {
        final lastDate = DateTime.tryParse(lastRaw);
        if (lastDate != null &&
            DateTime.now().difference(lastDate).inDays < _cooldownDays) {
          return;
        }
      }

      if (await _inAppReview.isAvailable()) {
        await Future.delayed(const Duration(milliseconds: 900));
        await _inAppReview.requestReview();
        await prefs.setString(_kLastPromptAt, DateTime.now().toIso8601String());
      }
    } on MissingPluginException {
      // Safe fallback in unit/widget test environments
    } catch (e) {
      debugPrint('InAppReview error: $e');
    }
  }

  /// Opens the official App Store review page directly (used by the manual
  /// "Оценить приложение" button in Profile/Settings, per Apple HIG).
  Future<void> openAppStoreReview() async {
    try {
      await _inAppReview.openStoreListing(appStoreId: appStoreId);
    } on MissingPluginException {
      // Safe fallback in test environments
    } catch (e) {
      debugPrint('openStoreListing error: $e');
    }
  }
}
