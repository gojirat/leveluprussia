import 'package:flutter/material.dart';
import '../models/learning_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'learn_screen.dart';
import 'listening_screen.dart';
import 'match_game_screen.dart';
import 'quiz_screen.dart';

class PracticeHubScreen extends StatefulWidget {
  final AppState appState;

  const PracticeHubScreen({super.key, required this.appState});

  @override
  State<PracticeHubScreen> createState() => _PracticeHubScreenState();
}

class _PracticeHubScreenState extends State<PracticeHubScreen> {
  String _selectedLevel = 'A1';
  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'ALL'];

  void _launchListening(BuildContext context) {
    final words = widget.appState.pickSessionWords(
      level: _selectedLevel,
      count: widget.appState.settings.quizWordCount,
      favoritesOnly: false,
    );
    if (words.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListeningScreen(
          appState: widget.appState,
          levelCode: _selectedLevel,
          initialWords: words,
        ),
      ),
    );
  }

  void _launchMatchGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchGameScreen(
          appState: widget.appState,
          levelCode: _selectedLevel,
        ),
      ),
    );
  }

  void _launchSrsCards(BuildContext context) {
    final due = widget.appState.dueForReviewWords;
    final words = due.isNotEmpty
        ? due.take(widget.appState.settings.flashcardWordCount).toList()
        : widget.appState.pickSessionWords(
            level: _selectedLevel,
            count: widget.appState.settings.flashcardWordCount,
            favoritesOnly: false,
          );
    if (words.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearnScreen(
          appState: widget.appState,
          levelCode: _selectedLevel,
          initialWords: words,
          reverseMode: false,
          favoritesOnly: false,
          requestedCount: widget.appState.settings.flashcardWordCount,
        ),
      ),
    );
  }

  void _launchTypingQuiz(BuildContext context) {
    final words = widget.appState.pickSessionWords(
      level: _selectedLevel,
      count: widget.appState.settings.quizWordCount,
      favoritesOnly: false,
    );
    if (words.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          appState: widget.appState,
          levelCode: _selectedLevel,
          initialWords: words,
          quizMode: QuizMode.typing,
          favoritesOnly: false,
          requestedCount: widget.appState.settings.quizWordCount,
        ),
      ),
    );
  }

  void _launchFavorites(BuildContext context) {
    final favs = widget.appState.favoriteWords;
    if (favs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте слова в избранное в разделе «Словарь»'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearnScreen(
          appState: widget.appState,
          levelCode: 'ALL',
          initialWords: favs.take(15).toList(),
          reverseMode: false,
          favoritesOnly: true,
          requestedCount: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final dueCount = widget.appState.dueForReviewWords.length;
        final bestMatch = widget.appState.bestMatchSeconds;
        final favCount = widget.appState.favoriteWords.length;
        final isWide = MediaQuery.of(context).size.width >= 720;

        final cards = [
          _TrainerCard(
            title: 'Аудирование',
            subtitle:
                'Слушайте английское произношение (1.0× и 0.7×) и выбирайте перевод',
            badge: 'Аудио-тренажёр',
            icon: Icons.headphones_rounded,
            color: AppColors.primary,
            onTap: () => _launchListening(context),
          ),
          _TrainerCard(
            title: 'Найди пары',
            subtitle: bestMatch != null
                ? 'Игра на скорость · Ваш рекорд: $bestMatch с'
                : 'Соединяйте 6 пар английских и русских слов на время',
            badge: 'Мини-игра',
            icon: Icons.grid_view_rounded,
            color: AppColors.accent,
            onTap: () => _launchMatchGame(context),
          ),
          _TrainerCard(
            title: 'Интервальное повторение',
            subtitle: dueCount > 0
                ? 'К повторению сегодня: $dueCount слов по алгоритму SM-2'
                : 'Умные карточки с оценкой сложности запоминания',
            badge: dueCount > 0 ? '$dueCount к повтору' : 'SM-2',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.emerald,
            onTap: () => _launchSrsCards(context),
          ),
          _TrainerCard(
            title: 'Правописание',
            subtitle: 'Вводите английские слова с клавиатуры с подсказками букв',
            badge: 'Диктант',
            icon: Icons.keyboard_rounded,
            color: AppColors.amber,
            onTap: () => _launchTypingQuiz(context),
          ),
          _TrainerCard(
            title: 'Тренировка избранного',
            subtitle: favCount > 0
                ? 'Повторите $favCount сохранённых вами сложных слов'
                : 'Отмечайте сложные слова сердцем для личной практики',
            badge: '$favCount слов',
            icon: Icons.favorite_rounded,
            color: AppColors.pink,
            onTap: () => _launchFavorites(context),
          ),
        ];

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Тренажёры',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Выберите уровень и формат практики',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _levels.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, idx) {
                            final lvl = _levels[idx];
                            final selected = _selectedLevel == lvl;
                            return ChoiceChip(
                              label: Text(lvl == 'ALL' ? 'Все' : lvl),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedLevel = lvl),
                              showCheckmark: false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                sliver: isWide
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 126,
                        ),
                        delegate: SliverChildListDelegate(cards),
                      )
                    : SliverList.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, idx) => cards[idx],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TrainerCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
