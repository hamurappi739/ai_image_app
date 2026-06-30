import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'gallery_download_mobile.dart' as mobile;
import 'gallery_download_stub.dart' as stub;

Future<bool> downloadGalleryImage(
  BuildContext context,
  String imageUrl, {
  String? suggestedFileName,
}) {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return mobile.downloadGalleryImage(
      context,
      imageUrl,
      suggestedFileName: suggestedFileName,
    );
  }
  return stub.downloadGalleryImage(
    context,
    imageUrl,
    suggestedFileName: suggestedFileName,
  );
}
