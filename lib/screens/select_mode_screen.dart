import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../models/learning_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cefr_badge.dart';
import 'learn_screen.dart';
import 'quiz_screen.dart';

class SelectModeScreen extends StatefulWidget {
  final AppState appState;
  final String levelCode; // A1..C1 or ALL
  final bool initialFavoritesOnly;

  const SelectModeScreen({
    super.key,
    required this.appState,
    required this.levelCode,
    this.initialFavoritesOnly = false,
  });

  @override
  State<SelectModeScreen> createState() => _SelectModeScreenState();
}

class _SelectModeScreenState extends State<SelectModeScreen> {
  int _selectedTab = 0; // 0 = Flashcards, 1 = Quiz
  late int _flashcardCount;
  late int _quizCount;
  bool _reverseFlashcards = false;
  late bool _favoritesOnly;
  QuizMode _quizMode = QuizMode.multipleChoice;

  static const _wordCountOptions = [5, 10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    _flashcardCount = widget.appState.settings.flashcardWordCount;
    _quizCount = widget.appState.settings.quizWordCount;
    _favoritesOnly = widget.initialFavoritesOnly;
  }

  int _availableWordsCount() {
    final all = widget.appState.wordsForLevel(widget.levelCode);
    if (!_favoritesOnly) return all.length;
    return all.where((w) => widget.appState.isFavorite(w.id)).length;
  }

  void _startSession() {
    final count = _selectedTab == 0 ? _flashcardCount : _quizCount;
    final words = widget.appState.pickSessionWords(
      level: widget.levelCode,
      count: count,
      favoritesOnly: _favoritesOnly,
    );

    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _favoritesOnly
                ? 'Сначала добавьте слова в избранное'
                : 'Слова для этого уровня не найдены',
          ),
        ),
      );
      return;
    }

    if (_selectedTab == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LearnScreen(
            appState: widget.appState,
            levelCode: widget.levelCode,
            initialWords: words,
            reverseMode: _reverseFlashcards,
            favoritesOnly: _favoritesOnly,
            requestedCount: count,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            appState: widget.appState,
            levelCode: widget.levelCode,
            initialWords: words,
            quizMode: _quizMode,
            favoritesOnly: _favoritesOnly,
            requestedCount: count,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAll = widget.levelCode == 'ALL';
    final levelInfo = isAll ? null : CefrLevelInfo.byCode(widget.levelCode);
    final total = widget.appState.wordsForLevel(widget.levelCode).length;
    final learned = widget.appState.learnedCountForLevel(widget.levelCode);
    final available = _availableWordsCount();
    final progressRatio = total == 0 ? 0.0 : learned / total;
    final levelColor =
        isAll ? AppColors.primary : AppColors.levelColor(widget.levelCode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите режим'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isAll
                      ? const [Color(0xFF0B2A4A), Color(0xFF101A2B)]
                      : AppColors.levelGradient(widget.levelCode),
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: levelColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!isAll)
                        CefrBadge(level: widget.levelCode, large: true)
                      else
                        const CefrBadge(level: 'ALL', large: true),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isAll ? 'Все уровни' : levelInfo!.subtitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$learned / $total слов',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progressRatio * 100).round()}%',
                        style: TextStyle(
                          color: levelColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(levelColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Mode switcher: Flashcards vs Quiz
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeTabButton(
                      label: 'Флешкарты',
                      icon: Icons.style_rounded,
                      selected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _ModeTabButton(
                      label: 'Квиз',
                      icon: Icons.quiz_rounded,
                      selected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            if (_selectedTab == 0) ...[
              const Text(
                'Режим показа',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: 'Сначала слово, потом перевод',
                subtitle: 'Английское слово → русский перевод',
                icon: Icons.translate_rounded,
                selected: !_reverseFlashcards,
                onTap: () => setState(() => _reverseFlashcards = false),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: 'Сначала перевод, потом слово',
                subtitle: 'Обратный режим: русский → английский',
                icon: Icons.swap_horiz_rounded,
                selected: _reverseFlashcards,
                onTap: () => setState(() => _reverseFlashcards = true),
              ),
            ] else ...[
              const Text(
                'Выбери режим квиза',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: 'Выбор ответа',
                subtitle: 'Выбери правильный перевод из нескольких вариантов.',
                icon: Icons.checklist_rounded,
                selected: _quizMode == QuizMode.multipleChoice,
                onTap: () =>
                    setState(() => _quizMode = QuizMode.multipleChoice),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: 'Обратный перевод',
                subtitle: 'Переводи слова с русского на английский.',
                icon: Icons.swap_horiz_rounded,
                selected: _quizMode == QuizMode.reverseChoice,
                onTap: () =>
                    setState(() => _quizMode = QuizMode.reverseChoice),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: 'Ввод слова',
                subtitle: 'Вспоминай слова и тренируй правописание.',
                icon: Icons.keyboard_rounded,
                selected: _quizMode == QuizMode.typing,
                onTap: () => setState(() => _quizMode = QuizMode.typing),
              ),
            ],

            const SizedBox(height: 22),
            const Text(
              'Количество слов',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _wordCountOptions.map((c) {
                final current =
                    _selectedTab == 0 ? _flashcardCount : _quizCount;
                final selected = current == c;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: c == _wordCountOptions.last ? 0 : 8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          if (_selectedTab == 0) {
                            _flashcardCount = c;
                          } else {
                            _quizCount = c;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$c',
                          style: TextStyle(
                            color: selected
                                ? AppColors.primaryLight
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),
            // Favorites only toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.coral,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Только избранное',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Показывать только слова из избранного',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _favoritesOnly,
                    activeThumbColor: AppColors.emerald,
                    onChanged: (v) => setState(() => _favoritesOnly = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Доступно слов: $available',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: available == 0 ? null : _startSession,
                icon: Icon(
                  _selectedTab == 0
                      ? Icons.play_arrow_rounded
                      : Icons.bolt_rounded,
                ),
                label: Text(
                  _selectedTab == 0 ? 'Начать обучение' : 'Начать квиз',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.22)
                    : AppColors.bgCardElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primaryLight : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
