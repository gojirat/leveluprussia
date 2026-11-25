import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  TtsService._internal();

  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  /// Speaks [text] in English. Set [slow] to true for 0.7x Listening practice speed.
  Future<void> speak(String text, {bool slow = false}) async {
    try {
      await _ensureInit();
      await _tts.setSpeechRate(slow ? 0.32 : 0.48);
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
