class WordProgress {
  final String wordId;
  final int correctCount;
  final int incorrectCount;
  final DateTime lastReviewed;
  // SM-2 Spaced Repetition fields
  final int intervalDays;
  final double easeFactor;
  final DateTime nextReviewAt;

  WordProgress({
    required this.wordId,
    required this.correctCount,
    required this.incorrectCount,
    required this.lastReviewed,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    DateTime? nextReviewAt,
  }) : nextReviewAt = nextReviewAt ?? lastReviewed.add(const Duration(days: 1));

  bool get isLearned => correctCount >= 1;
  bool get isMastered => correctCount >= 3 && intervalDays >= 6;
  bool get isDueNow => !nextReviewAt.isAfter(DateTime.now());

  WordProgress copyWith({
    int? correctCount,
    int? incorrectCount,
    DateTime? lastReviewed,
    int? intervalDays,
    double? easeFactor,
    DateTime? nextReviewAt,
  }) {
    return WordProgress(
      wordId: wordId,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }

  factory WordProgress.fromJson(Map<String, dynamic> json) {
    final last = DateTime.tryParse(json['lastReviewed'] as String? ?? '') ??
        DateTime.now();
    final interval = (json['intervalDays'] as num?)?.toInt() ?? 1;
    return WordProgress(
      wordId: json['wordId'] as String,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      incorrectCount: (json['incorrectCount'] as num?)?.toInt() ?? 0,
      lastReviewed: last,
      intervalDays: interval,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      nextReviewAt: DateTime.tryParse(json['nextReviewAt'] as String? ?? '') ??
          last.add(Duration(days: interval)),
    );
  }

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'lastReviewed': lastReviewed.toIso8601String(),
        'intervalDays': intervalDays,
        'easeFactor': easeFactor,
        'nextReviewAt': nextReviewAt.toIso8601String(),
      };
}

/// SM-2 ease ratings for spaced repetition flashcards
enum SrsRating {
  again, // 0: forgot -> review again soon (10 min / today)
  hard, // 1: difficult -> short interval
  good, // 2: remembered -> standard SM-2 growth
  easy, // 3: effortless -> boosted interval
}

class CustomWord {
  final String id;
  final String word;
  final String translation;
  final String note;
  final DateTime createdAt;

  const CustomWord({
    required this.id,
    required this.word,
    required this.translation,
    this.note = '',
    required this.createdAt,
  });

  factory CustomWord.fromJson(Map<String, dynamic> json) {
    return CustomWord(
      id: json['id'] as String,
      word: json['word'] as String,
      translation: json['translation'] as String,
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'translation': translation,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };
}

class StreakData {
  final int currentStreak;
  final int bestStreak;
  final String? lastActivityDate; // YYYY-MM-DD

  const StreakData({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastActivityDate,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      lastActivityDate: json['lastActivityDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastActivityDate': lastActivityDate,
      };
}

class DailyStats {
  final String date; // YYYY-MM-DD
  final int wordsReviewed;
  final int correctAnswers;
  final int totalAnswers;
  final int durationSeconds;

  const DailyStats({
    required this.date,
    this.wordsReviewed = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.durationSeconds = 0,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] as String,
      wordsReviewed: (json['wordsReviewed'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalAnswers: (json['totalAnswers'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'wordsReviewed': wordsReviewed,
        'correctAnswers': correctAnswers,
        'totalAnswers': totalAnswers,
        'durationSeconds': durationSeconds,
      };
}

class SessionRecord {
  final String id;
  final String mode; // flashcard, listening, match_game, quiz_choice, ...
  final String level;
  final int totalWords;
  final int correctCount;
  final int durationSeconds;
  final int maxCorrectStreak;
  final DateTime completedAt;

  const SessionRecord({
    required this.id,
    required this.mode,
    required this.level,
    required this.totalWords,
    required this.correctCount,
    required this.durationSeconds,
    required this.maxCorrectStreak,
    required this.completedAt,
  });

  int get accuracy =>
      totalWords == 0 ? 0 : ((correctCount / totalWords) * 100).round();

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String,
      mode: json['mode'] as String,
      level: json['level'] as String,
      totalWords: (json['totalWords'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      maxCorrectStreak: (json['maxCorrectStreak'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'level': level,
        'totalWords': totalWords,
        'correctCount': correctCount,
        'durationSeconds': durationSeconds,
        'maxCorrectStreak': maxCorrectStreak,
        'completedAt': completedAt.toIso8601String(),
      };
}

class AppSettings {
  final int flashcardWordCount;
  final int quizWordCount;
  final int dailyGoalWords;
  final bool isDarkMode;

  const AppSettings({
    this.flashcardWordCount = 10,
    this.quizWordCount = 10,
    this.dailyGoalWords = 20,
    this.isDarkMode = false,
  });

  AppSettings copyWith({
    int? flashcardWordCount,
    int? quizWordCount,
    int? dailyGoalWords,
    bool? isDarkMode,
  }) {
    return AppSettings(
      flashcardWordCount: flashcardWordCount ?? this.flashcardWordCount,
      quizWordCount: quizWordCount ?? this.quizWordCount,
      dailyGoalWords: dailyGoalWords ?? this.dailyGoalWords,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      flashcardWordCount: (json['flashcardWordCount'] as num?)?.toInt() ?? 10,
      quizWordCount: (json['quizWordCount'] as num?)?.toInt() ?? 10,
      dailyGoalWords: (json['dailyGoalWords'] as num?)?.toInt() ?? 20,
      isDarkMode: (json['isDarkMode'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'flashcardWordCount': flashcardWordCount,
        'quizWordCount': quizWordCount,
        'dailyGoalWords': dailyGoalWords,
        'isDarkMode': isDarkMode,
      };
}

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String emoji;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });

  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'first_word',
      title: 'Первый шаг',
      description: 'Изучите первое слово',
      emoji: '🌱',
    ),
    AchievementDef(
      id: 'words_10',
      title: 'Начало пути',
      description: 'Изучите 10 слов',
      emoji: '📖',
    ),
    AchievementDef(
      id: 'words_50',
      title: 'Исследователь',
      description: 'Изучите 50 слов',
      emoji: '🧭',
    ),
    AchievementDef(
      id: 'words_100',
      title: 'Клуб сотни',
      description: 'Изучите 100 слов',
      emoji: '💯',
    ),
    AchievementDef(
      id: 'words_500',
      title: 'Мастер лексики',
      description: 'Изучите 500 слов',
      emoji: '👑',
    ),
    AchievementDef(
      id: 'streak_3',
      title: 'Ритм 3 дня',
      description: 'Занимайтесь 3 дня подряд',
      emoji: '🔥',
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Неделя практики',
      description: 'Занимайтесь 7 дней подряд',
      emoji: '⚡',
    ),
    AchievementDef(
      id: 'streak_30',
      title: 'Чемпион месяца',
      description: 'Занимайтесь 30 дней подряд',
      emoji: '🏆',
    ),
    AchievementDef(
      id: 'sessions_10',
      title: '10 тренировок',
      description: 'Завершите 10 тренировок',
      emoji: '🎯',
    ),
    AchievementDef(
      id: 'sessions_50',
      title: '50 тренировок',
      description: 'Завершите 50 тренировок',
      emoji: '🎓',
    ),
    AchievementDef(
      id: 'accuracy_80',
      title: 'Точный слух',
      description: '80% точности в сессии',
      emoji: '🧠',
    ),
    AchievementDef(
      id: 'accuracy_100',
      title: 'Без единой ошибки',
      description: '100% точности в сессии',
      emoji: '✨',
    ),
    AchievementDef(
      id: 'streak_correct_10',
      title: '10 подряд',
      description: '10 правильных ответов подряд',
      emoji: '🚀',
    ),
    AchievementDef(
      id: 'streak_correct_20',
      title: 'Неудержимый',
      description: '20 правильных ответов подряд',
      emoji: '💎',
    ),
    AchievementDef(
      id: 'time_60',
      title: 'Час практики',
      description: 'Потратьте 60 минут на обучение',
      emoji: '⏱️',
    ),
  ];
}

enum QuizMode {
  multipleChoice,
  reverseChoice,
  typing,
}
