import 'package:flutter/material.dart';

/// Настроение визуальной заглушки (без реальных фото).
enum VisualPlaceholderMood {
  portrait,
  business,
  winter,
  summer,
  product,
  family,
  interior,
  photoshoot,
  premium,
}

class VisualPlaceholderTheme {
  const VisualPlaceholderTheme({
    required this.gradientColors,
    required this.icon,
    required this.caption,
  });

  final List<Color> gradientColors;
  final IconData icon;
  final String caption;
}

/// Палитры и подписи по настроению.
class VisualPlaceholderPalette {
  VisualPlaceholderPalette._();

  static const accent = Color(0xFF5B6CFF);
  static const textSecondary = Color(0xFF6B7280);
  static const textPrimary = Color(0xFF1A1D26);

  static VisualPlaceholderTheme theme(VisualPlaceholderMood mood) {
    return switch (mood) {
      VisualPlaceholderMood.portrait => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFF8EEF5), Color(0xFFE8D0E0)],
          icon: Icons.face_retouching_natural_outlined,
          caption: 'Портрет',
        ),
      VisualPlaceholderMood.business => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFE4ECF4), Color(0xFFB0C0D4)],
          icon: Icons.business_center_outlined,
          caption: 'Деловой образ',
        ),
      VisualPlaceholderMood.winter => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFE6F2FA), Color(0xFFA8CCE8)],
          icon: Icons.ac_unit_outlined,
          caption: 'Зима',
        ),
      VisualPlaceholderMood.summer => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFFFF4E0), Color(0xFFE8D090)],
          icon: Icons.wb_sunny_outlined,
          caption: 'Лето',
        ),
      VisualPlaceholderMood.product => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFEAF4EE), Color(0xFFB8D4C8)],
          icon: Icons.inventory_2_outlined,
          caption: 'Товар',
        ),
      VisualPlaceholderMood.family => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFF5EBE0), Color(0xFFD8C0A8)],
          icon: Icons.family_restroom_outlined,
          caption: 'Семья',
        ),
      VisualPlaceholderMood.interior => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFF2EDE6), Color(0xFFC8B8A4)],
          icon: Icons.weekend_outlined,
          caption: 'Интерьер',
        ),
      VisualPlaceholderMood.photoshoot => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
          icon: Icons.photo_camera_outlined,
          caption: 'Фотосессия',
        ),
      VisualPlaceholderMood.premium => const VisualPlaceholderTheme(
          gradientColors: [Color(0xFFD8C8F0), Color(0xFF9070C8)],
          icon: Icons.diamond_outlined,
          caption: 'Премиум',
        ),
    };
  }

  static VisualPlaceholderMood moodForPhotoshootId(String styleId) {
    return switch (styleId) {
      'studio_portrait' => VisualPlaceholderMood.photoshoot,
      'business_portrait' ||
      'business_brand' ||
      'expert_photoshoot' =>
        VisualPlaceholderMood.business,
      'urban_portrait' ||
      'cafe_city' ||
      'park_walk' ||
      'personal_brand' =>
        VisualPlaceholderMood.photoshoot,
      'evening_look' || 'premium_portrait' => VisualPlaceholderMood.premium,
      'winter_photoshoot' => VisualPlaceholderMood.winter,
      'summer_photoshoot' => VisualPlaceholderMood.summer,
      'home_portrait' || 'tender_photoshoot' => VisualPlaceholderMood.portrait,
      'travel_portrait' => VisualPlaceholderMood.summer,
      'custom_photoshoot' => VisualPlaceholderMood.photoshoot,
      _ => VisualPlaceholderMood.photoshoot,
    };
  }
}

/// Одна карточка-превью для шаблонов и help-блоков.
class VisualPlaceholder extends StatelessWidget {
  const VisualPlaceholder({
    super.key,
    required this.mood,
    this.height = 120,
    this.caption,
    this.icon,
    this.gradientColors,
    this.variant = 0,
    this.showExampleBadge = true,
    this.borderRadius = BorderRadius.zero,
    this.compact = false,
    this.dimmed = false,
  });

  final VisualPlaceholderMood mood;
  final double height;
  final String? caption;
  final IconData? icon;
  final List<Color>? gradientColors;
  final int variant;
  final bool showExampleBadge;
  final BorderRadius borderRadius;
  final bool compact;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final base = VisualPlaceholderPalette.theme(mood);
    final colors = gradientColors ?? base.gradientColors;
    final onDark = colors.first.computeLuminance() < 0.42;
    final label = caption ?? base.caption;
    final centerIcon = icon ?? base.icon;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            ..._PlaceholderDecorations.build(
              mood: mood,
              variant: variant,
              onDark: onDark,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: onDark ? 0.08 : 0.2),
                      Colors.transparent,
                      Colors.black.withValues(alpha: onDark ? 0.1 : 0.04),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -8,
              bottom: -12,
              child: Icon(
                centerIcon,
                size: compact ? 64 : 80,
                color: (onDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
              ),
            ),
            Center(
              child: _PlaceholderCenterVisual(
                mood: mood,
                icon: centerIcon,
                onDark: onDark,
                compact: compact,
              ),
            ),
            if (showExampleBadge)
              Positioned(
                top: 8,
                left: 8,
                child: _SoftBadge(
                  label: 'Пример',
                  onDark: onDark,
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.auto_awesome,
                size: compact ? 14 : 16,
                color: Colors.white.withValues(alpha: onDark ? 0.7 : 0.55),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _CaptionChip(label: label, onDark: onDark),
            ),
            if (dimmed)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Серия из трёх мини-превью для фотосессий.
class VisualPlaceholderSeries extends StatelessWidget {
  const VisualPlaceholderSeries({
    super.key,
    required this.mood,
    this.height = 148,
    this.gradientColors,
    this.icon,
    this.variant = 0,
    this.showCatalogBadges = false,
    this.recommendation,
    this.showPremiumStar = false,
    this.borderRadius = BorderRadius.zero,
    this.showPhotoLabels = false,
  });

  final VisualPlaceholderMood mood;
  final double height;
  final List<Color>? gradientColors;
  final IconData? icon;
  final int variant;
  final bool showCatalogBadges;
  final String? recommendation;
  final bool showPremiumStar;
  final BorderRadius borderRadius;
  final bool showPhotoLabels;

  @override
  Widget build(BuildContext context) {
    final base = VisualPlaceholderPalette.theme(mood);
    final colors = gradientColors ?? base.gradientColors;
    final onDark = colors.first.computeLuminance() < 0.42;
    final centerIcon = icon ?? base.icon;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            ..._PlaceholderDecorations.build(
              mood: mood,
              variant: variant,
              onDark: onDark,
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = height < 110;
                final topInset = compact ? 22.0 : 28.0;
                final bottomInset = compact ? 8.0 : 12.0;
                final labelSpace = showPhotoLabels ? 14.0 : 0.0;
                final miniHeight = (constraints.maxHeight -
                        topInset -
                        bottomInset -
                        labelSpace)
                    .clamp(36.0, 120.0);

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 10 : 14,
                    topInset,
                    compact ? 10 : 14,
                    bottomInset,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) SizedBox(width: compact ? 6 : 8),
                        Expanded(
                          child: _SeriesMiniCard(
                            index: i,
                            colors: colors,
                            icon: centerIcon,
                            onDark: onDark,
                            label: showPhotoLabels ? 'Фото ${i + 1}' : null,
                            cardHeight: miniHeight,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            if (showCatalogBadges) ...[
              if (recommendation != null && recommendation!.isNotEmpty)
                Positioned(
                  left: 10,
                  top: 10,
                  child: _SoftBadge(
                    label: recommendation!,
                    onDark: onDark,
                    solid: true,
                  ),
                ),
              Positioned(
                right: 10,
                top: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showPremiumStar) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: onDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : VisualPlaceholderPalette.accent,
                      ),
                      const SizedBox(width: 6),
                    ],
                    _SoftBadge(
                      label: '3 фото',
                      onDark: onDark,
                      solid: true,
                      emphasized: true,
                    ),
                  ],
                ),
              ),
            ] else
              Positioned(
                right: 10,
                top: 10,
                child: _SoftBadge(
                  label: '3 фото',
                  onDark: onDark,
                  solid: true,
                  emphasized: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeriesMiniCard extends StatelessWidget {
  const _SeriesMiniCard({
    required this.index,
    required this.colors,
    required this.icon,
    required this.onDark,
    required this.cardHeight,
    this.label,
  });

  final int index;
  final List<Color> colors;
  final IconData icon;
  final bool onDark;
  final double cardHeight;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tilt = (index - 1) * 0.04;
    final dy = index == 1 ? -3.0 : 0.0;

    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: tilt,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: cardHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(colors.first, Colors.white, 0.12 + index * 0.06)!,
                      Color.lerp(colors.last, Colors.white, index * 0.04)!,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: -4,
                      bottom: -6,
                      child: Icon(
                        icon,
                        size: 28,
                        color: colors.last.withValues(alpha: 0.2),
                      ),
                    ),
                    Icon(
                      Icons.person_outline,
                      size: 20 + index * 2.0,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(
                label!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.88)
                      : VisualPlaceholderPalette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCenterVisual extends StatelessWidget {
  const _PlaceholderCenterVisual({
    required this.mood,
    required this.icon,
    required this.onDark,
    required this.compact,
  });

  final VisualPlaceholderMood mood;
  final IconData icon;
  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 56.0 : 68.0;
    final glyph = compact ? 26.0 : 32.0;

    if (mood == VisualPlaceholderMood.product ||
        mood == VisualPlaceholderMood.interior) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.72),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: glyph, color: VisualPlaceholderPalette.accent),
      );
    }

    return Container(
      width: size * 0.88,
      height: size * 1.1,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(size * 0.44),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.68),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: glyph,
        color: onDark
            ? Colors.white.withValues(alpha: 0.92)
            : VisualPlaceholderPalette.accent.withValues(alpha: 0.88),
      ),
    );
  }
}

class _CaptionChip extends StatelessWidget {
  const _CaptionChip({required this.label, required this.onDark});

  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.black.withValues(alpha: 0.32)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: onDark ? Colors.white : VisualPlaceholderPalette.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    required this.onDark,
    this.solid = false,
    this.emphasized = false,
  });

  final String label;
  final bool onDark;
  final bool solid;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: solid
            ? Colors.white.withValues(alpha: onDark ? 0.92 : 0.9)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasized
              ? VisualPlaceholderPalette.textPrimary
              : VisualPlaceholderPalette.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlaceholderDecorations {
  static List<Widget> build({
    required VisualPlaceholderMood mood,
    required int variant,
    required bool onDark,
  }) {
    final accent = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.32);

    final moodExtras = switch (mood) {
      VisualPlaceholderMood.winter => [
          Positioned(
            top: 14,
            right: 18,
            child: Icon(
              Icons.ac_unit,
              size: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      VisualPlaceholderMood.summer => [
          Positioned(
            top: 12,
            right: 16,
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      VisualPlaceholderMood.premium => [
          Positioned(
            top: 36,
            left: 20,
            child: Icon(
              Icons.star_outline,
              size: 14,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      VisualPlaceholderMood.family => [
          Positioned(
            bottom: 40,
            right: 22,
            child: Icon(
              Icons.favorite_border,
              size: 14,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      _ => <Widget>[],
    };

    final variantExtras = switch (variant % 4) {
      1 => [
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 28,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
            ),
          ),
        ],
      2 => [
          Positioned(
            right: 14,
            top: 36,
            child: Container(
              width: 32,
              height: 42,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      3 => [
          Positioned(
            left: 12,
            top: 12,
            right: 12,
            bottom: 36,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent, width: 1.2),
              ),
            ),
          ),
        ],
      _ => [
          Positioned(
            left: 16,
            bottom: 36,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
    };

    return [...variantExtras, ...moodExtras];
  }
}
