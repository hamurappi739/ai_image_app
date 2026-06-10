// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/material.dart';

Future<void> downloadGalleryImage(
  BuildContext context,
  String imageUrl, {
  String? suggestedFileName,
}) async {
  final fileName = suggestedFileName ?? 'image';
  try {
    final anchor = html.AnchorElement(href: imageUrl)
      ..download = fileName
      ..target = '_blank'
      ..rel = 'noopener';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {
    html.window.open(imageUrl, '_blank');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Фото открыто в новой вкладке.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
