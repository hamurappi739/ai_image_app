import 'package:flutter/material.dart';

import '../utils/mock_image_url.dart';
import 'visual_placeholder.dart';

/// Gallery / viewer image: real URL via network; mock/demo via rich Flutter preview.
class GalleryResultImage extends StatelessWidget {
  const GalleryResultImage({
    super.key,
    required this.url,
    this.description,
    this.seriesIndex,
    this.compact = false,
    this.photoshootSeries = false,
    this.fit = BoxFit.cover,
  });

  final String url;
  final String? description;
  final int? seriesIndex;
  final bool compact;
  final bool photoshootSeries;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (isMockPlaceholderImageUrl(url)) {
      return GalleryMockResultPreview(
        url: url,
        description: description,
        seriesIndex: seriesIndex,
        compact: compact,
        photoshootSeries: photoshootSeries,
      );
    }

    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFF0F2F8),
          alignment: Alignment.center,
          child: SizedBox(
            width: compact ? 22 : 28,
            height: compact ? 22 : 28,
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => GalleryMockResultPreview(
        url: url,
        description: description,
        seriesIndex: seriesIndex,
        compact: compact,
        photoshootSeries: photoshootSeries,
      ),
    );
  }
}

/// Rich Flutter preview for mock placeholders and failed image loads.
class GalleryMockResultPreview extends StatelessWidget {
  const GalleryMockResultPreview({
    super.key,
    required this.url,
    this.description,
    this.seriesIndex,
    this.compact = false,
    this.photoshootSeries = false,
  });

  final String url;
  final String? description;
  final int? seriesIndex;
  final bool compact;
  final bool photoshootSeries;

  @override
  Widget build(BuildContext context) {
    final seed = mockPreviewSeed(
      url,
      description: description,
      seriesIndex: seriesIndex,
    );
    final isSeriesFrame = seriesIndex != null;
    final mood = galleryPreviewMood(
      seed: seed,
      photoshoot: photoshootSeries || isSeriesFrame,
    );
    final gradient = galleryPreviewGradient(seed);
    final caption = isSeriesFrame
        ? galleryPhotoshootFrameCaption(seriesIndex!)
        : gallerySinglePreviewCaption(seed: seed, description: description);

    return VisualPlaceholder(
      mood: mood,
      gradientColors: gradient,
      caption: caption,
      secondaryBadge: isSeriesFrame ? 'Серия' : 'Готово',
      variant: seed % 4,
      compact: compact,
      showBadges: !compact,
      borderRadius: BorderRadius.zero,
    );
  }
}

/// Photoshoot group thumbnail when all frames are mock placeholders.
class GalleryPhotoshootSeriesPreview extends StatelessWidget {
  const GalleryPhotoshootSeriesPreview({
    super.key,
    required this.imageUrls,
    this.description = '',
  });

  final List<String> imageUrls;
  final String description;

  @override
  Widget build(BuildContext context) {
    final seed = mockPreviewSeed(
      imageUrls.join('|'),
      description: description,
    );
    final mood = galleryPreviewMood(seed: seed, photoshoot: true);
    final gradient = galleryPreviewGradient(seed);

    return LayoutBuilder(
      builder: (context, constraints) {
        return VisualPlaceholderSeries(
          mood: mood,
          gradientColors: gradient,
          height: constraints.maxHeight,
          variant: seed % 4,
          showCatalogBadges: true,
          recommendation: _seriesBadgeLabel(imageUrls.length),
        );
      },
    );
  }

  String? _seriesBadgeLabel(int count) {
    if (count == 3) return '3 фото';
    if (count > 1) return '$count фото';
    return null;
  }
}
