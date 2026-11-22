import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../models/dictionary_example.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'cefr_badge.dart';

Future<void> showWordDetailSheet({
  required BuildContext context,
  required WordItem word,
  required AppState appState,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _WordDetailSheetContent(word: word, appState: appState),
  );
}

class _WordDetailSheetContent extends StatefulWidget {
  final WordItem word;
  final AppState appState;

  const _WordDetailSheetContent({
    required this.word,
    required this.appState,
  });

  @override
  State<_WordDetailSheetContent> createState() =>
      _WordDetailSheetContentState();
}

class _WordDetailSheetContentState extends State<_WordDetailSheetContent> {
  List<DictionaryExample>? _examples;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExamples();
  }

  Future<void> _loadExamples() async {
    final res = await DictionaryService().fetchExamples(widget.word.word);
    if (!mounted) return;
    setState(() {
      _examples = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final isFav = widget.appState.isFavorite(widget.word.id);
        final progress = widget.appState.progressForWord(widget.word.id);
        final masterySteps = (progress?.correctCount ?? 0).clamp(0, 3);

        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CefrBadge(level: widget.word.level, large: true),
                      const Spacer(),
                      IconButton(
                        onPressed: () => TtsService().speak(widget.word.word),
                        icon: const Icon(Icons.volume_up_rounded),
                        color: AppColors.primaryLight,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            widget.appState.toggleFavorite(widget.word.id),
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                        color: isFav ? AppColors.coral : AppColors.textSecondary,
                        style: IconButton.styleFrom(
                          backgroundColor: isFav
                              ? AppColors.coralSoft
                              : AppColors.bgCardElevated,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.word.word,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.word.phonetic.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.word.phonetic,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      widget.word.translation,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mastery indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          masterySteps >= 3
                              ? Icons.verified_rounded
                              : Icons.school_rounded,
                          color: masterySteps >= 3
                              ? AppColors.emerald
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          masterySteps >= 3
                              ? 'Слово освоено'
                              : masterySteps >= 1
                                  ? 'Изучается ($masterySteps / 3)'
                                  : 'Новое слово',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(3, (idx) {
                            final filled = idx < masterySteps;
                            return Container(
                              width: 18,
                              height: 6,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: filled
                                    ? AppColors.emerald
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Примеры и значения',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Загрузка примеров...',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else if (_examples == null || _examples!.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'Примеры для этого слова недоступны',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    ..._examples!.map((ex) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ex.partOfSpeech.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ex.partOfSpeech,
                                    style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Text(
                                ex.definition,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              if (ex.example != null &&
                                  ex.example!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '"${ex.example!}"',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          TtsService().speak(ex.example!),
                                      icon: const Icon(
                                        Icons.volume_up_rounded,
                                        size: 18,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
