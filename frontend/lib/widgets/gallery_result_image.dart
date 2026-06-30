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

/// How long to wait before treating a load attempt as timed out.
@visibleForTesting
Duration galleryNetworkImageLoadingTimeout = const Duration(seconds: 22);

/// Delay before showing "still loading" hint under the spinner.
@visibleForTesting
Duration galleryNetworkImageSlowLoadHintDelay = const Duration(seconds: 3);

/// Automatic retries after the first load error/timeout (before manual retry).
@visibleForTesting
int galleryNetworkImageMaxAutoRetries = 2;

/// Delays before each automatic retry attempt.
@visibleForTesting
List<Duration> galleryNetworkImageAutoRetryDelays = const [
  Duration(milliseconds: 800),
  Duration(milliseconds: 1800),
];

/// Stagger gallery list image loads to avoid burst requests on open.
@visibleForTesting
Duration galleryImageLoadStaggerDelay(int? index) {
  if (index == null || index <= 0) {
    return Duration.zero;
  }
  const step = Duration(milliseconds: 120);
  const maxDelay = Duration(milliseconds: 1800);
  final delay = step * index;
  return delay > maxDelay ? maxDelay : delay;
}

@visibleForTesting
bool galleryImageShouldShowFallback({
  required int autoRetryCount,
  int maxAutoRetries = 2,
}) {
  return autoRetryCount >= maxAutoRetries;
}

@visibleForTesting
Duration? galleryImageAutoRetryDelayForAttempt(int autoRetryCount) {
  if (autoRetryCount < 0 || autoRetryCount >= galleryNetworkImageAutoRetryDelays.length) {
    return null;
  }
  return galleryNetworkImageAutoRetryDelays[autoRetryCount];
}

/// How error/timeout fallback is rendered inside [GalleryResultImage].
enum GalleryImageFallbackMode {
  /// Full message and action buttons (gallery cards, viewer).
  standard,

  /// Minimal icon + short label for small thumbnails (no retry / open).
  thumbnail,
}

/// Gallery / viewer image: real URL via network; mock/demo via rich Flutter preview.
class GalleryResultImage extends StatelessWidget {
  const GalleryResultImage({
    super.key,
    required this.url,
    this.description,
    this.seriesIndex,
    this.compact = false,
    this.fallbackMode = GalleryImageFallbackMode.standard,
    this.photoshootSeries = false,
    this.fit = BoxFit.cover,
    this.fullQuality = false,
    this.onOpenPressed,
    this.loadStaggerIndex,
  });

  final String url;
  final String? description;
  final int? seriesIndex;
  final bool compact;
  final GalleryImageFallbackMode fallbackMode;
  final bool photoshootSeries;
  final BoxFit fit;

  /// When true, decode and load the full remote image (viewer / fullscreen).
  final bool fullQuality;

  /// Called when user taps "Открыть" on timeout/error fallback (e.g. open viewer).
  final VoidCallback? onOpenPressed;

  /// Optional list index for staggered gallery loading (ignored when [fullQuality]).
  final int? loadStaggerIndex;

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
      fallbackMode: fallbackMode,
      fit: fit,
      fullQuality: fullQuality,
      onOpenPressed: onOpenPressed,
      loadStaggerIndex: fullQuality ? null : loadStaggerIndex,
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
    required this.fallbackMode,
    required this.fit,
    required this.fullQuality,
    this.onOpenPressed,
    this.loadStaggerIndex,
  });

  final String url;
  final bool compact;
  final GalleryImageFallbackMode fallbackMode;
  final BoxFit fit;
  final bool fullQuality;
  final VoidCallback? onOpenPressed;
  final int? loadStaggerIndex;

  bool get _thumbnailFallback =>
      fallbackMode == GalleryImageFallbackMode.thumbnail;

  @override
  State<_GalleryNetworkImage> createState() => _GalleryNetworkImageState();
}

class _GalleryNetworkImageState extends State<_GalleryNetworkImage> {
  _GalleryImageLoadPhase _phase = _GalleryImageLoadPhase.loading;
  int _retryGeneration = 0;
  int _autoRetryCount = 0;
  bool _loadTimedOut = false;
  bool _staggerReady = false;
  Timer? _slowLoadTimer;
  Timer? _timeoutTimer;
  Timer? _autoRetryTimer;
  Timer? _staggerTimer;
  bool _showSlowLoadingMessage = false;

  @override
  void initState() {
    super.initState();
    _beginLoadCycle(resetAutoRetries: true);
  }

  @override
  void didUpdateWidget(covariant _GalleryNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.loadStaggerIndex != widget.loadStaggerIndex) {
      _beginLoadCycle(resetAutoRetries: true);
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
    _autoRetryTimer?.cancel();
    _autoRetryTimer = null;
    _staggerTimer?.cancel();
    _staggerTimer = null;
  }

  void _beginLoadCycle({required bool resetAutoRetries}) {
    _cancelTimers();
    setState(() {
      _phase = _GalleryImageLoadPhase.loading;
      if (resetAutoRetries) {
        _retryGeneration = 0;
        _autoRetryCount = 0;
      }
      _loadTimedOut = false;
      _showSlowLoadingMessage = false;
      _staggerReady = false;
    });
    _scheduleStaggerIfNeeded();
  }

  void _scheduleStaggerIfNeeded() {
    final delay = galleryImageLoadStaggerDelay(widget.loadStaggerIndex);
    if (delay <= Duration.zero) {
      if (!_staggerReady) {
        setState(() => _staggerReady = true);
      }
      _startAttemptTimers();
      return;
    }

    _staggerTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _staggerReady = true);
      _startAttemptTimers();
    });
  }

  void _startAttemptTimers() {
    _cancelTimers();
    _slowLoadTimer = Timer(galleryNetworkImageSlowLoadHintDelay, () {
      if (!mounted || _phase != _GalleryImageLoadPhase.loading) return;
      setState(() => _showSlowLoadingMessage = true);
    });
    _timeoutTimer = Timer(galleryNetworkImageLoadingTimeout, () {
      if (!mounted || _phase != _GalleryImageLoadPhase.loading) return;
      _handleLoadFailure(isTimeout: true);
    });
  }

  void _onFrameReady() {
    if (_phase == _GalleryImageLoadPhase.loaded) return;
    _cancelTimers();
    if (!mounted) return;
    setState(() {
      _phase = _GalleryImageLoadPhase.loaded;
      _showSlowLoadingMessage = false;
      _loadTimedOut = false;
    });
  }

  void _handleLoadFailure({required bool isTimeout}) {
    if (!mounted || _phase != _GalleryImageLoadPhase.loading) return;

    if (_autoRetryCount < galleryNetworkImageMaxAutoRetries) {
      final delay = galleryImageAutoRetryDelayForAttempt(_autoRetryCount);
      if (delay == null) {
        _showFinalFailure(isTimeout: isTimeout);
        return;
      }

      _autoRetryCount++;
      _retryGeneration++;
      _cancelTimers();
      _autoRetryTimer = Timer(delay, () {
        if (!mounted) return;
        setState(() {
          _phase = _GalleryImageLoadPhase.loading;
          _showSlowLoadingMessage = false;
          _loadTimedOut = false;
        });
        _startAttemptTimers();
      });
      return;
    }

    _showFinalFailure(isTimeout: isTimeout);
  }

  void _showFinalFailure({required bool isTimeout}) {
    _cancelTimers();
    if (!mounted) return;
    setState(() {
      _phase = isTimeout
          ? _GalleryImageLoadPhase.timeout
          : _GalleryImageLoadPhase.error;
      _loadTimedOut = isTimeout;
      _showSlowLoadingMessage = false;
    });
  }

  void _retry() {
    _cancelTimers();
    setState(() {
      _retryGeneration++;
      _autoRetryCount = 0;
      _phase = _GalleryImageLoadPhase.loading;
      _loadTimedOut = false;
      _showSlowLoadingMessage = false;
      _staggerReady = true;
    });
    _startAttemptTimers();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _GalleryImageLoadPhase.timeout ||
        _phase == _GalleryImageLoadPhase.error) {
      return GalleryImageLoadFailureFallback(
        compact: widget.compact,
        fallbackMode: widget.fallbackMode,
        isTimeout: _loadTimedOut,
        onOpenPressed:
            widget._thumbnailFallback ? null : widget.onOpenPressed,
        onRetryPressed: widget._thumbnailFallback ? null : _retry,
      );
    }

    if (!_staggerReady) {
      return GalleryImageLoadingPlaceholder(
        compact: widget.compact,
        fallbackMode: widget.fallbackMode,
        showSlowMessage: false,
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
              fallbackMode: widget.fallbackMode,
              showSlowMessage:
                  !widget._thumbnailFallback && _showSlowLoadingMessage,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            logGalleryImageLoadError(widget.url, error);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleLoadFailure(isTimeout: false);
            });
            return GalleryImageLoadingPlaceholder(
              compact: widget.compact,
              fallbackMode: widget.fallbackMode,
              showSlowMessage: false,
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
    this.fallbackMode = GalleryImageFallbackMode.standard,
    this.showSlowMessage = false,
  });

  final bool compact;
  final GalleryImageFallbackMode fallbackMode;
  final bool showSlowMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail =
        fallbackMode == GalleryImageFallbackMode.thumbnail;

    return Container(
      color: const Color(0xFFF0F2F8),
      alignment: Alignment.center,
      padding: EdgeInsets.all(thumbnail ? 4 : (compact ? 12 : 16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: thumbnail ? 18 : (compact ? 22 : 28),
            height: thumbnail ? 18 : (compact ? 22 : 28),
            child: CircularProgressIndicator(
              strokeWidth: thumbnail ? 2 : 2.5,
            ),
          ),
          if (showSlowMessage && !thumbnail) ...[
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
    this.fallbackMode = GalleryImageFallbackMode.standard,
    required this.isTimeout,
    this.onOpenPressed,
    this.onRetryPressed,
  });

  final bool compact;
  final GalleryImageFallbackMode fallbackMode;
  final bool isTimeout;
  final VoidCallback? onOpenPressed;
  final VoidCallback? onRetryPressed;

  @override
  Widget build(BuildContext context) {
    if (fallbackMode == GalleryImageFallbackMode.thumbnail) {
      return _ThumbnailFailureFallback(compact: compact);
    }

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

class _ThumbnailFailureFallback extends StatelessWidget {
  const _ThumbnailFailureFallback({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFFF0F2F8),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: compact ? 20 : 22,
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 2),
            Text(
              'Не загрузилось',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                height: 1.1,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
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
