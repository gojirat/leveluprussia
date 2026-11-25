import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_item.dart';
import '../models/learning_models.dart';

class AppState extends ChangeNotifier {
  static const _kProgress = '@english_words_progress';
  static const _kFavorites = '@english_words_favorites';
  static const _kStreak = '@english_words_streak';
  static const _kDailyStats = '@english_words_daily_stats';
  static const _kSessions = '@english_words_sessions';
  static const _kAchievements = '@english_words_achievements';
  static const _kSettings = '@english_words_settings';
  static const _kWelcomeShown = '@english_words_welcome_shown';
  static const _kCustomWords = '@english_words_custom_words';
  static const _kBestMatchSeconds = '@english_words_best_match_sec';

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _welcomeShown = false;
  bool get welcomeShown => _welcomeShown;

  List<WordItem> _words = const [];
  List<WordItem> get words => _words;

  final Map<String, List<WordItem>> _wordsByLevel = {};
  final Map<String, WordItem> _wordsById = {};

  List<CustomWord> _customWords = [];
  List<CustomWord> get customWords => _customWords;

  int? _bestMatchSeconds;
  int? get bestMatchSeconds => _bestMatchSeconds;

  Map<String, WordProgress> _progress = {};
  Map<String, WordProgress> get progress => _progress;

  Set<String> _favorites = {};
  Set<String> get favorites => _favorites;

  StreakData _streak = const StreakData();
  StreakData get streak => _streak;

  Map<String, DailyStats> _dailyStats = {};
  Map<String, DailyStats> get dailyStats => _dailyStats;

  List<SessionRecord> _sessions = [];
  List<SessionRecord> get sessions => _sessions;

  Map<String, DateTime> _unlockedAchievements = {};
  Map<String, DateTime> get unlockedAchievements => _unlockedAchievements;

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  Future<void> init() async {
    final rawJson = await rootBundle.loadString('assets/data/words.json');
    final List<dynamic> parsed = jsonDecode(rawJson) as List<dynamic>;
    _words = parsed
        .map((e) => WordItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    _wordsByLevel.clear();
    _wordsById.clear();
    for (final w in _words) {
      _wordsById[w.id] = w;
      _wordsByLevel.putIfAbsent(w.level, () => []).add(w);
    }

    final prefs = await SharedPreferences.getInstance();
    _welcomeShown = prefs.getBool(_kWelcomeShown) ?? false;
    _bestMatchSeconds = prefs.getInt(_kBestMatchSeconds);

    final progressRaw = prefs.getString(_kProgress);
    if (progressRaw != null) {
      try {
        final decoded = jsonDecode(progressRaw) as Map<String, dynamic>;
        _progress = decoded.map(
          (k, v) => MapEntry(k, WordProgress.fromJson(v as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    final customRaw = prefs.getString(_kCustomWords);
    if (customRaw != null) {
      try {
        final decoded = jsonDecode(customRaw) as List<dynamic>;
        _customWords = decoded
            .map((e) => CustomWord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final favRaw = prefs.getStringList(_kFavorites);
    if (favRaw != null) {
      _favorites = favRaw.toSet();
    }

    final streakRaw = prefs.getString(_kStreak);
    if (streakRaw != null) {
      try {
        _streak = StreakData.fromJson(
          jsonDecode(streakRaw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    final dailyRaw = prefs.getString(_kDailyStats);
    if (dailyRaw != null) {
      try {
        final decoded = jsonDecode(dailyRaw) as Map<String, dynamic>;
        _dailyStats = decoded.map(
          (k, v) => MapEntry(k, DailyStats.fromJson(v as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    final sessionsRaw = prefs.getString(_kSessions);
    if (sessionsRaw != null) {
      try {
        final decoded = jsonDecode(sessionsRaw) as List<dynamic>;
        _sessions = decoded
            .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final achRaw = prefs.getString(_kAchievements);
    if (achRaw != null) {
      try {
        final decoded = jsonDecode(achRaw) as Map<String, dynamic>;
        _unlockedAchievements = decoded.map(
          (k, v) => MapEntry(k, DateTime.tryParse(v as String) ?? DateTime.now()),
        );
      } catch (_) {}
    }

    final settingsRaw = prefs.getString(_kSettings);
    if (settingsRaw != null) {
      try {
        _settings = AppSettings.fromJson(
          jsonDecode(settingsRaw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    _isLoaded = true;
    notifyListeners();
  }

  // --- Helpers ---
  List<WordItem> wordsForLevel(String level) {
    if (level == 'ALL') return _words;
    if (level == 'MY') {
      return _customWords
          .map(
            (c) => WordItem(
              id: c.id,
              word: c.word,
              translation: c.translation,
              phonetic: c.note,
              level: 'MY',
            ),
          )
          .toList();
    }
    return _wordsByLevel[level] ?? const [];
  }

  WordItem? wordById(String id) => _wordsById[id];

  bool isFavorite(String wordId) => _favorites.contains(wordId);

  List<WordItem> get favoriteWords =>
      _words.where((w) => _favorites.contains(w.id)).toList();

  WordProgress? progressForWord(String wordId) => _progress[wordId];

  int get totalLearnedCount =>
      _progress.values.where((p) => p.isLearned).length;

  int get totalMasteredCount =>
      _progress.values.where((p) => p.isMastered).length;

  /// Words scheduled for SM-2 spaced repetition review today
  List<WordItem> get dueForReviewWords {
    final now = DateTime.now();
    final due = <WordItem>[];
    for (final entry in _progress.entries) {
      if (!entry.value.nextReviewAt.isAfter(now)) {
        final w = _wordsById[entry.key];
        if (w != null) due.add(w);
      }
    }
    return due;
  }

  int learnedCountForLevel(String level) {
    final list = wordsForLevel(level);
    int c = 0;
    for (final w in list) {
      if (_progress[w.id]?.isLearned == true) c++;
    }
    return c;
  }

  String _dateKey(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  String _todayKey() => _dateKey(DateTime.now());

  DailyStats get todayStats =>
      _dailyStats[_todayKey()] ?? DailyStats(date: _todayKey());

  /// Last 7 days activity for the weekly bar chart
  List<DailyStats> get last7DaysStats {
    final now = DateTime.now();
    return List.generate(7, (idx) {
      final dt = now.subtract(Duration(days: 6 - idx));
      final key = _dateKey(dt);
      return _dailyStats[key] ?? DailyStats(date: key);
    });
  }

  int get totalStudySeconds =>
      _dailyStats.values.fold(0, (sum, d) => sum + d.durationSeconds);

  int get overallAccuracy {
    int correct = 0;
    int total = 0;
    for (final s in _sessions) {
      correct += s.correctCount;
      total += s.totalWords;
    }
    if (total == 0) return 0;
    return ((correct / total) * 100).round();
  }

  List<WordItem> pickSessionWords({
    required String level,
    required int count,
    required bool favoritesOnly,
  }) {
    final pool = wordsForLevel(level)
        .where((w) => !favoritesOnly || _favorites.contains(w.id))
        .toList();
    if (pool.isEmpty) return const [];

    final rng = Random();
    final dueNow = <WordItem>[];
    final unlearned = <WordItem>[];
    final learning = <WordItem>[];
    final mastered = <WordItem>[];

    for (final w in pool) {
      final p = _progress[w.id];
      if (p != null && p.isDueNow) {
        dueNow.add(w);
      } else if (p == null || !p.isLearned) {
        unlearned.add(w);
      } else if (!p.isMastered) {
        learning.add(w);
      } else {
        mastered.add(w);
      }
    }

    dueNow.shuffle(rng);
    unlearned.shuffle(rng);
    learning.shuffle(rng);
    mastered.shuffle(rng);

    final combined = [...dueNow, ...unlearned, ...learning, ...mastered];
    return combined.take(min(count, combined.length)).toList();
  }

  // --- Custom Personal Words CRUD ---
  Future<void> addCustomWord({
    required String word,
    required String translation,
    String note = '',
  }) async {
    final item = CustomWord(
      id: 'my_${DateTime.now().millisecondsSinceEpoch}',
      word: word.trim(),
      translation: translation.trim(),
      note: note.trim(),
      createdAt: DateTime.now(),
    );
    _customWords.insert(0, item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCustomWords,
      jsonEncode(_customWords.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteCustomWord(String id) async {
    _customWords.removeWhere((e) => e.id == id);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCustomWords,
      jsonEncode(_customWords.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> recordMatchGameTime(int seconds) async {
    if (_bestMatchSeconds == null || seconds < _bestMatchSeconds!) {
      _bestMatchSeconds = seconds;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kBestMatchSeconds, seconds);
    }
  }

  // --- Mutations ---
  Future<void> setWelcomeShown(bool shown) async {
    _welcomeShown = shown;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWelcomeShown, shown);
  }

  Future<void> toggleFavorite(String wordId) async {
    if (_favorites.contains(wordId)) {
      _favorites.remove(wordId);
    } else {
      _favorites.add(wordId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavorites, _favorites.toList());
  }

  Future<void> updateSettings(AppSettings next) async {
    _settings = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettings, jsonEncode(_settings.toJson()));
  }

  /// SM-2 Spaced Repetition answer recording
  Future<void> recordSrsRating(String wordId, SrsRating rating) async {
    final prev = _progress[wordId];
    final now = DateTime.now();
    final prevInterval = prev?.intervalDays ?? 1;
    final prevEase = prev?.easeFactor ?? 2.5;

    late int nextInterval;
    late double nextEase;
    late DateTime nextReview;
    bool isCorrect = rating != SrsRating.again;

    switch (rating) {
      case SrsRating.again:
        nextInterval = 0;
        nextEase = max(1.3, prevEase - 0.2);
        nextReview = now.add(const Duration(minutes: 10));
        break;
      case SrsRating.hard:
        nextInterval = max(1, (prevInterval * 1.2).round());
        nextEase = max(1.3, prevEase - 0.15);
        nextReview = now.add(Duration(days: nextInterval));
        break;
      case SrsRating.good:
        nextInterval = prev == null
            ? 1
            : (prevInterval <= 1 ? 3 : (prevInterval * prevEase).round());
        nextEase = prevEase;
        nextReview = now.add(Duration(days: nextInterval));
        break;
      case SrsRating.easy:
        nextInterval = prev == null
            ? 4
            : max(4, (prevInterval * prevEase * 1.3).round());
        nextEase = min(3.0, prevEase + 0.15);
        nextReview = now.add(Duration(days: nextInterval));
        break;
    }

    _progress[wordId] = WordProgress(
      wordId: wordId,
      correctCount: (prev?.correctCount ?? 0) + (isCorrect ? 1 : 0),
      incorrectCount: (prev?.incorrectCount ?? 0) + (isCorrect ? 0 : 1),
      lastReviewed: now,
      intervalDays: nextInterval,
      easeFactor: nextEase,
      nextReviewAt: nextReview,
    );

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kProgress,
      jsonEncode(_progress.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  Future<void> recordWordAnswer(String wordId, bool isCorrect) {
    return recordSrsRating(
      wordId,
      isCorrect ? SrsRating.good : SrsRating.again,
    );
  }

  Future<List<AchievementDef>> completeSession({
    required String mode,
    required String level,
    required int totalWords,
    required int correctCount,
    required int durationSeconds,
    required int maxCorrectStreak,
  }) async {
    final now = DateTime.now();
    final session = SessionRecord(
      id: '${now.millisecondsSinceEpoch}',
      mode: mode,
      level: level,
      totalWords: totalWords,
      correctCount: correctCount,
      durationSeconds: max(1, durationSeconds),
      maxCorrectStreak: maxCorrectStreak,
      completedAt: now,
    );
    _sessions.insert(0, session);
    if (_sessions.length > 200) {
      _sessions = _sessions.sublist(0, 200);
    }

    final today = _todayKey();
    final prevDaily = _dailyStats[today] ?? DailyStats(date: today);
    _dailyStats[today] = DailyStats(
      date: today,
      wordsReviewed: prevDaily.wordsReviewed + totalWords,
      correctAnswers: prevDaily.correctAnswers + correctCount,
      totalAnswers: prevDaily.totalAnswers + totalWords,
      durationSeconds: prevDaily.durationSeconds + max(1, durationSeconds),
    );

    _updateStreakForToday(today);
    final newlyUnlocked = _checkAchievements(session);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(
        _kSessions,
        jsonEncode(_sessions.map((s) => s.toJson()).toList()),
      ),
      prefs.setString(
        _kDailyStats,
        jsonEncode(_dailyStats.map((k, v) => MapEntry(k, v.toJson()))),
      ),
      prefs.setString(_kStreak, jsonEncode(_streak.toJson())),
      prefs.setString(
        _kAchievements,
        jsonEncode(
          _unlockedAchievements
              .map((k, v) => MapEntry(k, v.toIso8601String())),
        ),
      ),
    ]);

    return newlyUnlocked;
  }

  void _updateStreakForToday(String today) {
    final last = _streak.lastActivityDate;
    if (last == today) {
      if (_streak.currentStreak == 0) {
        _streak = StreakData(
          currentStreak: 1,
          bestStreak: max(1, _streak.bestStreak),
          lastActivityDate: today,
        );
      }
      return;
    }

    int nextStreak = 1;
    if (last != null) {
      final lastDate = DateTime.tryParse(last);
      final todayDate = DateTime.tryParse(today);
      if (lastDate != null && todayDate != null) {
        final diff = todayDate.difference(lastDate).inDays;
        if (diff == 1) {
          nextStreak = _streak.currentStreak + 1;
        }
      }
    }

    _streak = StreakData(
      currentStreak: nextStreak,
      bestStreak: max(nextStreak, _streak.bestStreak),
      lastActivityDate: today,
    );
  }

  List<AchievementDef> _checkAchievements(SessionRecord session) {
    final learned = totalLearnedCount;
    final totalSessions = _sessions.length;
    final totalMinutes = totalStudySeconds ~/ 60;
    final accuracy = session.accuracy;
    final now = DateTime.now();
    final newlyUnlocked = <AchievementDef>[];

    void tryUnlock(String id, bool condition) {
      if (condition && !_unlockedAchievements.containsKey(id)) {
        _unlockedAchievements[id] = now;
        final def = AchievementDef.all.firstWhere((a) => a.id == id);
        newlyUnlocked.add(def);
      }
    }

    tryUnlock('first_word', learned >= 1);
    tryUnlock('words_10', learned >= 10);
    tryUnlock('words_50', learned >= 50);
    tryUnlock('words_100', learned >= 100);
    tryUnlock('words_500', learned >= 500);
    tryUnlock('streak_3', _streak.bestStreak >= 3);
    tryUnlock('streak_7', _streak.bestStreak >= 7);
    tryUnlock('streak_30', _streak.bestStreak >= 30);
    tryUnlock('sessions_10', totalSessions >= 10);
    tryUnlock('sessions_50', totalSessions >= 50);
    tryUnlock('accuracy_80', session.totalWords >= 5 && accuracy >= 80);
    tryUnlock('accuracy_100', session.totalWords >= 5 && accuracy == 100);
    tryUnlock('streak_correct_10', session.maxCorrectStreak >= 10);
    tryUnlock('streak_correct_20', session.maxCorrectStreak >= 20);
    tryUnlock('time_60', totalMinutes >= 60);

    return newlyUnlocked;
  }

  Future<void> clearAllProgress() async {
    _progress = {};
    _favorites = {};
    _streak = const StreakData();
    _dailyStats = {};
    _sessions = [];
    _unlockedAchievements = {};
    _bestMatchSeconds = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kProgress),
      prefs.remove(_kFavorites),
      prefs.remove(_kStreak),
      prefs.remove(_kDailyStats),
      prefs.remove(_kSessions),
      prefs.remove(_kAchievements),
      prefs.remove(_kBestMatchSeconds),
    ]);
  }
}
