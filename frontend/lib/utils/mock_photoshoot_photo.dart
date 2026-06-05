import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Минимальное PNG для multipart-запроса фотосессии на эмуляторе (без галереи).
class MockPhotoshootPhoto {
  MockPhotoshootPhoto._();

  static const _pngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  static final Uint8List bytes = base64Decode(_pngBase64);

  /// Автовыбор тестового фото в debug-сборке на Android (эмулятор).
  static bool get shouldAutoUseOnPlatform =>
      kDebugMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  static XFile asXFile() {
    return XFile.fromData(
      bytes,
      name: 'demo-photoshoot.png',
      mimeType: 'image/png',
    );
  }
}
