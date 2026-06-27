import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'gallery_download_common.dart';

const _galleryImageAcceptHeader = 'image/jpeg,image/png,image/webp,image/*,*/*;q=0.8';

Future<void> downloadGalleryImage(
  BuildContext context,
  String imageUrl, {
  String? suggestedFileName,
}) async {
  final trimmedUrl = imageUrl.trim();
  if (trimmedUrl.isEmpty) {
    _showGalleryDownloadSnackBar(context, galleryDownloadFailureMessage);
    return;
  }

  try {
    final response = await http.get(
      Uri.parse(trimmedUrl),
      headers: const {'Accept': _galleryImageAcceptHeader},
    );
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw StateError('Empty image payload');
    }

    final extension = resolveGalleryDownloadExtension(
      imageUrl: trimmedUrl,
      contentType: response.headers['content-type'],
    );
    final fileName = suggestedFileName?.trim().isNotEmpty == true
        ? '${suggestedFileName!.trim()}.$extension'
        : buildGalleryDownloadFileName(extension: extension);

    final tempFile = File('${Directory.systemTemp.path}/$fileName');
    await tempFile.writeAsBytes(bytes, flush: true);

    try {
      final result = await ImageGallerySaverPlus.saveFile(
        tempFile.path,
        name: fileName,
        isReturnPathOfIOS: true,
      );
      if (!isGalleryDownloadSaveSuccess(result)) {
        throw StateError('Gallery save rejected');
      }
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }

    if (!context.mounted) return;
    _showGalleryDownloadSnackBar(context, galleryDownloadSuccessMessage);
  } catch (_) {
    if (!context.mounted) return;
    _showGalleryDownloadSnackBar(context, galleryDownloadFailureMessage);
  }
}

void _showGalleryDownloadSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
