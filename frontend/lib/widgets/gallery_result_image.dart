import 'dart:async';

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
    this.fullQuality = false,
  });

  final String url;
  final String? description;
  final int? seriesIndex;
  final bool compact;
  final bool photoshootSeries;
  final BoxFit fit;

  /// When true, decode and load the full remote image (viewer / fullscreen).
  final bool fullQuality;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return GalleryMockResultPreview(
        url: url,
        description: description,
        seriesIndex: seriesIndex,
        compact: compact,
        photoshootSeries: photoshootSeries,
      );
    }

    if (isMockPlaceholderImageUrl(url)) {
      return GalleryMockResultPreview(
        url: url,
        description: description,
        seriesIndex: seriesIndex,
        compact: compact,
        photoshootSeries: photoshootSeries,
      );
    }

    return _GalleryNetworkImage(
      url: url,
      description: description,
      seriesIndex: seriesIndex,
      compact: compact,
      photoshootSeries: photoshootSeries,
      fit: fit,
      fullQuality: fullQuality,
    );
  }
}

class _GalleryNetworkImage extends StatefulWidget {
  const _GalleryNetworkImage({
    required this.url,
    required this.compact,
    required this.photoshootSeries,
    required this.fit,
    required this.fullQuality,
    this.description,
    this.seriesIndex,
  });

  final String url;
  final String? description;
  final int? seriesIndex;
  final bool compact;
  final bool photoshootSeries;
  final BoxFit fit;
  final bool fullQuality;

  @override
  State<_GalleryNetworkImage> createState() => _GalleryNetworkImageState();
}

class _GalleryNetworkImageState extends State<_GalleryNetworkImage> {
  static const _slowLoadDelay = Duration(seconds: 3);

  Timer? _slowLoadTimer;
  bool _showSlowLoadingMessage = false;

  @override
  void initState() {
    super.initState();
    _slowLoadTimer = Timer(_slowLoadDelay, () {
      if (mounted) {
        setState(() => _showSlowLoadingMessage = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _GalleryNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _showSlowLoadingMessage = false;
      _slowLoadTimer?.cancel();
      _slowLoadTimer = Timer(_slowLoadDelay, () {
        if (mounted) {
          setState(() => _showSlowLoadingMessage = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _slowLoadTimer?.cancel();
    super.dispose();
  }

  void _onImageResolved() {
    _slowLoadTimer?.cancel();
    if (_showSlowLoadingMessage && mounted) {
      setState(() => _showSlowLoadingMessage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheSize = _decodeCacheSize(
          context: context,
          constraints: constraints,
          fullQuality: widget.fullQuality,
        );

        return Image.network(
          widget.url,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: cacheSize?.width,
          cacheHeight: cacheSize?.height,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onImageResolved();
              });
              return child;
            }
            return GalleryImageLoadingPlaceholder(
              compact: widget.compact,
              showSlowMessage: _showSlowLoadingMessage,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onImageResolved();
            });
            return GalleryImageErrorPlaceholder(compact: widget.compact);
          },
        );
      },
    );
  }
}

class _DecodeCacheSize {
  const _DecodeCacheSize({required this.width, required this.height});

  final int width;
  final int height;
}

_DecodeCacheSize? _decodeCacheSize({
  required BuildContext context,
  required BoxConstraints constraints,
  required bool fullQuality,
}) {
  if (fullQuality) return null;

  final width = constraints.maxWidth;
  final height = constraints.maxHeight;
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return null;
  }

  final ratio = MediaQuery.devicePixelRatioOf(context);
  return _DecodeCacheSize(
    width: (width * ratio).round().clamp(1, 2048),
    height: (height * ratio).round().clamp(1, 2048),
  );
}

/// Loading state for gallery network images.
class GalleryImageLoadingPlaceholder extends StatelessWidget {
  const GalleryImageLoadingPlaceholder({
    super.key,
    this.compact = false,
    this.showSlowMessage = false,
  });

  final bool compact;
  final bool showSlowMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFFF0F2F8),
      alignment: Alignment.center,
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: compact ? 22 : 28,
            height: compact ? 22 : 28,
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
          if (showSlowMessage) ...[
            SizedBox(height: compact ? 8 : 10),
            Text(
              'Загружаем фото…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 12 : 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error fallback when a gallery image cannot be loaded.
class GalleryImageErrorPlaceholder extends StatelessWidget {
  const GalleryImageErrorPlaceholder({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFFF0F2F8),
      alignment: Alignment.center,
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: compact ? 28 : 36,
            color: const Color(0xFF9CA3AF),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'Не удалось загрузить фото',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 12 : 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
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
        final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 148.0;
        return VisualPlaceholderSeries(
          mood: mood,
          gradientColors: gradient,
          height: height,
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
