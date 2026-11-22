import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CefrBadge extends StatelessWidget {
  final String level;
  final bool large;

  const CefrBadge({
    super.key,
    required this.level,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.levelColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(large ? 10 : 7),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: large ? 14 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
