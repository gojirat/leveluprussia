class WordProgress {
  final String wordId;
  final int correctCount;
  final int incorrectCount;
  final DateTime lastReviewed;

  const WordProgress({
    required this.wordId,
    required this.correctCount,
    required this.incorrectCount,
    required this.lastReviewed,
  });

  bool get isLearned => correctCount >= 1;
  bool get isMastered => correctCount >= 3;

  WordProgress copyWith({
    int? correctCount,
    int? incorrectCount,
    DateTime? lastReviewed,
  }) {
    return WordProgress(
      wordId: wordId,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }

  factory WordProgress.fromJson(Map<String, dynamic> json) {
    return WordProgress(
      wordId: json['wordId'] as String,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      incorrectCount: (json['incorrectCount'] as num?)?.toInt() ?? 0,
      lastReviewed: DateTime.tryParse(json['lastReviewed'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'lastReviewed': lastReviewed.toIso8601String(),
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
  final String mode; // flashcard, quiz_choice, quiz_reverse, quiz_typing
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

  const AppSettings({
    this.flashcardWordCount = 10,
    this.quizWordCount = 10,
  });

  AppSettings copyWith({
    int? flashcardWordCount,
    int? quizWordCount,
  }) {
    return AppSettings(
      flashcardWordCount: flashcardWordCount ?? this.flashcardWordCount,
      quizWordCount: quizWordCount ?? this.quizWordCount,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      flashcardWordCount: (json['flashcardWordCount'] as num?)?.toInt() ?? 10,
      quizWordCount: (json['quizWordCount'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'flashcardWordCount': flashcardWordCount,
        'quizWordCount': quizWordCount,
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
      title: 'Исследователь слов',
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
      title: 'Мастер слов',
      description: 'Изучите 500 слов',
      emoji: '👑',
    ),
    AchievementDef(
      id: 'streak_3',
      title: 'Горячая серия',
      description: 'Серия 3 дня',
      emoji: '🔥',
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Воин недели',
      description: 'Серия 7 дней',
      emoji: '⚡',
    ),
    AchievementDef(
      id: 'streak_30',
      title: 'Чемпион месяца',
      description: 'Серия 30 дней',
      emoji: '🏆',
    ),
    AchievementDef(
      id: 'sessions_10',
      title: 'Энтузиаст обучения',
      description: 'Завершите 10 сессий',
      emoji: '🎯',
    ),
    AchievementDef(
      id: 'sessions_50',
      title: 'Преданный ученик',
      description: 'Завершите 50 сессий',
      emoji: '🎓',
    ),
    AchievementDef(
      id: 'accuracy_80',
      title: 'Острый ум',
      description: '80% точности в сессии',
      emoji: '🧠',
    ),
    AchievementDef(
      id: 'accuracy_100',
      title: 'Идеальный результат',
      description: '100% точности в сессии',
      emoji: '✨',
    ),
    AchievementDef(
      id: 'streak_correct_10',
      title: 'В огне',
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
      title: 'Час обучения',
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
