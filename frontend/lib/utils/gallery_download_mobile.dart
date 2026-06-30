import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'gallery_download_common.dart';

const _galleryImageAcceptHeader = 'image/jpeg,image/png,image/webp,image/*,*/*;q=0.8';

Future<bool> downloadGalleryImage(
  BuildContext context,
  String imageUrl, {
  String? suggestedFileName,
}) async {
  final downloadUrl = resolveGalleryDownloadUrl(imageUrl);
  if (downloadUrl.isEmpty) {
    _showGalleryDownloadSnackBar(context, galleryDownloadFailureMessage);
    return false;
  }

  try {
    final response = await http.get(
      Uri.parse(downloadUrl),
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
      imageUrl: downloadUrl,
      contentType: response.headers['content-type'],
    );
    final fileName = suggestedFileName?.trim().isNotEmpty == true
        ? '${suggestedFileName!.trim()}.$extension'
        : buildGalleryDownloadFileName(extension: extension);

    final result = await ImageGallerySaverPlus.saveImage(
      bytes,
      name: fileName,
      quality: 100,
    );
    if (!isGalleryDownloadSaveSuccess(result)) {
      throw StateError('Gallery save rejected');
    }

    if (kDebugMode) {
      final host = Uri.tryParse(downloadUrl)?.host ?? 'unknown';
      debugPrint('Gallery download saved: host=$host bytes=${bytes.length}');
    }

    if (!context.mounted) return true;
    _showGalleryDownloadSnackBar(context, galleryDownloadSuccessMessage);
    return true;
  } catch (error) {
    if (kDebugMode) {
      final host = Uri.tryParse(downloadUrl)?.host ?? 'unknown';
      debugPrint(
        'Gallery download failed: host=$host errorType=${error.runtimeType}',
      );
    }
    if (!context.mounted) return false;
    _showGalleryDownloadSnackBar(context, galleryDownloadFailureMessage);
    return false;
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
