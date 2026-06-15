import 'package:flutter/material.dart';

import '../assets/preview_asset_paths.dart';
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

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSheet = style == GoodResultGuideStyle.sheet;

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
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildHeaderTexts(theme)),
            ],
          )
        else
          _buildHeaderTexts(theme),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const minCardWidth = 148.0;
            final fitsInRow =
                constraints.maxWidth >= minCardWidth * 2 + 12;

            const good = _GuidePhotoExampleCard(isGood: true);
            const bad = _GuidePhotoExampleCard(isGood: false);

            if (fitsInRow) {
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: good),
                  SizedBox(width: 12),
                  Expanded(child: bad),
                ],
              );
            }

            return SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  SizedBox(width: minCardWidth, child: good),
                  SizedBox(width: 12),
                  SizedBox(width: minCardWidth, child: bad),
                ],
              ),
            );
          },
        ),
      ],
    );

    if (isSheet) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EAEF)),
        ),
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildHeaderTexts(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Как получить хороший результат',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Лучше всего подходят чёткие фото, где лицо хорошо видно.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            height: 1.35,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GuidePhotoExampleCard extends StatelessWidget {
  const _GuidePhotoExampleCard({required this.isGood});

  final bool isGood;

  static const _goodColors = [Color(0xFFD4E0EE), Color(0xFF8EA4BE)];
  static const _badColors = [Color(0xFF3A3F4B), Color(0xFF6B7280)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isGood ? const Color(0xFF2E9B66) : const Color(0xFFC45C5C);
    final statusBg = isGood ? const Color(0xFFE8F7EF) : const Color(0xFFFCEEEE);
    final badgeLabel = isGood ? 'Хорошее фото' : 'Плохое фото';
    final hint = isGood
        ? 'Лицо хорошо видно, свет ровный, фото не размыто.'
        : 'Фото тёмное, лицо далеко, закрыто или размыто.';
    final assetPath = isGood
        ? PreviewAssetPaths.guidesGoodPhoto
        : PreviewAssetPaths.guidesBadPhoto;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood ? const Color(0xFFB8E6CF) : const Color(0xFFF0CACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1,
            child: PreviewAssetImage(
              assetPath: assetPath,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(10),
              placeholder: VisualPlaceholder(
                mood: isGood
                    ? VisualPlaceholderMood.portrait
                    : VisualPlaceholderMood.business,
                gradientColors: isGood ? _goodColors : _badColors,
                icon: isGood
                    ? Icons.face_retouching_natural_outlined
                    : Icons.face_outlined,
                height: 120,
                compact: true,
                dimmed: !isGood,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              height: 1.35,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
