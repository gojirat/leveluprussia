import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../models/learning_models.dart';
import '../services/review_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_detail_modal.dart';
import '../widgets/cefr_badge.dart';
import 'settings_screen.dart';

class ProgressScreen extends StatelessWidget {
  final AppState appState;

  const ProgressScreen({super.key, required this.appState});

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final learned = appState.totalLearnedCount;
        final mastered = appState.totalMasteredCount;
        final streak = appState.streak;
        final accuracy = appState.overallAccuracy;
        final unlocked = appState.unlockedAchievements;
        final week = appState.last7DaysStats;
        final maxDayWords = max(
          appState.settings.dailyGoalWords,
          week.fold<int>(0, (m, d) => max(m, d.wordsReviewed)),
        );
        final isDark = appState.settings.isDarkMode;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + Settings + Theme toggle
                Row(
                  children: [
                    Text(
                      'Прогресс',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton.outlined(
                      tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
                      onPressed: () => appState.updateSettings(
                        appState.settings.copyWith(isDarkMode: !isDark),
                      ),
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Настройки',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(appState: appState),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Top 3 KPI Cards
                Row(
                  children: [
                    Expanded(
                      child: _KpiBox(
                        icon: Icons.check_circle_rounded,
                        color: AppColors.primary,
                        value: '$learned',
                        label: 'Изучено',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _KpiBox(
                        icon: Icons.verified_rounded,
                        color: AppColors.emerald,
                        value: '$mastered',
                        label: 'Освоено',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _KpiBox(
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.amber,
                        value: '${streak.currentStreak} дн.',
                        label: 'Серия ($accuracy%)',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 7-Day Activity Bar Chart
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Активность за 7 дней',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Цель: ${appState.settings.dailyGoalWords}/день',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: week.map((d) {
                            final dt = DateTime.tryParse(d.date) ??
                                DateTime.now();
                            final label = _weekdays[(dt.weekday - 1) % 7];
                            final ratio = maxDayWords == 0
                                ? 0.0
                                : (d.wordsReviewed / maxDayWords)
                                    .clamp(0.06, 1.0);
                            final metGoal = d.wordsReviewed >=
                                appState.settings.dailyGoalWords;
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (d.wordsReviewed > 0)
                                    Text(
                                      '${d.wordsReviewed}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppColors.secondaryText(context),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 20,
                                    height: 74 * ratio,
                                    decoration: BoxDecoration(
                                      color: metGoal
                                          ? AppColors.emerald
                                          : d.wordsReviewed > 0
                                              ? AppColors.primary
                                              : AppColors.cardBorder(context),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mutedText(context),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CEFR breakdown
                Text(
                  'Уровни CEFR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder(context)),
                  ),
                  child: Column(
                    children: CefrLevelInfo.all.map((info) {
                      final total = appState.wordsForLevel(info.code).length;
                      final lvlLearned =
                          appState.learnedCountForLevel(info.code);
                      final ratio = total == 0 ? 0.0 : lvlLearned / total;
                      final color = AppColors.levelColor(info.code);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CefrBadge(level: info.code),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    info.subtitle,
                                    style: TextStyle(
                                      color: AppColors.primaryText(context),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$lvlLearned / $total',
                                  style: TextStyle(
                                    color: AppColors.secondaryText(context),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: color.withValues(alpha: 0.14),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 22),

                // Achievements
                Row(
                  children: [
                    Text(
                      'Достижения',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${unlocked.length} / ${AchievementDef.all.length}',
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: AchievementDef.all.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width >= 720 ? 5 : 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, idx) {
                    final ach = AchievementDef.all[idx];
                    final unlockedAt = unlocked[ach.id];
                    final isUnlocked = unlockedAt != null;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => showAchievementDetailModal(
                        context: context,
                        achievement: ach,
                        unlockedAt: unlockedAt,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? AppColors.emerald.withValues(alpha: 0.12)
                              : AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUnlocked
                                ? AppColors.emerald.withValues(alpha: 0.5)
                                : AppColors.cardBorder(context),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isUnlocked ? ach.emoji : '🔒',
                              style: TextStyle(fontSize: isUnlocked ? 28 : 22),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ach.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isUnlocked
                                    ? AppColors.primaryText(context)
                                    : AppColors.mutedText(context),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Rate App button (App Store compliant direct listing)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => ReviewService().openAppStoreReview(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.amber),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Оценить приложение',
                                style: TextStyle(
                                  color: AppColors.primaryText(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Оставить отзыв в App Store',
                                style: TextStyle(
                                  color: AppColors.secondaryText(context),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.mutedText(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KpiBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _KpiBox({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
