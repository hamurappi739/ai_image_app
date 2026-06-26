import 'package:flutter/material.dart';

import '../utils/mock_image_url.dart';
import 'gallery_result_image.dart';

const _accentColor = Color(0xFF5B6CFF);

/// Photoshoot card thumbnail: one real network frame + lightweight placeholders.
class GalleryPhotoshootTripletPreview extends StatelessWidget {
  const GalleryPhotoshootTripletPreview({
    super.key,
    required this.imageUrls,
    required this.description,
  });

  final List<String> imageUrls;
  final String description;

  static const previewAspectRatio = 16 / 9;

  List<String> get _normalizedUrls {
    if (imageUrls.isEmpty) {
      return const ['', '', ''];
    }
    if (imageUrls.length >= 3) {
      return imageUrls.take(3).toList();
    }
    final last = imageUrls.last;
    return [
      ...imageUrls,
      for (var i = imageUrls.length; i < 3; i++) last,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final urls = _normalizedUrls;
    final allMock = urls.isNotEmpty &&
        urls.every((url) => url.isEmpty || isMockPlaceholderImageUrl(url));

    return AspectRatio(
      aspectRatio: previewAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: allMock
            ? GalleryPhotoshootSeriesPreview(
                imageUrls: urls.where((u) => u.isNotEmpty).toList(),
                description: description,
              )
            : Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: i == 0
                            ? GalleryResultImage(
                                url: urls[i],
                                description: description,
                                seriesIndex: i,
                                compact: true,
                                photoshootSeries: true,
                              )
                            : GalleryDeferredSeriesFrame(index: i),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Lightweight stand-in for frames 2–3 in gallery list cards.
class GalleryDeferredSeriesFrame extends StatelessWidget {
  const GalleryDeferredSeriesFrame({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2F8),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.photo_library_outlined,
              size: 24,
              color: _accentColor.withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
