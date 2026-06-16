import 'package:flutter/material.dart';

bool isHttpPreviewUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return false;
  }
  final lower = url.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// Shows a bundled [Image.asset] or remote [Image.network] preview.
///
/// Network URL takes priority when it starts with http(s). On network failure
/// the widget falls back to [assetPath], then to [placeholder].
class PreviewAssetImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final content = _buildImage();

    Widget sized = content;
    if (height != null || width != null) {
      sized = SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: content,
      );
    }

    if (borderRadius == BorderRadius.zero) {
      return sized;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: sized,
    );
  }

  Widget _buildImage() {
    if (isHttpPreviewUrl(networkUrl)) {
      return Image.network(
        networkUrl!.trim(),
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildAssetImage(),
      );
    }
    return _buildAssetImage();
  }

  Widget _buildAssetImage() {
    final path = assetPath?.trim();
    if (path == null || path.isEmpty) {
      return placeholder;
    }

    return Image.asset(
      path,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
