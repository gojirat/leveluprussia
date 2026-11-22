import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_example.dart';

class DictionaryService {
  static const _cacheKey = '@english_words_dictionary_cache';
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  final Map<String, List<DictionaryExample>> _memoryCache = {};
  bool _cacheLoaded = false;

  Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final list = (entry.value as List<dynamic>)
              .map((e) => DictionaryExample.fromJson(e as Map<String, dynamic>))
              .toList();
          _memoryCache[entry.key] = list;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmedKeys = _memoryCache.keys.toList();
      final Map<String, dynamic> out = {};
      // Keep last 150 cached words to keep storage compact
      final start = trimmedKeys.length > 150 ? trimmedKeys.length - 150 : 0;
      for (final k in trimmedKeys.sublist(start)) {
        out[k] = _memoryCache[k]!.map((e) => e.toJson()).toList();
      }
      await prefs.setString(_cacheKey, jsonEncode(out));
    } catch (_) {}
  }

  Future<List<DictionaryExample>> fetchExamples(String word) async {
    final cleanWord = word.trim().toLowerCase();
    await _loadCache();
    if (_memoryCache.containsKey(cleanWord)) {
      return _memoryCache[cleanWord]!;
    }

    try {
      final uri = Uri.parse(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(cleanWord)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        return const [];
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final List<DictionaryExample> results = [];

      for (final entry in data) {
        final meanings = (entry['meanings'] as List<dynamic>?) ?? const [];
        for (final meaning in meanings) {
          final pos = (meaning['partOfSpeech'] as String?) ?? '';
          final defs = (meaning['definitions'] as List<dynamic>?) ?? const [];
          for (final d in defs) {
            final defText = (d['definition'] as String?) ?? '';
            final exText = d['example'] as String?;
            if (defText.isNotEmpty) {
              results.add(DictionaryExample(
                partOfSpeech: pos,
                definition: defText,
                example: exText,
              ));
            }
            if (results.length >= 4) break;
          }
          if (results.length >= 4) break;
        }
        if (results.length >= 4) break;
      }

      _memoryCache[cleanWord] = results;
      await _saveCache();
      return results;
    } catch (_) {
      return const [];
    }
  }
}
