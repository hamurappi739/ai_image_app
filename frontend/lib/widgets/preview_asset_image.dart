import 'package:flutter/material.dart';

/// Shows a bundled [Image.asset] when the file exists; otherwise [placeholder].
///
/// Paths are declared in pubspec under `assets/previews/` and `assets/guides/`.
/// Missing files are handled via [errorBuilder] — the app does not crash.
class PreviewAssetImage extends StatelessWidget {
  const PreviewAssetImage({
    super.key,
    this.assetPath,
    required this.placeholder,
    this.height,
    this.width,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
  });

  final String? assetPath;
  final Widget placeholder;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = assetPath?.trim();
    final Widget content;
    if (path == null || path.isEmpty) {
      content = placeholder;
    } else {
      content = Image.asset(
        path,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

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
}
