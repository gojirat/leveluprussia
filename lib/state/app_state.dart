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

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _welcomeShown = false;
  bool get welcomeShown => _welcomeShown;

  List<WordItem> _words = const [];
  List<WordItem> get words => _words;

  final Map<String, List<WordItem>> _wordsByLevel = {};
  final Map<String, WordItem> _wordsById = {};

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
    // Load bundled 4,109 CEFR words
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

    // Progress
    final progressRaw = prefs.getString(_kProgress);
    if (progressRaw != null) {
      try {
        final decoded = jsonDecode(progressRaw) as Map<String, dynamic>;
        _progress = decoded.map(
          (k, v) => MapEntry(k, WordProgress.fromJson(v as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    // Favorites
    final favRaw = prefs.getStringList(_kFavorites);
    if (favRaw != null) {
      _favorites = favRaw.toSet();
    }

    // Streak
    final streakRaw = prefs.getString(_kStreak);
    if (streakRaw != null) {
      try {
        _streak = StreakData.fromJson(
          jsonDecode(streakRaw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    // Daily stats
    final dailyRaw = prefs.getString(_kDailyStats);
    if (dailyRaw != null) {
      try {
        final decoded = jsonDecode(dailyRaw) as Map<String, dynamic>;
        _dailyStats = decoded.map(
          (k, v) => MapEntry(k, DailyStats.fromJson(v as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    // Sessions
    final sessionsRaw = prefs.getString(_kSessions);
    if (sessionsRaw != null) {
      try {
        final decoded = jsonDecode(sessionsRaw) as List<dynamic>;
        _sessions = decoded
            .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Achievements
    final achRaw = prefs.getString(_kAchievements);
    if (achRaw != null) {
      try {
        final decoded = jsonDecode(achRaw) as Map<String, dynamic>;
        _unlockedAchievements = decoded.map(
          (k, v) => MapEntry(k, DateTime.tryParse(v as String) ?? DateTime.now()),
        );
      } catch (_) {}
    }

    // Settings
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

  int learnedCountForLevel(String level) {
    final list = wordsForLevel(level);
    int c = 0;
    for (final w in list) {
      if (_progress[w.id]?.isLearned == true) c++;
    }
    return c;
  }

  int masteredCountForLevel(String level) {
    final list = wordsForLevel(level);
    int c = 0;
    for (final w in list) {
      if (_progress[w.id]?.isMastered == true) c++;
    }
    return c;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  DailyStats get todayStats =>
      _dailyStats[_todayKey()] ?? DailyStats(date: _todayKey());

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

    // Prioritize unlearned and non-mastered words, shuffled within groups
    final rng = Random();
    final unlearned = <WordItem>[];
    final learning = <WordItem>[];
    final mastered = <WordItem>[];

    for (final w in pool) {
      final p = _progress[w.id];
      if (p == null || !p.isLearned) {
        unlearned.add(w);
      } else if (!p.isMastered) {
        learning.add(w);
      } else {
        mastered.add(w);
      }
    }

    unlearned.shuffle(rng);
    learning.shuffle(rng);
    mastered.shuffle(rng);

    final combined = [...unlearned, ...learning, ...mastered];
    return combined.take(min(count, combined.length)).toList();
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

  Future<void> recordWordAnswer(String wordId, bool isCorrect) async {
    final prev = _progress[wordId];
    final now = DateTime.now();
    if (prev == null) {
      _progress[wordId] = WordProgress(
        wordId: wordId,
        correctCount: isCorrect ? 1 : 0,
        incorrectCount: isCorrect ? 0 : 1,
        lastReviewed: now,
      );
    } else {
      _progress[wordId] = prev.copyWith(
        correctCount: prev.correctCount + (isCorrect ? 1 : 0),
        incorrectCount: prev.incorrectCount + (isCorrect ? 0 : 1),
        lastReviewed: now,
      );
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kProgress,
      jsonEncode(_progress.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  /// Saves completed session, updates streak & daily stats, and returns newly unlocked achievements.
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

    // Update daily stats
    final today = _todayKey();
    final prevDaily = _dailyStats[today] ?? DailyStats(date: today);
    _dailyStats[today] = DailyStats(
      date: today,
      wordsReviewed: prevDaily.wordsReviewed + totalWords,
      correctAnswers: prevDaily.correctAnswers + correctCount,
      totalAnswers: prevDaily.totalAnswers + totalWords,
      durationSeconds: prevDaily.durationSeconds + max(1, durationSeconds),
    );

    // Update streak
    _updateStreakForToday(today);

    // Check achievements
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
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kProgress),
      prefs.remove(_kFavorites),
      prefs.remove(_kStreak),
      prefs.remove(_kDailyStats),
      prefs.remove(_kSessions),
      prefs.remove(_kAchievements),
    ]);
  }
}
