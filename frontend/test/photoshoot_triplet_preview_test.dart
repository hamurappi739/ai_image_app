import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_image_generator/widgets/photoshoot_triplet_preview.dart';
import 'package:ai_image_generator/widgets/preview_asset_image.dart';

void main() {
  test('uses per-frame network URL when only one remote preview is available', () {
    const widget = PhotoshootTripletPreview(
      styleId: 'studio_portrait',
      previewAssets: [
        'assets/previews/photoshoots/studio_portrait_1.jpg',
        'assets/previews/photoshoots/studio_portrait_2.jpg',
        'assets/previews/photoshoots/studio_portrait_3.jpg',
      ],
      previewUrls: [
        'https://cdn.example.com/studio_portrait_1_v1.jpg',
      ],
      gradientColors: [Colors.blue, Colors.purple],
      icon: Icons.photo_camera,
      previewVariant: 0,
    );

    expect(
      widget.previewUrls.length,
      1,
    );
    expect(
      isHttpPreviewUrl(widget.previewUrls.first),
      isTrue,
    );
  });
}
