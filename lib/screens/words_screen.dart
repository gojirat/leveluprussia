import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/word_detail_sheet.dart';
import 'learn_screen.dart';

class WordsScreen extends StatefulWidget {
  final AppState appState;

  const WordsScreen({super.key, required this.appState});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _section = 0; // 0 = All 4109, 1 = My Words, 2 = Favorites
  String _selectedLevel = 'ALL';
  bool _sortByRu = false;

  static const _levelFilters = ['ALL', 'A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddCustomWordDialog() async {
    final enCtrl = TextEditingController();
    final ruCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить своё слово'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: enCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Английское слово',
                hintText: 'например, resilience',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ruCtrl,
              decoration: const InputDecoration(
                labelText: 'Перевод на русский',
                hintText: 'например, стойкость',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Заметка / пример (необязательно)',
                hintText: 'контекст использования',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (enCtrl.text.trim().isEmpty || ruCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await widget.appState.addCustomWord(
        word: enCtrl.text,
        translation: ruCtrl.text,
        note: noteCtrl.text,
      );
      if (mounted) setState(() => _section = 1);
    }

    enCtrl.dispose();
    ruCtrl.dispose();
    noteCtrl.dispose();
  }

  List<WordItem> _filteredWords() {
    final List<WordItem> base;
    if (_section == 1) {
      base = widget.appState.wordsForLevel('MY');
    } else if (_section == 2) {
      base = widget.appState.favoriteWords;
    } else {
      base = widget.appState.wordsForLevel(_selectedLevel);
    }

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<WordItem>.of(base)
        : base
            .where((w) =>
                w.word.toLowerCase().contains(q) ||
                w.translation.toLowerCase().contains(q))
            .toList();

    if (_section != 1) {
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
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final items = _filteredWords();
        final myCount = widget.appState.customWords.length;
        final favCount = widget.appState.favoriteWords.length;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Словарь',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddCustomWordDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Своё слово',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Section Switcher: Base / My Words / Favorites
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<int>(
                  segments: [
                    const ButtonSegment(value: 0, label: Text('База')),
                    ButtonSegment(value: 1, label: Text('Мои ($myCount)')),
                    ButtonSegment(value: 2, label: Text('★ ($favCount)')),
                  ],
                  selected: {_section},
                  onSelectionChanged: (s) => setState(() => _section = s.first),
                ),
              ),
              const SizedBox(height: 12),

              // Search bar + Sort
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Поиск на EN или RU...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                )
                              : null,
                        ),
                      ),
                    ),
                    if (_section != 1) ...[
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Сортировка',
                        onPressed: () => setState(() => _sortByRu = !_sortByRu),
                        icon: Text(
                          _sortByRu ? 'А-Я' : 'A-Z',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_section == 0)
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _levelFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) {
                      final lvl = _levelFilters[idx];
                      final selected = _selectedLevel == lvl;
                      return ChoiceChip(
                        label: Text(lvl == 'ALL' ? 'Все' : lvl),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedLevel = lvl),
                        showCheckmark: false,
                      );
                    },
                  ),
                )
              else if (_section == 1 && items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LearnScreen(
                              appState: widget.appState,
                              levelCode: 'MY',
                              initialWords: items,
                              reverseMode: false,
                              favoritesOnly: false,
                              requestedCount: items.length,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Учить мои слова (${items.length})'),
                    ),
                  ),
                )
              else
                const SizedBox(height: 10),

              // List
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _section == 1
                                    ? Icons.note_add_outlined
                                    : _section == 2
                                        ? Icons.favorite_border_rounded
                                        : Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.mutedText(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _section == 1
                                    ? 'Личный словарь пока пуст'
                                    : _section == 2
                                        ? 'Нет избранных слов'
                                        : 'Ничего не найдено',
                                style: TextStyle(
                                  color: AppColors.primaryText(context),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _section == 1
                                    ? 'Нажмите «Своё слово», чтобы добавить нужную лексику и тренировать её в карточках.'
                                    : _section == 2
                                        ? 'Отмечайте сложные слова иконкой сердца.'
                                        : 'Попробуйте изменить запрос или фильтр уровня.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.secondaryText(context),
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final word = items[idx];
                          final isCustom = word.level == 'MY';
                          final isFav = widget.appState.isFavorite(word.id);

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isCustom
                                ? null
                                : () => showWordDetailSheet(
                                      context: context,
                                      word: word,
                                      appState: widget.appState,
                                    ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.cardBorder(context),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CefrBadge(
                                          level: isCustom ? 'МОЁ' : word.level,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          word.word,
                                          style: TextStyle(
                                            color:
                                                AppColors.primaryText(context),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (word.phonetic.isNotEmpty)
                                          Text(
                                            word.phonetic,
                                            style: TextStyle(
                                              color:
                                                  AppColors.mutedText(context),
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        Text(
                                          word.translation,
                                          style: TextStyle(
                                            color: AppColors.secondaryText(
                                              context,
                                            ),
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
                                    color: AppColors.primary,
                                  ),
                                  if (isCustom)
                                    IconButton(
                                      onPressed: () => widget.appState
                                          .deleteCustomWord(word.id),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 21,
                                      ),
                                      color: AppColors.coral,
                                    )
                                  else
                                    IconButton(
                                      onPressed: () => widget.appState
                                          .toggleFavorite(word.id),
                                      icon: Icon(
                                        isFav
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 21,
                                      ),
                                      color: isFav
                                          ? AppColors.coral
                                          : AppColors.mutedText(context),
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
