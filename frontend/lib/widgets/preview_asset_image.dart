import 'package:flutter/material.dart';

import '../assets/preview_asset_registry.dart';

/// Shows a local [Image.asset] when the path is registered; otherwise [placeholder].
///
/// Does not call [Image.asset] for missing or unregistered paths — no console
/// errors from absent files during development.
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
    if (!PreviewAssetRegistry.isAvailable(assetPath)) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: Image.asset(
          assetPath!,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }
}
