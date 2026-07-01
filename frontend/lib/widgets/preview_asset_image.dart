import 'package:flutter/material.dart';

bool isHttpPreviewUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return false;
  }
  final lower = url.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

const _previewDecodeMaxPx = 900;

@visibleForTesting
int previewAssetDecodeCachePx(double layoutPx, double devicePixelRatio) {
  if (!layoutPx.isFinite || layoutPx <= 0) {
    return _previewDecodeMaxPx;
  }
  final scaled = (layoutPx * devicePixelRatio).round();
  if (scaled <= 0) {
    return _previewDecodeMaxPx;
  }
  return scaled > _previewDecodeMaxPx ? _previewDecodeMaxPx : scaled;
}

/// Shows a bundled [Image.asset] under an optional remote [Image.network] preview.
///
/// When both asset and network URLs are present, the asset is shown immediately
/// while the network image loads and fades in on the first decoded frame.
/// Network failures keep the asset visible instead of an empty block.
class PreviewAssetImage extends StatefulWidget {
  const PreviewAssetImage({
    super.key,
    this.assetPath,
    this.networkUrl,
    required this.placeholder,
    this.height,
    this.width,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
  });

  final String? assetPath;
  final String? networkUrl;
  final Widget placeholder;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  State<PreviewAssetImage> createState() => _PreviewAssetImageState();
}

class _PreviewAssetImageState extends State<PreviewAssetImage> {
  bool _networkLoaded = false;
  bool _networkFailed = false;

  @override
  void didUpdateWidget(covariant PreviewAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkUrl != widget.networkUrl ||
        oldWidget.assetPath != widget.assetPath) {
      _networkLoaded = false;
      _networkFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = previewAssetDecodeCachePx(
          constraints.maxWidth,
          dpr,
        );
        final cacheHeight = previewAssetDecodeCachePx(
          constraints.maxHeight,
          dpr,
        );

        final asset = _buildAssetImage(cacheWidth: cacheWidth, cacheHeight: cacheHeight);
        final network = _buildNetworkLayer(
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        );

        if (network == null) {
          return asset;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            asset,
            AnimatedOpacity(
              opacity: _networkLoaded && !_networkFailed ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: network,
            ),
          ],
        );
      },
    );

    if (widget.height != null || widget.width != null) {
      content = SizedBox(
        height: widget.height,
        width: widget.width ?? double.infinity,
        child: content,
      );
    }

    if (widget.borderRadius == BorderRadius.zero) {
      return content;
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: content,
    );
  }

  Widget? _buildNetworkLayer({
    required int cacheWidth,
    required int cacheHeight,
  }) {
    if (_networkFailed || !isHttpPreviewUrl(widget.networkUrl)) {
      return null;
    }

    return Image.network(
      widget.networkUrl!.trim(),
      fit: widget.fit,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          if (!_networkLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _networkLoaded = true);
            });
          }
          return child;
        }
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _networkFailed = true;
            _networkLoaded = false;
          });
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAssetImage({
    required int cacheWidth,
    required int cacheHeight,
  }) {
    final path = widget.assetPath?.trim();
    if (path == null || path.isEmpty) {
      return widget.placeholder;
    }

    return Image.asset(
      path,
      fit: widget.fit,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (context, error, stackTrace) => widget.placeholder,
    );
  }
}
