import 'package:flutter/material.dart';

class AppColors {
  // Brand identity harmonized with the custom coral-and-indigo 3D book icon
  static const Color primary = Color(0xFF4F46E5); // Royal Indigo
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color accent = Color(0xFFFF5A5F); // Warm Coral
  static const Color accentSoft = Color(0x1FFF5A5F);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldBright = Color(0xFF059669);
  static const Color emeraldSoft = Color(0x2010B981);
  static const Color coral = Color(0xFFEF4444);
  static const Color coralSoft = Color(0x20EF4444);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0x24F59E0B);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);

  // Dark surface tokens
  static const Color bgPrimary = Color(0xFF0F111A);
  static const Color bgSecondary = Color(0xFF151826);
  static const Color bgCard = Color(0xFF1A1E30);
  static const Color bgCardElevated = Color(0xFF22273D);
  static const Color bgSurface = Color(0xFF262C44);
  static const Color border = Color(0xFF2A304A);
  static const Color borderLight = Color(0xFF363E5E);

  // Light surface tokens
  static const Color lightBgPrimary = Color(0xFFF6F7FB);
  static const Color lightBgSecondary = Color(0xFFFFFFFF);
  static const Color lightBgCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE3E6F0);

  // Text (dark mode defaults kept for backward compatibility)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static Color surfaceBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? bgPrimary
          : lightBgPrimary;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgCard : lightBgCard;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? border : lightBorder;

  static Color primaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimary
          : const Color(0xFF111827);

  static Color secondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondary
          : const Color(0xFF4B5563);

  static Color mutedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textMuted
          : const Color(0xFF6B7280);

  static Color levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return const Color(0xFF10B981);
      case 'A2':
        return const Color(0xFF3B82F6);
      case 'B1':
        return const Color(0xFF6366F1);
      case 'B2':
        return const Color(0xFFF59E0B);
      case 'C1':
        return const Color(0xFFEC4899);
      case 'MY':
        return const Color(0xFFFF5A5F);
      default:
        return primary;
    }
  }

  static List<Color> levelGradient(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return const [Color(0xFF0D9488), Color(0xFF059669)];
      case 'A2':
        return const [Color(0xFF2563EB), Color(0xFF4F46E5)];
      case 'B1':
        return const [Color(0xFF4F46E5), Color(0xFF7C3AED)];
      case 'B2':
        return const [Color(0xFFD97706), Color(0xFFEA580C)];
      case 'C1':
        return const [Color(0xFFDB2777), Color(0xFF9333EA)];
      default:
        return const [Color(0xFF4F46E5), Color(0xFF6366F1)];
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBgPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightBgCard,
        error: AppColors.coral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBgPrimary,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightBgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : const Color(0xFF6B7280),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? AppColors.primary : const Color(0xFF6B7280),
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        selectedIconTheme:
            const IconThemeData(color: AppColors.primary, size: 24),
        unselectedIconTheme:
            const IconThemeData(color: Color(0xFF6B7280), size: 23),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.accent,
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
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primaryLight : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? AppColors.primaryLight : AppColors.textMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.bgSecondary,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.2),
        selectedIconTheme:
            const IconThemeData(color: AppColors.primaryLight, size: 24),
        unselectedIconTheme:
            const IconThemeData(color: AppColors.textMuted, size: 23),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
