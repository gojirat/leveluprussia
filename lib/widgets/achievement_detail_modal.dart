import 'package:flutter/material.dart';
import '../models/learning_models.dart';
import '../theme/app_theme.dart';

Future<void> showAchievementDetailModal({
  required BuildContext context,
  required AchievementDef achievement,
  DateTime? unlockedAt,
}) {
  final isUnlocked = unlockedAt != null;
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isUnlocked
              ? AppColors.emerald.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? AppColors.emeraldSoft
                    : AppColors.bgCardElevated,
                border: Border.all(
                  color: isUnlocked ? AppColors.emerald : AppColors.borderLight,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                isUnlocked ? achievement.emoji : '🔒',
                style: const TextStyle(fontSize: 34),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.emeraldSoft
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isUnlocked
                    ? 'Достижение разблокировано!'
                    : 'Продолжайте учиться, чтобы разблокировать!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? AppColors.emerald : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
