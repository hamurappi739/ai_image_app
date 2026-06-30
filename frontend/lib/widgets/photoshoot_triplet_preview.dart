import 'package:flutter/material.dart';

import '../assets/preview_asset_paths.dart';
import 'preview_asset_image.dart';
import 'visual_placeholder.dart';

/// Three square 1:1 previews in a row for photoshoot catalog cards.
class PhotoshootTripletPreview extends StatelessWidget {
  const PhotoshootTripletPreview({
    super.key,
    required this.styleId,
    required this.previewAssets,
    this.previewUrls = const [],
    required this.gradientColors,
    required this.icon,
    required this.previewVariant,
    this.spacing = 4,
    this.outerRadius = 12,
    this.innerRadius = 8,
  });

  final String styleId;
  final List<String> previewAssets;
  final List<String> previewUrls;
  final List<Color> gradientColors;
  final IconData icon;
  final int previewVariant;
  final double spacing;
  final double outerRadius;
  final double innerRadius;

  String? _networkUrlForIndex(int index) {
    if (index < 0 || index >= previewUrls.length) {
      return null;
    }
    final url = previewUrls[index];
    return isHttpPreviewUrl(url) ? url.trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    final mood = VisualPlaceholderPalette.moodForPhotoshootId(styleId);
    final assets = previewAssets.length >= 3
        ? previewAssets
        : PreviewAssetPaths.photoshootPreviewAssetsForId(styleId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(outerRadius),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final assetPath = i < assets.length ? assets[i] : null;
                    final networkUrl = _networkUrlForIndex(i);
                    return PreviewAssetImage(
                      assetPath: assetPath,
                      networkUrl: networkUrl,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(innerRadius),
                      placeholder: VisualPlaceholder(
                        mood: mood,
                        gradientColors: gradientColors,
                        icon: icon,
                        variant: previewVariant + i,
                        height: constraints.maxHeight,
                        compact: true,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
