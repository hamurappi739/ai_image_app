import 'package:flutter/material.dart';

Future<void> downloadGalleryImage(
  BuildContext context,
  String imageUrl, {
  String? suggestedFileName,
}) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Скачивание недоступно на этой платформе. '
        'Откройте изображение и сохраните его вручную.',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
