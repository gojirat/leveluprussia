class WordItem {
  final String id;
  final String word;
  final String translation;
  final String phonetic;
  final String level; // A1, A2, B1, B2, C1

  const WordItem({
    required this.id,
    required this.word,
    required this.translation,
    required this.phonetic,
    required this.level,
  });

  factory WordItem.fromJson(Map<String, dynamic> json) {
    return WordItem(
      id: json['id'] as String,
      word: json['word'] as String,
      translation: json['translation'] as String,
      phonetic: (json['phonetic'] as String?) ?? '',
      level: json['level'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'translation': translation,
        'phonetic': phonetic,
        'level': level,
      };
}

class CefrLevelInfo {
  final String code;
  final String title;
  final String subtitle;

  const CefrLevelInfo({
    required this.code,
    required this.title,
    required this.subtitle,
  });

  static const List<CefrLevelInfo> all = [
    CefrLevelInfo(
      code: 'A1',
      title: 'Уровень A1',
      subtitle: 'Простые слова',
    ),
    CefrLevelInfo(
      code: 'A2',
      title: 'Уровень A2',
      subtitle: 'Базовые слова',
    ),
    CefrLevelInfo(
      code: 'B1',
      title: 'Уровень B1',
      subtitle: 'Средние слова',
    ),
    CefrLevelInfo(
      code: 'B2',
      title: 'Уровень B2',
      subtitle: 'Продвинутые слова',
    ),
    CefrLevelInfo(
      code: 'C1',
      title: 'Уровень C1',
      subtitle: 'Сложные слова',
    ),
  ];

  static CefrLevelInfo byCode(String code) {
    return all.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => all.first,
    );
  }
}
