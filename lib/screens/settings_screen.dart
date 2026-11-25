import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  static const _countOptions = [5, 10, 15, 20, 30];
  static const _dailyGoalOptions = [10, 20, 30, 50];

  Future<void> _confirmResetWelcome(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сбросить экран приветствия'),
        content: const Text(
          'Показать экран приветствия снова при следующем запуске?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await appState.setWelcomeShown(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Экран приветствия будет показан при следующем запуске приложения',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmClearProgress(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить прогресс?'),
        content: const Text(
          'Удалит статистику, достижения, избранное и серии. Обучение начнётся заново.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await appState.clearAllProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Прогресс очищен')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final settings = appState.settings;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  // Theme toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Тёмная тема',
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Переключение между светлым и тёмным оформлением',
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontSize: 12.5,
                        ),
                      ),
                      value: settings.isDarkMode,
                      onChanged: (v) => appState.updateSettings(
                        settings.copyWith(isDarkMode: v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _CountSelectorCard(
                    title: 'Дневная цель (слов в день)',
                    subtitle: 'Отображается в кольце прогресса и графике недели',
                    options: _dailyGoalOptions,
                    selected: settings.dailyGoalWords,
                    onChanged: (v) => appState.updateSettings(
                      settings.copyWith(dailyGoalWords: v),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _CountSelectorCard(
                    title: 'Слов в карточках',
                    subtitle: 'Количество слов в одной сессии SM-2',
                    options: _countOptions,
                    selected: settings.flashcardWordCount,
                    onChanged: (v) => appState.updateSettings(
                      settings.copyWith(flashcardWordCount: v),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _CountSelectorCard(
                    title: 'Слов в квизе и аудировании',
                    subtitle: 'Количество вопросов в одной тренировке',
                    options: _countOptions,
                    selected: settings.quizWordCount,
                    onChanged: (v) => appState.updateSettings(
                      settings.copyWith(quizWordCount: v),
                    ),
                  ),
                  const SizedBox(height: 22),

                  _ActionRow(
                    icon: Icons.waving_hand_rounded,
                    iconColor: AppColors.primary,
                    title: 'Сбросить экран приветствия',
                    subtitle: 'Показать онбординг при следующем запуске',
                    onTap: () => _confirmResetWelcome(context),
                  ),
                  const SizedBox(height: 10),
                  _ActionRow(
                    icon: Icons.delete_forever_rounded,
                    iconColor: AppColors.coral,
                    title: 'Очистить всю историю прогресса',
                    subtitle: 'Удалит статистику, достижения и серии.',
                    destructive: true,
                    onTap: () => _confirmClearProgress(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CountSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<int> options;
  final int selected;
  final ValueChanged<int> onChanged;

  const _CountSelectorCard({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((v) {
              final isSelected = v == selected;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: v == options.last ? 0 : 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.16)
                            : AppColors.surfaceBg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder(context),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$v',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primaryText(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: destructive ? AppColors.coralSoft : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destructive
                ? AppColors.coral.withValues(alpha: 0.4)
                : AppColors.cardBorder(context),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: destructive
                          ? AppColors.coral
                          : AppColors.primaryText(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }
}
