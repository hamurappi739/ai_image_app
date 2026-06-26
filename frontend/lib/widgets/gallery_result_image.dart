import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/gallery_image_proxy_url.dart';
import '../utils/mock_image_url.dart';
import 'visual_placeholder.dart';

/// HTTP headers for gallery image requests (Supabase CDN, etc.).
const Map<String, String> kGalleryImageRequestHeaders = {
  'Accept': 'image/jpeg,image/png,image/webp,image/*,*/*;q=0.8',
};

/// Max decode dimension for compact cards on web/desktop (Android/iOS skip cache hints).
const int kGalleryCompactDecodeMaxPx = 720;

/// How long to wait before showing the timeout fallback instead of a spinner.
@visibleForTesting
Duration galleryNetworkImageLoadingTimeout = const Duration(seconds: 12);

/// Delay before showing "still loading" hint under the spinner.
@visibleForTesting
Duration galleryNetworkImageSlowLoadHintDelay = const Duration(seconds: 3);

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
    this.onOpenPressed,
  });

  final String url;
  final String? description;
  final int? seriesIndex;
  final bool compact;
  final bool photoshootSeries;
  final BoxFit fit;

  /// When true, decode and load the full remote image (viewer / fullscreen).
  final bool fullQuality;

  /// Called when user taps "Открыть" on timeout/error fallback (e.g. open viewer).
  final VoidCallback? onOpenPressed;

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
      compact: compact,
      fit: fit,
      fullQuality: fullQuality,
      onOpenPressed: onOpenPressed,
    );
  }
}

@visibleForTesting
String galleryImageUrlWithRetry(String url, int retryGeneration) {
  if (retryGeneration <= 0) return url;
  final uri = Uri.tryParse(url);
  if (uri == null) return '$url?retry=$retryGeneration';
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'retry': '$retryGeneration',
        },
      )
      .toString();
}

@visibleForTesting
void logGalleryImageLoadError(String url, Object error) {
  final uri = Uri.tryParse(url);
  final host = uri?.host ?? 'unknown';
  final path = uri?.path ?? '';
  final ext = path.contains('.') ? path.split('.').last.toLowerCase() : 'none';
  final errorType = error.runtimeType.toString();
  debugPrint(
    'Gallery image load failed: urlHost=$host ext=$ext errorType=$errorType',
  );
}

bool _shouldUseDecodeCacheHints({required bool fullQuality}) {
  if (fullQuality) return false;
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

enum _GalleryImageLoadPhase { loading, loaded, error, timeout }

class _GalleryNetworkImage extends StatefulWidget {
  const _GalleryNetworkImage({
    required this.url,
    required this.compact,
    required this.fit,
    required this.fullQuality,
    this.onOpenPressed,
  });

  final String url;
  final bool compact;
  final BoxFit fit;
  final bool fullQuality;
  final VoidCallback? onOpenPressed;

  @override
  State<_GalleryNetworkImage> createState() => _GalleryNetworkImageState();
}

class _GalleryNetworkImageState extends State<_GalleryNetworkImage> {
  _GalleryImageLoadPhase _phase = _GalleryImageLoadPhase.loading;
  int _retryGeneration = 0;
  Timer? _slowLoadTimer;
  Timer? _timeoutTimer;
  bool _showSlowLoadingMessage = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void didUpdateWidget(covariant _GalleryNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _resetForNewUrl();
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _slowLoadTimer?.cancel();
    _slowLoadTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _startTimers() {
    _cancelTimers();
    _slowLoadTimer = Timer(galleryNetworkImageSlowLoadHintDelay, () {
      if (!mounted || _phase != _GalleryImageLoadPhase.loading) return;
      setState(() => _showSlowLoadingMessage = true);
    });
    _timeoutTimer = Timer(galleryNetworkImageLoadingTimeout, () {
      if (!mounted || _phase != _GalleryImageLoadPhase.loading) return;
      setState(() => _phase = _GalleryImageLoadPhase.timeout);
    });
  }

  void _resetForNewUrl() {
    _cancelTimers();
    setState(() {
      _phase = _GalleryImageLoadPhase.loading;
      _retryGeneration = 0;
      _showSlowLoadingMessage = false;
    });
    _startTimers();
  }

  void _onFrameReady() {
    if (_phase == _GalleryImageLoadPhase.loaded) return;
    _cancelTimers();
    if (!mounted) return;
    setState(() {
      _phase = _GalleryImageLoadPhase.loaded;
      _showSlowLoadingMessage = false;
    });
  }

  void _onError(Object error) {
    logGalleryImageLoadError(widget.url, error);
    _cancelTimers();
    if (!mounted) return;
    setState(() {
      _phase = _GalleryImageLoadPhase.error;
      _showSlowLoadingMessage = false;
    });
  }

  void _retry() {
    _cancelTimers();
    setState(() {
      _retryGeneration++;
      _phase = _GalleryImageLoadPhase.loading;
      _showSlowLoadingMessage = false;
    });
    _startTimers();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _GalleryImageLoadPhase.timeout ||
        _phase == _GalleryImageLoadPhase.error) {
      return GalleryImageLoadFailureFallback(
        compact: widget.compact,
        isTimeout: _phase == _GalleryImageLoadPhase.timeout,
        onOpenPressed: widget.onOpenPressed,
        onRetryPressed: _retry,
      );
    }

    final displayUrl = galleryImageDisplayUrl(widget.url);
    final effectiveUrl =
        galleryImageUrlWithRetry(displayUrl, _retryGeneration);

    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeSize = _decodeCacheSize(
          context: context,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          fullQuality: widget.fullQuality,
        );

        return Image.network(
          effectiveUrl,
          key: ValueKey<String>('gallery-img-$_retryGeneration-$effectiveUrl'),
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          headers: kGalleryImageRequestHeaders,
          cacheWidth: decodeSize?.width,
          cacheHeight: decodeSize?.height,
          filterQuality:
              widget.fullQuality ? FilterQuality.high : FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onFrameReady();
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
              _onError(error);
            });
            return GalleryImageLoadFailureFallback(
              compact: widget.compact,
              isTimeout: false,
              onOpenPressed: widget.onOpenPressed,
              onRetryPressed: _retry,
            );
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
  required double width,
  required double height,
  required bool fullQuality,
}) {
  if (!_shouldUseDecodeCacheHints(fullQuality: fullQuality)) {
    return null;
  }

  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return null;
  }

  final ratio = MediaQuery.devicePixelRatioOf(context);
  final w = (width * ratio).round().clamp(1, kGalleryCompactDecodeMaxPx);
  final h = (height * ratio).round().clamp(1, kGalleryCompactDecodeMaxPx);
  return _DecodeCacheSize(width: w, height: h);
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

/// Fallback when load times out or [Image.network] reports an error.
class GalleryImageLoadFailureFallback extends StatelessWidget {
  const GalleryImageLoadFailureFallback({
    super.key,
    required this.compact,
    required this.isTimeout,
    this.onOpenPressed,
    this.onRetryPressed,
  });

  final bool compact;
  final bool isTimeout;
  final VoidCallback? onOpenPressed;
  final VoidCallback? onRetryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isTimeout
        ? 'Фото сохранено, но не загрузилось'
        : 'Не удалось загрузить фото';

    return Container(
      color: const Color(0xFFF0F2F8),
      alignment: Alignment.center,
      padding: EdgeInsets.all(compact ? 10 : 16),
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
            title,
            textAlign: TextAlign.center,
            maxLines: compact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 12 : 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (onOpenPressed != null)
                TextButton(
                  onPressed: onOpenPressed,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 12,
                      vertical: compact ? 4 : 8,
                    ),
                  ),
                  child: Text(compact ? 'Открыть' : 'Открыть фото'),
                ),
              if (onRetryPressed != null)
                TextButton(
                  onPressed: onRetryPressed,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 12,
                      vertical: compact ? 4 : 8,
                    ),
                  ),
                  child: const Text('Повторить'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Error fallback when a gallery image cannot be loaded (legacy alias).
class GalleryImageErrorPlaceholder extends StatelessWidget {
  const GalleryImageErrorPlaceholder({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GalleryImageLoadFailureFallback(
      compact: compact,
      isTimeout: false,
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
