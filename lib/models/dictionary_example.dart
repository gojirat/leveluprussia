class DictionaryExample {
  final String partOfSpeech;
  final String definition;
  final String? example;

  const DictionaryExample({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });

  factory DictionaryExample.fromJson(Map<String, dynamic> json) {
    return DictionaryExample(
      partOfSpeech: (json['partOfSpeech'] as String?) ?? '',
      definition: (json['definition'] as String?) ?? '',
      example: json['example'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'partOfSpeech': partOfSpeech,
        'definition': definition,
        if (example != null) 'example': example,
      };
}
