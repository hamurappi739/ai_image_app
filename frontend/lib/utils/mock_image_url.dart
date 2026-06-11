import 'package:flutter/material.dart';

import '../widgets/visual_placeholder.dart';

/// Demo/mock placeholder hosts returned by backend mock providers.
bool isMockPlaceholderImageUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final host = uri.host.toLowerCase();
  return host == 'placehold.co' || host.endsWith('.placehold.co');
}

int mockPreviewSeed(
  String url, {
  String? description,
  int? seriesIndex,
}) {
  var hash = 0;
  for (final part in [url, description ?? '', '${seriesIndex ?? ''}']) {
    for (var i = 0; i < part.length; i++) {
      hash = 0x1fffffff & (hash + part.codeUnitAt(i));
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= hash >> 11;
  hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  return hash.abs();
}

VisualPlaceholderMood galleryPreviewMood({
  required int seed,
  bool photoshoot = false,
}) {
  if (photoshoot) {
    const moods = [
      VisualPlaceholderMood.photoshoot,
      VisualPlaceholderMood.premium,
      VisualPlaceholderMood.portrait,
      VisualPlaceholderMood.business,
    ];
    return moods[seed % moods.length];
  }

  const moods = [
    VisualPlaceholderMood.portrait,
    VisualPlaceholderMood.social,
    VisualPlaceholderMood.business,
    VisualPlaceholderMood.summer,
    VisualPlaceholderMood.premium,
    VisualPlaceholderMood.family,
  ];
  return moods[seed % moods.length];
}

String gallerySinglePreviewCaption({
  required int seed,
  String? description,
}) {
  const defaults = ['Фото готово', 'Портрет', 'Образ'];
  final text = description?.trim();
  if (text != null && text.isNotEmpty && seed % 4 == 0) {
    if (text.length <= 24) return text;
    return '${text.substring(0, 21).trim()}…';
  }
  return defaults[seed % defaults.length];
}

String galleryPhotoshootFrameCaption(int seriesIndex) {
  return 'Фото ${seriesIndex + 1}';
}

List<Color>? galleryPreviewGradient(int seed) {
  const palettes = [
    [Color(0xFFEDE9FF), Color(0xFF7C8CFF)],
    [Color(0xFFE8F4FF), Color(0xFF4A7CFF)],
    [Color(0xFFF0FDF4), Color(0xFF6EE7B7)],
    [Color(0xFFFFF7ED), Color(0xFFFDBA74)],
    [Color(0xFFFDF2F8), Color(0xFFF9A8D4)],
    [Color(0xFFF0F9FF), Color(0xFF7DD3FC)],
  ];
  return palettes[seed % palettes.length];
}
