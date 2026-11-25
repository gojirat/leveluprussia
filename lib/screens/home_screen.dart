import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cefr_badge.dart';
import 'learn_screen.dart';
import 'listening_screen.dart';
import 'match_game_screen.dart';
import 'select_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  void _openLevel(BuildContext context, String levelCode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectModeScreen(
          appState: appState,
          levelCode: levelCode,
        ),
      ),
    );
  }

  void _startDueReview(BuildContext context) {
    final due = appState.dueForReviewWords;
    final words = due.isNotEmpty
        ? due.take(appState.settings.flashcardWordCount).toList()
        : appState.pickSessionWords(
            level: 'A1',
            count: appState.settings.flashcardWordCount,
            favoritesOnly: false,
          );
    if (words.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearnScreen(
          appState: appState,
          levelCode: 'ALL',
          initialWords: words,
          reverseMode: false,
          favoritesOnly: false,
          requestedCount: appState.settings.flashcardWordCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final todayCount = appState.todayStats.wordsReviewed;
        final dailyGoal = appState.settings.dailyGoalWords;
        final goalProgress = (todayCount / max(1, dailyGoal)).clamp(0.0, 1.0);
        final streak = appState.streak.currentStreak;
        final dueCount = appState.dueForReviewWords.length;
        final isWide = MediaQuery.of(context).size.width >= 720;

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          if (!isWide) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/app_icon_1024.png',
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Изучение слов: уровень',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.primaryText(context),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Ежедневная практика английского',
                                  style: TextStyle(
                                    color: AppColors.secondaryText(context),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amberSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 18,
                                  color: AppColors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$streak дн.',
                                  style: const TextStyle(
                                    color: AppColors.amber,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Daily Goal + SM-2 Due Review Hero Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Daily Goal Progress Ring
                            SizedBox(
                              width: 84,
                              height: 84,
                              child: CustomPaint(
                                painter: _GoalRingPainter(
                                  progress: goalProgress,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$todayCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        'из $dailyGoal',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dueCount > 0
                                        ? 'Повторение сегодня'
                                        : 'Цель на сегодня',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dueCount > 0
                                        ? 'Ждут повторения: $dueCount слов (SM-2)'
                                        : 'Выполнено ${(goalProgress * 100).round()}% дневной нормы',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _startDueReview(context),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      dueCount > 0
                                          ? 'Повторить ($dueCount)'
                                          : 'Учить слова',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick Actions: Listening & Word Match
                      Row(
                        children: [
                          Expanded(
                            child: _QuickModePill(
                              icon: Icons.headphones_rounded,
                              label: 'Аудирование',
                              color: AppColors.primary,
                              onTap: () {
                                final w = appState.pickSessionWords(
                                  level: 'A1',
                                  count: 10,
                                  favoritesOnly: false,
                                );
                                if (w.isEmpty) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ListeningScreen(
                                      appState: appState,
                                      levelCode: 'A1',
                                      initialWords: w,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickModePill(
                              icon: Icons.grid_view_rounded,
                              label: 'Найди пары',
                              color: AppColors.accent,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MatchGameScreen(
                                      appState: appState,
                                      levelCode: 'A1',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Курсы по уровням CEFR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                          Text(
                            '${appState.totalLearnedCount} / ${appState.words.length}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Responsive CEFR Grid (2 columns on iPad, 1 column on iPhone)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                sliver: isWide
                    ? SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 148,
                        ),
                        itemCount: CefrLevelInfo.all.length,
                        itemBuilder: (context, idx) => _buildLevelCard(
                          context,
                          CefrLevelInfo.all[idx],
                        ),
                      )
                    : SliverList.separated(
                        itemCount: CefrLevelInfo.all.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) => _buildLevelCard(
                          context,
                          CefrLevelInfo.all[idx],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelCard(BuildContext context, CefrLevelInfo info) {
    final total = appState.wordsForLevel(info.code).length;
    final learned = appState.learnedCountForLevel(info.code);
    final ratio = total == 0 ? 0.0 : learned / total;
    final color = AppColors.levelColor(info.code);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openLevel(context, info.code),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                CefrBadge(level: info.code, large: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        info.subtitle,
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$learned / $total слов',
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(ratio * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: color.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickModePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickModePill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double progress;

  _GoalRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - 10) / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter old) => old.progress != progress;
}
