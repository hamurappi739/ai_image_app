import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Theme-aware colors for onboarding mock UI (not real preview photos).
@immutable
class OnboardingMockupPalette {
  const OnboardingMockupPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.surface,
    required this.card,
    required this.border,
    required this.accentTint,
    required this.accent,
    required this.isDark,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color surface;
  final Color card;
  final Color border;
  final Color accentTint;
  final Color accent;
  final bool isDark;

  factory OnboardingMockupPalette.of(BuildContext context) {
    final colors = context.appColors;
    return OnboardingMockupPalette(
      textPrimary: context.appTextPrimary,
      textSecondary: colors.textSecondary,
      surface: colors.subtleFill,
      card: colors.elevatedSurface,
      border: colors.borderColor,
      accentTint: colors.selectedTile,
      accent: context.appAccent,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }

  Color goodStatusBg() =>
      isDark ? const Color(0xFF1A3D2E) : const Color(0xFFE8F7EF);

  Color badStatusBg() =>
      isDark ? const Color(0xFF3D2424) : const Color(0xFFFCEEEE);

  Color goodStatusBorder() =>
      isDark ? const Color(0xFF2E6B4A) : const Color(0xFFB8E6CF);

  Color badStatusBorder() =>
      isDark ? const Color(0xFF6B3A3A) : const Color(0xFFF0CACA);
}

class OnboardingMockupPaletteScope extends InheritedWidget {
  const OnboardingMockupPaletteScope({
    super.key,
    required this.palette,
    required super.child,
  });

  final OnboardingMockupPalette palette;

  static OnboardingMockupPalette of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OnboardingMockupPaletteScope>();
    return scope?.palette ?? OnboardingMockupPalette.of(context);
  }

  @override
  bool updateShouldNotify(OnboardingMockupPaletteScope oldWidget) =>
      palette != oldWidget.palette;
}
