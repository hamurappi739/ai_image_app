import 'dart:convert';

import 'package:ai_image_generator/models/generated_image_item.dart';
import 'package:ai_image_generator/models/user_balance.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class InsufficientImagesException implements Exception {
  const InsufficientImagesException();
}

class InsufficientPhotoshootsException implements Exception {
  const InsufficientPhotoshootsException();
}

class PhotoGenerationInvalidPhotoException implements Exception {
  const PhotoGenerationInvalidPhotoException();
}

class PhotoGenerationDescriptionException implements Exception {
  const PhotoGenerationDescriptionException();
}

class GenerateImageResponse {
  const GenerateImageResponse({
    required this.imageUrl,
    required this.prompt,
    this.paymentType,
    this.creditConsumed = false,
    this.remainingFreeGenerations,
    this.remainingPaidCredits,
    this.balance,
  });

  final String imageUrl;
  final String prompt;
  final String? paymentType;
  final bool creditConsumed;
  final int? remainingFreeGenerations;
  final int? remainingPaidCredits;
  final UserBalance? balance;

  factory GenerateImageResponse.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'];
    return GenerateImageResponse(
      imageUrl: json['image_url'] as String,
      prompt: json['prompt'] as String,
      paymentType: json['payment_type'] as String?,
      creditConsumed: json['credit_consumed'] as bool? ?? false,
      remainingFreeGenerations: json['remaining_free_generations'] as int?,
      remainingPaidCredits: json['remaining_paid_credits'] as int?,
      balance: rawBalance is Map<String, dynamic>
          ? UserBalance.fromJson(rawBalance)
          : null,
    );
  }
}

class GenerationHistoryItem {
  const GenerationHistoryItem({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    required this.paymentType,
    required this.createdAt,
    this.photoshootId,
  });

  final String id;
  final String prompt;
  final String imageUrl;
  final String paymentType;
  final DateTime createdAt;
  final String? photoshootId;

  factory GenerationHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawPhotoshootId = json['photoshoot_id'];
    return GenerationHistoryItem(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      imageUrl: json['image_url'] as String,
      paymentType: json['payment_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      photoshootId: rawPhotoshootId is String ? rawPhotoshootId : null,
    );
  }

  GeneratedImageItem toGalleryItem() {
    return GeneratedImageItem(
      id: id,
      description: prompt,
      imageUrl: imageUrl,
      createdAt: createdAt,
      photoshootId: photoshootId,
    );
  }
}

class MockPaymentUnavailableException implements Exception {
  const MockPaymentUnavailableException();
}

class MockPaymentFailedException implements Exception {
  const MockPaymentFailedException();
}

class MockPaymentServiceUnavailableException implements Exception {
  const MockPaymentServiceUnavailableException();
}

class MockPaymentAddedBalance {
  const MockPaymentAddedBalance({
    required this.paidImageGenerations,
    required this.paidPhotoshoots,
  });

  final int paidImageGenerations;
  final int paidPhotoshoots;

  factory MockPaymentAddedBalance.fromJson(Map<String, dynamic> json) {
    return MockPaymentAddedBalance(
      paidImageGenerations: json['paid_image_generations'] as int? ?? 0,
      paidPhotoshoots: json['paid_photoshoots'] as int? ?? 0,
    );
  }
}

class MockVerifyRuStorePaymentResponse {
  const MockVerifyRuStorePaymentResponse({
    required this.status,
    required this.packageId,
    required this.added,
    this.balance,
  });

  final String status;
  final String packageId;
  final MockPaymentAddedBalance added;
  final UserBalance? balance;

  factory MockVerifyRuStorePaymentResponse.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'];
    final rawAdded = json['added'];
    return MockVerifyRuStorePaymentResponse(
      status: json['status'] as String? ?? '',
      packageId: json['package_id'] as String? ?? '',
      added: rawAdded is Map<String, dynamic>
          ? MockPaymentAddedBalance.fromJson(rawAdded)
          : const MockPaymentAddedBalance(
              paidImageGenerations: 0,
              paidPhotoshoots: 0,
            ),
      balance: rawBalance is Map<String, dynamic>
          ? UserBalance.fromJson(rawBalance)
          : null,
    );
  }
}

class MockVerifyCustomAmountPaymentResponse {
  const MockVerifyCustomAmountPaymentResponse({
    required this.status,
    required this.packageId,
    required this.amountRub,
    required this.added,
    required this.unusedRub,
    this.balance,
  });

  final String status;
  final String packageId;
  final int amountRub;
  final MockPaymentAddedBalance added;
  final int unusedRub;
  final UserBalance? balance;

  factory MockVerifyCustomAmountPaymentResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawBalance = json['balance'];
    final rawAdded = json['added'];
    return MockVerifyCustomAmountPaymentResponse(
      status: json['status'] as String? ?? '',
      packageId: json['package_id'] as String? ?? '',
      amountRub: json['amount_rub'] as int? ?? 0,
      added: rawAdded is Map<String, dynamic>
          ? MockPaymentAddedBalance.fromJson(rawAdded)
          : const MockPaymentAddedBalance(
              paidImageGenerations: 0,
              paidPhotoshoots: 0,
            ),
      unusedRub: json['unused_rub'] as int? ?? 0,
      balance: rawBalance is Map<String, dynamic>
          ? UserBalance.fromJson(rawBalance)
          : null,
    );
  }
}

class PhotoshootPlaceholderException implements Exception {
  const PhotoshootPlaceholderException();
}

class PhotoshootInvalidPhotoException implements Exception {
  const PhotoshootInvalidPhotoException();
}

class PhotoshootGenerationFailedException implements Exception {
  const PhotoshootGenerationFailedException();
}

class PhotoshootGenerateResponse {
  const PhotoshootGenerateResponse({
    required this.styleId,
    required this.styleTitle,
    required this.imageUrls,
    required this.outputCount,
    required this.photoshootId,
    this.balance,
    this.description,
  });

  final String styleId;
  final String styleTitle;
  final List<String> imageUrls;
  final int outputCount;
  final String photoshootId;
  final UserBalance? balance;
  final String? description;

  factory PhotoshootGenerateResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    if (status != null && status != 'success') {
      throw const PhotoshootGenerationFailedException();
    }
    final rawUrls = (json['images'] as List<dynamic>?)
            ?.map((url) => url as String)
            .toList() ??
        (json['image_urls'] as List<dynamic>?)
            ?.map((url) => url as String)
            .toList() ??
        <String>[];
    final outputCount = json['output_count'] as int? ?? rawUrls.length;
    if (outputCount <= 0 || rawUrls.length < outputCount) {
      throw const PhotoshootGenerationFailedException();
    }
    final rawBalance = json['balance'];
    return PhotoshootGenerateResponse(
      styleId: json['style_id'] as String,
      styleTitle: json['style_title'] as String,
      imageUrls: rawUrls,
      outputCount: outputCount,
      photoshootId: json['photoshoot_id'] as String? ?? '',
      balance: rawBalance is Map<String, dynamic>
          ? UserBalance.fromJson(rawBalance)
          : null,
      description: json['description'] as String?,
    );
  }
}

class PhotoshootJobStartResponse {
  const PhotoshootJobStartResponse({required this.jobId});

  final String jobId;

  factory PhotoshootJobStartResponse.fromJson(Map<String, dynamic> json) {
    return PhotoshootJobStartResponse(jobId: json['job_id'] as String);
  }
}

class PhotoshootJobFrameStatus {
  const PhotoshootJobFrameStatus({required this.index, required this.status});

  final int index;
  final String status;

  factory PhotoshootJobFrameStatus.fromJson(Map<String, dynamic> json) {
    return PhotoshootJobFrameStatus(
      index: json['index'] as int,
      status: json['status'] as String,
    );
  }
}

class PhotoshootJobStatusResponse {
  const PhotoshootJobStatusResponse({
    required this.status,
    required this.message,
    required this.frames,
    required this.images,
    this.photoshootId,
    this.styleId,
    this.styleTitle,
    this.outputCount,
    this.balance,
    this.description,
  });

  final String status;
  final String message;
  final List<PhotoshootJobFrameStatus> frames;
  final List<String> images;
  final String? photoshootId;
  final String? styleId;
  final String? styleTitle;
  final int? outputCount;
  final UserBalance? balance;
  final String? description;

  factory PhotoshootJobStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawFrames = json['frames'] as List<dynamic>? ?? const [];
    final rawImages = (json['images'] as List<dynamic>?)
            ?.map((url) => url as String)
            .toList() ??
        <String>[];
    final rawBalance = json['balance'];
    return PhotoshootJobStatusResponse(
      status: json['status'] as String? ?? 'queued',
      message: json['message'] as String? ?? '',
      frames: rawFrames
          .map(
            (frame) =>
                PhotoshootJobFrameStatus.fromJson(frame as Map<String, dynamic>),
          )
          .toList(),
      images: rawImages,
      photoshootId: json['photoshoot_id'] as String?,
      styleId: json['style_id'] as String?,
      styleTitle: json['style_title'] as String?,
      outputCount: json['output_count'] as int?,
      balance: rawBalance is Map<String, dynamic>
          ? UserBalance.fromJson(rawBalance)
          : null,
      description: json['description'] as String?,
    );
  }

  PhotoshootGenerateResponse toGenerateResponse({
    required String fallbackStyleId,
    required String fallbackStyleTitle,
  }) {
    final resolvedOutputCount = outputCount ?? images.length;
    return PhotoshootGenerateResponse(
      styleId: styleId ?? fallbackStyleId,
      styleTitle: styleTitle ?? fallbackStyleTitle,
      imageUrls: images,
      outputCount: resolvedOutputCount,
      photoshootId: photoshootId ?? '',
      balance: balance,
      description: description,
    );
  }
}

const _hiddenDevDescriptionPatterns = [
  'debug test prompt',
  'debug',
  'test prompt',
];

bool _isHiddenDevGenerationDescription(String description) {
  final lower = description.toLowerCase();
  return _hiddenDevDescriptionPatterns.any((pattern) => lower.contains(pattern));
}

const _apiBaseUrlFromEnvironment = String.fromEnvironment('API_BASE_URL');

const _defaultWebApiBaseUrl = 'http://127.0.0.1:8000';
const _defaultAndroidApiBaseUrl = 'http://10.0.2.2:8000';

class ApiService {
  static bool _baseUrlLogged = false;

  ApiService() {
    if (kDebugMode && !_baseUrlLogged) {
      _baseUrlLogged = true;
      debugPrint('ApiService base URL: $baseUrl');
    }
  }

  String? _accessToken;

  /// Sets optional Supabase (or other) access token for `Authorization: Bearer`.
  /// Pass `null` or empty string to clear. Token is never logged or persisted here.
  void setAccessToken(String? token) {
    final trimmed = token?.trim();
    _accessToken = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Map<String, String> _requestHeaders({bool jsonBody = false}) {
    final headers = <String, String>{};
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Backend API root. Override at build/run time:
  /// `--dart-define=API_BASE_URL=https://your-backend.example.com`
  static String get baseUrl {
    final override = _apiBaseUrlFromEnvironment.trim();
    if (override.isNotEmpty) {
      return _normalizeApiBaseUrl(override);
    }
    if (kIsWeb) {
      return _defaultWebApiBaseUrl;
    }
    return _defaultAndroidApiBaseUrl;
  }

  static String _normalizeApiBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  Future<GenerateImageResponse> generateImage(String prompt) async {
    final uri = Uri.parse('$baseUrl/generate');
    final response = await http.post(
      uri,
      headers: _requestHeaders(jsonBody: true),
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return GenerateImageResponse.fromJson(json);
    }
    if (response.statusCode == 400) {
      throw Exception('Prompt cannot be empty');
    }
    if (response.statusCode == 402) {
      throw const InsufficientImagesException();
    }
    throw Exception('Failed to generate image');
  }

  Future<GenerateImageResponse> generateImageWithPhoto({
    required String description,
    required XFile photoFile,
    String? templateId,
    XFile? petPhotoFile,
    XFile? childPhotoFile,
    String? cakeDigit,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/generate-with-photo'),
    );
    request.headers.addAll(_requestHeaders());
    request.fields['description'] = description;
    if (templateId != null && templateId.trim().isNotEmpty) {
      request.fields['template_id'] = templateId.trim();
    }
    if (cakeDigit != null && cakeDigit.trim().isNotEmpty) {
      request.fields['cake_digit'] = cakeDigit.trim();
    }

    Future<void> attachFile(String fieldName, XFile file) async {
      final fileBytes = await file.readAsBytes();
      final mimeType = _resolveMultipartMimeType(file);
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: _resolveFileName(file),
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    await attachFile('photo', photoFile);
    if (petPhotoFile != null) {
      await attachFile('pet_photo', petPhotoFile);
    }
    if (childPhotoFile != null) {
      await attachFile('child_photo', childPhotoFile);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return GenerateImageResponse.fromJson(json);
    }
    if (response.statusCode == 400) {
      final body = response.body;
      if (body.contains('Description cannot be empty')) {
        throw const PhotoGenerationDescriptionException();
      }
      throw const PhotoGenerationInvalidPhotoException();
    }
    if (response.statusCode == 402) {
      throw const InsufficientImagesException();
    }
    throw Exception('Failed to generate image with photo');
  }

  Future<UserBalance> fetchBalance() async {
    final uri = Uri.parse('$baseUrl/balance');
    final response = await http.get(uri, headers: _requestHeaders());

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserBalance.fromJson(json);
    }
    if (response.statusCode == 401) {
      throw Exception('Authorization required');
    }
    throw Exception('Failed to fetch balance');
  }

  Future<List<GenerationHistoryItem>> fetchGenerations({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/generations').replace(
      queryParameters: {'limit': limit.toString()},
    );
    final response = await http.get(uri, headers: _requestHeaders());

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = json['generations'] as List<dynamic>? ?? [];
      final items = rawList
          .map(
            (item) => GenerationHistoryItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items
          .where((item) => !_isHiddenDevGenerationDescription(item.prompt))
          .toList();
    }
    if (response.statusCode == 401) {
      throw Exception('Authorization required');
    }
    throw Exception('Failed to fetch generations');
  }

  static const _allowedPhotoshootMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  String _resolveMultipartMimeType(XFile photoFile) {
    final declared = photoFile.mimeType?.trim().toLowerCase();
    if (declared != null && _allowedPhotoshootMimeTypes.contains(declared)) {
      return declared;
    }

    final path = photoFile.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (path.endsWith('.png')) {
      return 'image/png';
    }
    if (path.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _resolveFileName(XFile photoFile) {
    final path = photoFile.path;
    if (path.isEmpty) {
      return 'photoshoot.jpg';
    }
    final slashIdx = path.lastIndexOf('/');
    final backslashIdx = path.lastIndexOf('\\');
    final idx = slashIdx > backslashIdx ? slashIdx : backslashIdx;
    if (idx == -1 || idx + 1 >= path.length) {
      return 'photoshoot.jpg';
    }
    return path.substring(idx + 1);
  }

  static const _mockPaymentMaxRetries = 2;
  static const _mockPaymentRetryDelay = Duration(milliseconds: 600);

  Future<http.Response> _postMockPaymentWithRetry({
    required Uri uri,
    required Map<String, dynamic> body,
  }) async {
    const maxAttempts = _mockPaymentMaxRetries + 1;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_mockPaymentRetryDelay);
      }

      final response = await http.post(
        uri,
        headers: _requestHeaders(jsonBody: true),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return response;
      }
      if (response.statusCode == 403 ||
          response.statusCode == 404 ||
          response.statusCode == 501) {
        throw const MockPaymentUnavailableException();
      }
      if (response.statusCode == 400) {
        throw const MockPaymentFailedException();
      }
      if (response.statusCode == 503) {
        if (attempt < maxAttempts - 1) {
          continue;
        }
        throw const MockPaymentServiceUnavailableException();
      }
      throw const MockPaymentFailedException();
    }

    throw const MockPaymentServiceUnavailableException();
  }

  Future<MockVerifyRuStorePaymentResponse> mockVerifyRuStorePayment({
    required String packageId,
    required String providerPaymentId,
  }) async {
    final response = await _postMockPaymentWithRetry(
      uri: Uri.parse('$baseUrl/payments/rustore/mock-verify'),
      body: {
        'package_id': packageId,
        'provider_payment_id': providerPaymentId,
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MockVerifyRuStorePaymentResponse.fromJson(json);
  }

  /// Production RuStore verification (server-side). Not implemented on backend yet.
  ///
  /// TODO(rustore): call after RuStore Pay SDK returns purchase id / token.
  /// Backend path: ``POST /payments/rustore/verify``.
  Future<MockVerifyRuStorePaymentResponse> verifyRuStorePayment({
    required String packageId,
    required String providerPaymentId,
    String? purchaseToken,
  }) async {
    final response = await _postMockPaymentWithRetry(
      uri: Uri.parse('$baseUrl/payments/rustore/verify'),
      body: {
        'package_id': packageId,
        'provider_payment_id': providerPaymentId,
        'purchase_token': ?purchaseToken,
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MockVerifyRuStorePaymentResponse.fromJson(json);
  }

  Future<MockVerifyCustomAmountPaymentResponse> mockVerifyCustomAmountPayment({
    required int amountRub,
    required int paidPhotoshoots,
    required String providerPaymentId,
  }) async {
    final response = await _postMockPaymentWithRetry(
      uri: Uri.parse('$baseUrl/payments/rustore/mock-verify-custom'),
      body: {
        'amount_rub': amountRub,
        'paid_photoshoots': paidPhotoshoots,
        'provider_payment_id': providerPaymentId,
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MockVerifyCustomAmountPaymentResponse.fromJson(json);
  }

  Future<PhotoshootGenerateResponse> generatePhotoshoot({
    required String styleId,
    required String styleTitle,
    required XFile photoFile,
    String? description,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/photoshoots/generate'),
    );
    request.headers.addAll(_requestHeaders());
    request.fields['style_id'] = styleId;
    request.fields['style_title'] = styleTitle;
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
      request.fields['description'] = trimmedDescription;
    }

    final photoBytes = await photoFile.readAsBytes();
    final mimeType = _resolveMultipartMimeType(photoFile);
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: _resolveFileName(photoFile),
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 501) {
      throw const PhotoshootPlaceholderException();
    }
    if (response.statusCode == 400) {
      throw const PhotoshootInvalidPhotoException();
    }
    if (response.statusCode == 402) {
      throw const InsufficientPhotoshootsException();
    }
    if (response.statusCode == 500 || response.statusCode == 502 || response.statusCode == 503) {
      if (kDebugMode) {
        debugPrint(
          'POST /photoshoots/generate failed: '
          '${response.statusCode} ${response.body}',
        );
      }
      throw const PhotoshootGenerationFailedException();
    }
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PhotoshootGenerateResponse.fromJson(json);
    }
    throw Exception('Failed to prepare photoshoot');
  }

  Future<PhotoshootJobStartResponse> startPhotoshootJob({
    required String styleId,
    required String styleTitle,
    required XFile photoFile,
    String? description,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/photoshoots/generate/start'),
    );
    request.headers.addAll(_requestHeaders());
    request.fields['style_id'] = styleId;
    request.fields['style_title'] = styleTitle;
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
      request.fields['description'] = trimmedDescription;
    }

    final photoBytes = await photoFile.readAsBytes();
    final mimeType = _resolveMultipartMimeType(photoFile);
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: _resolveFileName(photoFile),
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 501) {
      throw const PhotoshootPlaceholderException();
    }
    if (response.statusCode == 400) {
      throw const PhotoshootInvalidPhotoException();
    }
    if (response.statusCode == 402) {
      throw const InsufficientPhotoshootsException();
    }
    if (response.statusCode >= 500) {
      throw const PhotoshootGenerationFailedException();
    }
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PhotoshootJobStartResponse.fromJson(json);
    }
    throw Exception('Failed to start photoshoot job');
  }

  Future<PhotoshootJobStatusResponse> getPhotoshootJobStatus(String jobId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/photoshoots/generate/status/$jobId'),
      headers: _requestHeaders(),
    );
    if (response.statusCode == 404) {
      throw const PhotoshootGenerationFailedException();
    }
    if (response.statusCode >= 500) {
      throw const PhotoshootGenerationFailedException();
    }
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PhotoshootJobStatusResponse.fromJson(json);
    }
    throw Exception('Failed to fetch photoshoot job status');
  }

  Future<PhotoshootGenerateResponse> generatePhotoshootWithProgress({
    required String styleId,
    required String styleTitle,
    required XFile photoFile,
    String? description,
    void Function(PhotoshootJobStatusResponse status)? onStatus,
  }) async {
    final started = await startPhotoshootJob(
      styleId: styleId,
      styleTitle: styleTitle,
      photoFile: photoFile,
      description: description,
    );
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final status = await getPhotoshootJobStatus(started.jobId);
      onStatus?.call(status);
      if (status.status == 'success') {
        return status.toGenerateResponse(
          fallbackStyleId: styleId,
          fallbackStyleTitle: styleTitle,
        );
      }
      if (status.status == 'error') {
        if (status.message.toLowerCase().contains('insufficient')) {
          throw const InsufficientPhotoshootsException();
        }
        throw const PhotoshootGenerationFailedException();
      }
    }
  }
}
