import 'package:flutter/material.dart';

class AppColors {
  // Core dark navy palette extracted from LevelUp
  static const Color bgPrimary = Color(0xFF080D17);
  static const Color bgSecondary = Color(0xFF0B1220);
  static const Color bgCard = Color(0xFF101A2B);
  static const Color bgCardElevated = Color(0xFF15263A);
  static const Color bgSurface = Color(0xFF182A40);
  static const Color border = Color(0xFF1D2B42);
  static const Color borderLight = Color(0xFF253752);

  // Brand accents
  static const Color primary = Color(0xFF168FFF);
  static const Color primaryLight = Color(0xFF159BFF);
  static const Color primaryDark = Color(0xFF1065AF);
  static const Color emerald = Color(0xFF00C68E);
  static const Color emeraldBright = Color(0xFF10B981);
  static const Color emeraldSoft = Color(0x2610B981);
  static const Color coral = Color(0xFFEF4444);
  static const Color coralSoft = Color(0x26EF4444);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0x26F59E0B);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static Color levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return const Color(0xFF10B981); // Emerald
      case 'A2':
        return const Color(0xFF168FFF); // Electric Blue
      case 'B1':
        return const Color(0xFF6366F1); // Indigo
      case 'B2':
        return const Color(0xFFF59E0B); // Amber
      case 'C1':
        return const Color(0xFFEC4899); // Pink/Rose
      case 'C2':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return primary;
    }
  }

  static List<Color> levelGradient(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return const [Color(0xFF064B3B), Color(0xFF0B2929)];
      case 'A2':
        return const [Color(0xFF0B2A4A), Color(0xFF0D1B2D)];
      case 'B1':
        return const [Color(0xFF1E1F4B), Color(0xFF101A2B)];
      case 'B2':
        return const [Color(0xFF3B2608), Color(0xFF191A26)];
      case 'C1':
        return const [Color(0xFF3E122C), Color(0xFF171628)];
      case 'C2':
        return const [Color(0xFF2B174A), Color(0xFF141729)];
      default:
        return const [Color(0xFF0D1B2D), Color(0xFF101A2B)];
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.emerald,
        surface: AppColors.bgCard,
        error: AppColors.coral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primaryLight : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.primaryLight : AppColors.textMuted,
          );
        }),
      ),
    );
  }
}
