import 'package:flutter/material.dart';

const _accentColor = Color(0xFF5B6CFF);

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.cardBackground,
    required this.borderColor,
    required this.textSecondary,
    required this.subtleFill,
    required this.selectedTile,
    required this.drawerGradientStart,
    required this.drawerGradientEnd,
    required this.chipBackground,
    required this.mutedBadgeFill,
  });

  final Color cardBackground;
  final Color borderColor;
  final Color textSecondary;
  final Color subtleFill;
  final Color selectedTile;
  final Color drawerGradientStart;
  final Color drawerGradientEnd;
  final Color chipBackground;
  final Color mutedBadgeFill;

  static const light = AppThemeColors(
    cardBackground: Colors.white,
    borderColor: Color(0xFFE8EAEF),
    textSecondary: Color(0xFF6B7280),
    subtleFill: Color(0xFFF7F8FC),
    selectedTile: Color(0xFFEDE9FF),
    drawerGradientStart: Color(0xFFF5F7FF),
    drawerGradientEnd: Color(0xFFEDE9FF),
    chipBackground: Color(0xFFF7F8FC),
    mutedBadgeFill: Color(0xFFF3F4F6),
  );

  static const dark = AppThemeColors(
    cardBackground: Color(0xFF171A22),
    borderColor: Color(0xFF2A2F3D),
    textSecondary: Color(0xFFA7ADBD),
    subtleFill: Color(0xFF1E2230),
    selectedTile: Color(0xFF252B3D),
    drawerGradientStart: Color(0xFF1A1F2E),
    drawerGradientEnd: Color(0xFF222838),
    chipBackground: Color(0xFF1E2230),
    mutedBadgeFill: Color(0xFF252B3D),
  );

  @override
  AppThemeColors copyWith({
    Color? cardBackground,
    Color? borderColor,
    Color? textSecondary,
    Color? subtleFill,
    Color? selectedTile,
    Color? drawerGradientStart,
    Color? drawerGradientEnd,
    Color? chipBackground,
    Color? mutedBadgeFill,
  }) {
    return AppThemeColors(
      cardBackground: cardBackground ?? this.cardBackground,
      borderColor: borderColor ?? this.borderColor,
      textSecondary: textSecondary ?? this.textSecondary,
      subtleFill: subtleFill ?? this.subtleFill,
      selectedTile: selectedTile ?? this.selectedTile,
      drawerGradientStart: drawerGradientStart ?? this.drawerGradientStart,
      drawerGradientEnd: drawerGradientEnd ?? this.drawerGradientEnd,
      chipBackground: chipBackground ?? this.chipBackground,
      mutedBadgeFill: mutedBadgeFill ?? this.mutedBadgeFill,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      subtleFill: Color.lerp(subtleFill, other.subtleFill, t)!,
      selectedTile: Color.lerp(selectedTile, other.selectedTile, t)!,
      drawerGradientStart:
          Color.lerp(drawerGradientStart, other.drawerGradientStart, t)!,
      drawerGradientEnd:
          Color.lerp(drawerGradientEnd, other.drawerGradientEnd, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      mutedBadgeFill: Color.lerp(mutedBadgeFill, other.mutedBadgeFill, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;

  Color get appAccent => Theme.of(this).colorScheme.primary;

  Color get appTextPrimary => Theme.of(this).colorScheme.onSurface;
}

class AppTheme {
  AppTheme._();

  static const Color lightScaffold = Color(0xFFF7F8FC);
  static const Color darkScaffold = Color(0xFF0F1117);

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        scaffold: lightScaffold,
        surface: AppThemeColors.light.cardBackground,
        onSurface: const Color(0xFF1A1D26),
        onSurfaceVariant: AppThemeColors.light.textSecondary,
        extension: AppThemeColors.light,
        divider: const Color(0xFFE8EAEF),
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        scaffold: darkScaffold,
        surface: AppThemeColors.dark.cardBackground,
        onSurface: const Color(0xFFF3F4F8),
        onSurfaceVariant: AppThemeColors.dark.textSecondary,
        extension: AppThemeColors.dark,
        divider: const Color(0xFF2A2F3D),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required AppThemeColors extension,
    required Color divider,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accentColor,
      brightness: brightness,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      dividerColor: divider,
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: extension.borderColor),
        ),
      ),
      colorScheme: colorScheme,
      extensions: [extension],
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          color: onSurfaceVariant,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
    );
  }
}
