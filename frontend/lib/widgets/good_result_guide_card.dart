import 'package:flutter/material.dart';

import '../assets/preview_asset_paths.dart';
import '../theme/app_theme.dart';
import 'preview_asset_image.dart';
import 'visual_placeholder.dart';

/// Visual style for [GoodResultGuideCard].
enum GoodResultGuideStyle {
  /// Full card with shadow — for scrollable screens (e.g. «Своя идея»).
  card,

  /// Flat inset panel — for bottom sheets and modals.
  sheet,
}

/// Shared «Как получить хороший результат» block for create flows.
class GoodResultGuideCard extends StatelessWidget {
  const GoodResultGuideCard({
    super.key,
    this.style = GoodResultGuideStyle.card,
  });

  final GoodResultGuideStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final isSheet = style == GoodResultGuideStyle.sheet;
    final isLight = theme.brightness == Brightness.light;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSheet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.selectedTile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: context.appAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildHeaderTexts(theme, colors)),
            ],
          )
        else
          _buildHeaderTexts(theme, colors),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const stackBreakpoint = 430.0;
            final stackVertically = constraints.maxWidth < stackBreakpoint;
            final compact = stackVertically;

            final good = _GuidePhotoExampleCard(isGood: true, compact: compact);
            final bad = _GuidePhotoExampleCard(isGood: false, compact: compact);

            if (stackVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  good,
                  SizedBox(height: compact ? 10 : 12),
                  bad,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: good),
                const SizedBox(width: 12),
                Expanded(child: bad),
              ],
            );
          },
        ),
      ],
    );

    if (isSheet) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: colors.subtleFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderColor),
        ),
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: content,
    );
  }

  Widget _buildHeaderTexts(ThemeData theme, AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Как получить хороший результат',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Лучше всего подходят чёткие фото, где лицо хорошо видно.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            height: 1.35,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GuidePhotoExampleCard extends StatelessWidget {
  const _GuidePhotoExampleCard({
    required this.isGood,
    this.compact = false,
  });

  final bool isGood;
  final bool compact;

  static const _goodColors = [Color(0xFFD4E0EE), Color(0xFF8EA4BE)];
  static const _badColors = [Color(0xFF3A3F4B), Color(0xFF6B7280)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = isGood
        ? (isDark ? const Color(0xFF6BCF9B) : const Color(0xFF2E9B66))
        : (isDark ? const Color(0xFFF08A8A) : const Color(0xFFC45C5C));
    final statusBg = isGood
        ? (isDark ? const Color(0xFF1F3D32) : const Color(0xFFE8F7EF))
        : (isDark ? const Color(0xFF3D2828) : const Color(0xFFFCEEEE));
    final cardBorder = isGood
        ? (isDark ? const Color(0xFF2D5A47) : const Color(0xFFB8E6CF))
        : (isDark ? const Color(0xFF5A3838) : const Color(0xFFF0CACA));
    final badgeLabel = isGood ? 'Хорошее фото' : 'Плохое фото';
    final hint = isGood
        ? 'Лицо хорошо видно, свет ровный, фото не размыто.'
        : 'Фото тёмное, лицо далеко, закрыто или размыто.';
    final assetPath = isGood
        ? PreviewAssetPaths.guidesGoodPhoto
        : PreviewAssetPaths.guidesBadPhoto;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 8,
              vertical: compact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          AspectRatio(
            aspectRatio: compact ? 4 / 3 : 1,
            child: PreviewAssetImage(
              assetPath: assetPath,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(compact ? 8 : 10),
              placeholder: VisualPlaceholder(
                mood: isGood
                    ? VisualPlaceholderMood.portrait
                    : VisualPlaceholderMood.business,
                gradientColors: isGood ? _goodColors : _badColors,
                icon: isGood
                    ? Icons.face_retouching_natural_outlined
                    : Icons.face_outlined,
                height: compact ? 90 : 120,
                compact: true,
                dimmed: !isGood,
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.3,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
