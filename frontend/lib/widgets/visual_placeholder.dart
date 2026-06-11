import 'package:flutter/material.dart';

import '../assets/preview_asset_paths.dart';
import 'preview_asset_image.dart';

/// Настроение визуальной заглушки (без реальных фото).
enum VisualPlaceholderMood {
  portrait,
  social,
  business,
  winter,
  summer,
  family,
  product,
  interior,
  photoshoot,
  premium,
}

class VisualPlaceholderTheme {
  const VisualPlaceholderTheme({
    required this.gradientColors,
    required this.icon,
    required this.caption,
    this.secondaryBadge,
  });

  final List<Color> gradientColors;
  final IconData icon;
  final String caption;
  final String? secondaryBadge;
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
          gradientColors: [
            Color(0xFFFFF5FA),
            Color(0xFFF3E0ED),
            Color(0xFFE2C4D8),
          ],
          icon: Icons.face_retouching_natural_outlined,
          caption: 'Портрет',
          secondaryBadge: 'Образ',
        ),
      VisualPlaceholderMood.social => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFF5F0FF),
            Color(0xFFE6DEFF),
            Color(0xFFC8B8F0),
          ],
          icon: Icons.camera_front_outlined,
          caption: 'Для соцсетей',
          secondaryBadge: 'Образ',
        ),
      VisualPlaceholderMood.business => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFF2F6FA),
            Color(0xFFDCE6F0),
            Color(0xFFB4C4D8),
          ],
          icon: Icons.business_center_outlined,
          caption: 'Деловой',
          secondaryBadge: 'Образ',
        ),
      VisualPlaceholderMood.winter => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFF4FAFF),
            Color(0xFFD8ECFA),
            Color(0xFFA8D0EC),
          ],
          icon: Icons.ac_unit_outlined,
          caption: 'Зима',
          secondaryBadge: 'Атмосфера',
        ),
      VisualPlaceholderMood.summer => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFFFFAF0),
            Color(0xFFFFF0D0),
            Color(0xFFE8D090),
          ],
          icon: Icons.wb_sunny_outlined,
          caption: 'Лето',
          secondaryBadge: 'Атмосфера',
        ),
      VisualPlaceholderMood.product => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFF4FAF6),
            Color(0xFFDCEEE4),
            Color(0xFFB0D4C4),
          ],
          icon: Icons.inventory_2_outlined,
          caption: 'Товар',
          secondaryBadge: 'Продажа',
        ),
      VisualPlaceholderMood.family => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFFFFAF5),
            Color(0xFFF0E4D8),
            Color(0xFFD4B8A0),
          ],
          icon: Icons.family_restroom_outlined,
          caption: 'Семья',
          secondaryBadge: 'Тепло',
        ),
      VisualPlaceholderMood.interior => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFFAF7F2),
            Color(0xFFE8E0D4),
            Color(0xFFC8B8A4),
          ],
          icon: Icons.weekend_outlined,
          caption: 'Интерьер',
          secondaryBadge: 'Уют',
        ),
      VisualPlaceholderMood.photoshoot => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFF6F2FF),
            Color(0xFFE8E2FF),
            Color(0xFFC4B8E8),
          ],
          icon: Icons.photo_camera_outlined,
          caption: 'Фотосессия',
          secondaryBadge: '3 фото',
        ),
      VisualPlaceholderMood.premium => const VisualPlaceholderTheme(
          gradientColors: [
            Color(0xFFF0E8FF),
            Color(0xFFD8C4F8),
            Color(0xFFA888E0),
          ],
          icon: Icons.diamond_outlined,
          caption: 'Премиум',
          secondaryBadge: 'Образ',
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

  static LinearGradient gradientFor(List<Color> colors) {
    if (colors.length >= 3) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0.0, 0.52, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}

/// Hero-блок главной в едином стиле с карточками.
class VisualPlaceholderHero extends StatelessWidget {
  const VisualPlaceholderHero({
    super.key,
    this.isCompact = false,
    this.previewAssetPath,
  });

  final bool isCompact;

  /// Defaults to [PreviewAssetPaths.homeHero] when not overridden.
  final String? previewAssetPath;

  static const _heroColors = [
    Color(0xFFFFF5FA),
    Color(0xFFEDE9FF),
    Color(0xFFC5D8FF),
  ];

  @override
  Widget build(BuildContext context) {
    final height = isCompact ? 188.0 : 220.0;
    final resolvedAsset = previewAssetPath ?? PreviewAssetPaths.homeHero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PreviewAssetImage(
          assetPath: resolvedAsset,
          height: height,
          borderRadius: BorderRadius.circular(24),
          placeholder: _HeroPlaceholderCanvas(isCompact: isCompact),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _HeroFeatureBadge(
              icon: Icons.dashboard_customize_outlined,
              label: 'Шаблоны',
            ),
            _HeroFeatureBadge(
              icon: Icons.photo_camera_outlined,
              label: 'Фотосессии',
            ),
            _HeroFeatureBadge(
              icon: Icons.edit_outlined,
              label: 'Свой запрос',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroPlaceholderCanvas extends StatelessWidget {
  const _HeroPlaceholderCanvas({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: VisualPlaceholderPalette.gradientFor(
                  VisualPlaceholderHero._heroColors,
                ),
              ),
            ),
            ..._PlaceholderDecorations.build(
              mood: VisualPlaceholderMood.portrait,
              variant: 0,
              onDark: false,
              rich: true,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlaceholderCenterVisual(
                    mood: VisualPlaceholderMood.portrait,
                    icon: Icons.face_retouching_natural_outlined,
                    onDark: false,
                    compact: isCompact,
                  ),
                  SizedBox(height: isCompact ? 10 : 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VisualPlaceholderPalette.accent
                              .withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Ваш новый образ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: VisualPlaceholderPalette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 14,
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFeatureBadge extends StatelessWidget {
  const _HeroFeatureBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: VisualPlaceholderPalette.accent.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: VisualPlaceholderPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Одна карточка-превью для шаблонов и help-блоков.
class VisualPlaceholder extends StatelessWidget {
  const VisualPlaceholder({
    super.key,
    required this.mood,
    this.height = 120,
    this.caption,
    this.secondaryBadge,
    this.icon,
    this.gradientColors,
    this.variant = 0,
    this.showBadges = true,
    this.borderRadius = BorderRadius.zero,
    this.compact = false,
    this.dimmed = false,
  });

  final VisualPlaceholderMood mood;
  final double height;
  final String? caption;
  final String? secondaryBadge;
  final IconData? icon;
  final List<Color>? gradientColors;
  final int variant;
  final bool showBadges;
  final BorderRadius borderRadius;
  final bool compact;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final base = VisualPlaceholderPalette.theme(mood);
    final colors = gradientColors ?? base.gradientColors;
    final onDark = colors.first.computeLuminance() < 0.42;
    final topLabel = caption ?? base.caption;
    final bottomLabel = secondaryBadge ?? base.secondaryBadge;
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
                gradient: VisualPlaceholderPalette.gradientFor(colors),
              ),
            ),
            ..._PlaceholderDecorations.build(
              mood: mood,
              variant: variant,
              onDark: onDark,
              rich: true,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: onDark ? 0.1 : 0.22),
                      Colors.transparent,
                      Colors.black.withValues(alpha: onDark ? 0.12 : 0.04),
                    ],
                  ),
                ),
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
            if (showBadges) ...[
              Positioned(
                top: 8,
                left: 8,
                child: _SoftBadge(label: topLabel, onDark: onDark),
              ),
              if (bottomLabel != null)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _SoftBadge(
                    label: bottomLabel,
                    onDark: onDark,
                    subtle: true,
                  ),
                ),
            ],
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.auto_awesome,
                size: compact ? 13 : 15,
                color: Colors.white.withValues(alpha: onDark ? 0.72 : 0.5),
              ),
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
                gradient: VisualPlaceholderPalette.gradientFor(colors),
              ),
            ),
            ..._PlaceholderDecorations.build(
              mood: mood,
              variant: variant,
              onDark: onDark,
              rich: true,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.transparent,
                      Colors.black.withValues(alpha: onDark ? 0.1 : 0.05),
                    ],
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = height < 110;
                final topInset = compact ? 20.0 : 26.0;
                final bottomInset = compact ? 8.0 : 10.0;
                final labelSpace = showPhotoLabels ? 14.0 : 0.0;
                final baseMiniHeight = (constraints.maxHeight -
                        topInset -
                        bottomInset -
                        labelSpace)
                    .clamp(40.0, 120.0);

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 10 : 12,
                    topInset,
                    compact ? 10 : 12,
                    bottomInset,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _SeriesMiniCard(
                          index: 0,
                          colors: colors,
                          icon: centerIcon,
                          mood: mood,
                          onDark: onDark,
                          label: showPhotoLabels ? 'Фото 1' : null,
                          cardHeight: baseMiniHeight * 0.92,
                        ),
                      ),
                      SizedBox(width: compact ? 5 : 7),
                      Expanded(
                        flex: 5,
                        child: _SeriesMiniCard(
                          index: 1,
                          colors: colors,
                          icon: centerIcon,
                          mood: mood,
                          onDark: onDark,
                          label: showPhotoLabels ? 'Фото 2' : null,
                          cardHeight: baseMiniHeight * 1.08,
                          emphasized: true,
                        ),
                      ),
                      SizedBox(width: compact ? 5 : 7),
                      Expanded(
                        flex: 4,
                        child: _SeriesMiniCard(
                          index: 2,
                          colors: colors,
                          icon: centerIcon,
                          mood: mood,
                          onDark: onDark,
                          label: showPhotoLabels ? 'Фото 3' : null,
                          cardHeight: baseMiniHeight * 0.92,
                        ),
                      ),
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
                            ? Colors.white.withValues(alpha: 0.88)
                            : VisualPlaceholderPalette.accent,
                      ),
                      const SizedBox(width: 5),
                    ],
                    _SoftBadge(
                      label: '3 фото',
                      onDark: onDark,
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
    required this.mood,
    required this.onDark,
    required this.cardHeight,
    this.label,
    this.emphasized = false,
  });

  final int index;
  final List<Color> colors;
  final IconData icon;
  final VisualPlaceholderMood mood;
  final bool onDark;
  final double cardHeight;
  final String? label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tilt = (index - 1) * 0.035;
    final dy = emphasized ? -5.0 : (index == 0 ? 1.0 : 2.0);

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
                  borderRadius: BorderRadius.circular(emphasized ? 12 : 10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        colors.first,
                        Colors.white,
                        emphasized ? 0.18 : 0.1 + index * 0.04,
                      )!,
                      Color.lerp(
                        colors.last,
                        Colors.white,
                        emphasized ? 0.08 : index * 0.03,
                      )!,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: emphasized ? 0.82 : 0.68),
                    width: emphasized ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: emphasized ? 0.14 : 0.09,
                      ),
                      blurRadius: emphasized ? 12 : 8,
                      offset: Offset(0, emphasized ? 5 : 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: -2,
                      bottom: -4,
                      child: Icon(
                        icon,
                        size: emphasized ? 30 : 24,
                        color: colors.last.withValues(alpha: 0.18),
                      ),
                    ),
                    _MiniSilhouette(
                      mood: mood,
                      emphasized: emphasized,
                      onDark: onDark,
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

class _MiniSilhouette extends StatelessWidget {
  const _MiniSilhouette({
    required this.mood,
    required this.emphasized,
    required this.onDark,
  });

  final VisualPlaceholderMood mood;
  final bool emphasized;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (mood == VisualPlaceholderMood.product ||
        mood == VisualPlaceholderMood.interior) {
      return Icon(
        VisualPlaceholderPalette.theme(mood).icon,
        size: emphasized ? 22 : 18,
        color: VisualPlaceholderPalette.accent.withValues(alpha: 0.75),
      );
    }

    return CustomPaint(
      size: Size(emphasized ? 22 : 18, emphasized ? 30 : 24),
      painter: _PersonSilhouettePainter(
        color: onDark
            ? Colors.white.withValues(alpha: 0.88)
            : VisualPlaceholderPalette.accent.withValues(alpha: 0.72),
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
    final size = compact ? 58.0 : 72.0;

    if (mood == VisualPlaceholderMood.product ||
        mood == VisualPlaceholderMood.interior) {
      return Container(
        width: size,
        height: size * 0.92,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.78),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: compact ? 26 : 30,
          color: VisualPlaceholderPalette.accent.withValues(alpha: 0.88),
        ),
      );
    }

    return Container(
      width: size * 0.82,
      height: size * 1.05,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(size * 0.42),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _PersonSilhouettePainter(
          color: onDark
              ? Colors.white.withValues(alpha: 0.92)
              : VisualPlaceholderPalette.accent.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _PersonSilhouettePainter extends CustomPainter {
  _PersonSilhouettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final headRadius = size.width * 0.22;
    final headCenter = Offset(size.width * 0.5, size.height * 0.3);

    canvas.drawCircle(headCenter, headRadius, paint);

    final bodyPath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.48,
        size.width * 0.78,
        size.height * 0.92,
      )
      ..close();
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant _PersonSilhouettePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    required this.onDark,
    this.emphasized = false,
    this.subtle = false,
  });

  final String label;
  final bool onDark;
  final bool emphasized;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: subtle
            ? (onDark
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.72))
            : Colors.white.withValues(alpha: onDark ? 0.92 : 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasized || !subtle
              ? VisualPlaceholderPalette.textPrimary
              : (onDark ? Colors.white : VisualPlaceholderPalette.textSecondary),
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
    bool rich = false,
  }) {
    final glow = onDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.45);

    final baseOrbs = rich
        ? [
            Positioned(
              left: -28,
              top: -18,
              child: _GlowOrb(diameter: 96, color: glow),
            ),
            Positioned(
              right: -16,
              bottom: -22,
              child: _GlowOrb(
                diameter: 72,
                color: glow.withValues(alpha: onDark ? 0.1 : 0.32),
              ),
            ),
            Positioned(
              right: 28,
              top: 18,
              child: _GlowOrb(
                diameter: 36,
                color: glow.withValues(alpha: onDark ? 0.08 : 0.24),
              ),
            ),
          ]
        : <Widget>[];

    final moodExtras = switch (mood) {
      VisualPlaceholderMood.winter => [
          Positioned(
            top: 16,
            right: 20,
            child: Icon(
              Icons.ac_unit,
              size: 15,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 28,
            child: Icon(
              Icons.ac_unit_outlined,
              size: 12,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ],
      VisualPlaceholderMood.summer => [
          Positioned(
            top: 14,
            right: 18,
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.58),
            ),
          ),
        ],
      VisualPlaceholderMood.premium => [
          Positioned(
            top: 34,
            left: 22,
            child: Icon(
              Icons.star_outline,
              size: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 26,
            child: Icon(
              Icons.diamond_outlined,
              size: 13,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ),
        ],
      VisualPlaceholderMood.family => [
          Positioned(
            bottom: 36,
            right: 24,
            child: Icon(
              Icons.favorite_border,
              size: 14,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      VisualPlaceholderMood.business => [
          Positioned(
            top: 22,
            left: 20,
            child: Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      VisualPlaceholderMood.social => [
          Positioned(
            top: 18,
            left: 22,
            child: Icon(
              Icons.tag_faces_outlined,
              size: 14,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ),
        ],
      _ => <Widget>[],
    };

    final variantExtras = switch (variant % 4) {
      1 => [
          Positioned(
            left: 14,
            bottom: 24,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: glow, width: 2),
              ),
            ),
          ),
        ],
      2 => [
          Positioned(
            right: 18,
            top: 40,
            child: Container(
              width: 26,
              height: 34,
              decoration: BoxDecoration(
                color: glow.withValues(alpha: onDark ? 0.09 : 0.28),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      3 => [
          Positioned(
            left: 10,
            top: 10,
            right: 10,
            bottom: 30,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: glow.withValues(alpha: onDark ? 0.1 : 0.3),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      _ => <Widget>[],
    };

    return [...baseOrbs, ...variantExtras, ...moodExtras];
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
