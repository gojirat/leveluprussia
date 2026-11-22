import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/word_detail_sheet.dart';

class WordsScreen extends StatefulWidget {
  final AppState appState;

  const WordsScreen({super.key, required this.appState});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedLevel = 'ALL';
  bool _sortByRu = false;

  static const _levelFilters = ['ALL', 'A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WordItem> _filteredWords() {
    final base = widget.appState.wordsForLevel(_selectedLevel);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<WordItem>.of(base)
        : base
            .where((w) =>
                w.word.toLowerCase().contains(q) ||
                w.translation.toLowerCase().contains(q))
            .toList();

    if (_sortByRu) {
      filtered.sort(
        (a, b) => a.translation
            .toLowerCase()
            .compareTo(b.translation.toLowerCase()),
      );
    } else {
      filtered.sort(
        (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
      );
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final items = _filteredWords();

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    const Text(
                      'Словарь',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _sortByRu = !_sortByRu),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sort_by_alpha_rounded,
                              size: 16,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _sortByRu ? 'А-Я' : 'A-Z',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Поиск слов...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          )
                        : null,
                  ),
                ),
              ),

              // Level Filter Chips
              SizedBox(
                height: 52,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _levelFilters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final lvl = _levelFilters[idx];
                    final selected = _selectedLevel == lvl;
                    final color = lvl == 'ALL'
                        ? AppColors.primary
                        : AppColors.levelColor(lvl);
                    return ChoiceChip(
                      label: Text(lvl == 'ALL' ? 'Все уровни' : lvl),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedLevel = lvl),
                      backgroundColor: AppColors.bgCard,
                      selectedColor: color.withValues(alpha: 0.22),
                      side: BorderSide(
                        color: selected ? color : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? color : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      showCheckmark: false,
                    );
                  },
                ),
              ),

              // Word List
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Ничего не найдено',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Попробуй изменить запрос или фильтр',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final word = items[idx];
                          final isFav = widget.appState.isFavorite(word.id);
                          final prog =
                              widget.appState.progressForWord(word.id);
                          final isMastered = prog?.isMastered == true;
                          final isLearned = prog?.isLearned == true;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => showWordDetailSheet(
                              context: context,
                              word: word,
                              appState: widget.appState,
                            ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMastered
                                      ? AppColors.emerald
                                          .withValues(alpha: 0.35)
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CefrBadge(level: word.level),
                                            const SizedBox(width: 8),
                                            if (isMastered)
                                              const Icon(
                                                Icons.verified_rounded,
                                                size: 16,
                                                color: AppColors.emerald,
                                              )
                                            else if (isLearned)
                                              const Icon(
                                                Icons.check_circle_outline,
                                                size: 15,
                                                color: AppColors.primaryLight,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          word.word,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (word.phonetic.isNotEmpty)
                                          Text(
                                            word.phonetic,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        const SizedBox(height: 3),
                                        Text(
                                          word.translation,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        TtsService().speak(word.word),
                                    icon: const Icon(
                                      Icons.volume_up_rounded,
                                      size: 21,
                                    ),
                                    color: AppColors.primaryLight,
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        widget.appState.toggleFavorite(word.id),
                                    icon: Icon(
                                      isFav
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 21,
                                    ),
                                    color: isFav
                                        ? AppColors.coral
                                        : AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
