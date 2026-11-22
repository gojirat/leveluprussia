import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  static const _countOptions = [5, 10, 15, 20, 30];

  Future<void> _confirmResetWelcome(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
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
        backgroundColor: AppColors.bgCard,
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Настройки обучения',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Настройте параметры обучения под свои цели и уровень',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Flashcards count
              _CountSelectorCard(
                title: 'Слов в карточках',
                subtitle: 'Количество слов в одной сессии флешкарт',
                options: _countOptions,
                selected: settings.flashcardWordCount,
                onChanged: (v) => appState.updateSettings(
                  settings.copyWith(flashcardWordCount: v),
                ),
              ),
              const SizedBox(height: 12),

              // Quiz count
              _CountSelectorCard(
                title: 'Слов в квизе',
                subtitle: 'Количество слов в одной сессии квиза',
                options: _countOptions,
                selected: settings.quizWordCount,
                onChanged: (v) => appState.updateSettings(
                  settings.copyWith(quizWordCount: v),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Управление данными',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _ActionRow(
                icon: Icons.waving_hand_rounded,
                iconColor: AppColors.primaryLight,
                title: 'Сбросить экран приветствия',
                subtitle: 'Показать онбординг при следующем запуске',
                onTap: () => _confirmResetWelcome(context),
              ),
              const SizedBox(height: 10),
              _ActionRow(
                icon: Icons.delete_forever_rounded,
                iconColor: AppColors.coral,
                title: 'Очистить всю историю прогресса',
                subtitle:
                    'Все данные обучения будут удалены без возможности восстановления.',
                destructive: true,
                onTap: () => _confirmClearProgress(context),
              ),
            ],
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
                            ? AppColors.primary.withValues(alpha: 0.22)
                            : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$v',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.textPrimary,
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
          color: destructive ? AppColors.coralSoft : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destructive
                ? AppColors.coral.withValues(alpha: 0.4)
                : AppColors.border,
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
                          : AppColors.textPrimary,
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
