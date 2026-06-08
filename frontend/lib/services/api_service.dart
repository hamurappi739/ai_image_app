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

class PhotoshootPlaceholderException implements Exception {
  const PhotoshootPlaceholderException();
}

class PhotoshootInvalidPhotoException implements Exception {
  const PhotoshootInvalidPhotoException();
}

class PhotoshootGenerateResponse {
  const PhotoshootGenerateResponse({
    required this.styleId,
    required this.styleTitle,
    required this.imageUrls,
    required this.outputCount,
    required this.photoshootId,
    this.balance,
  });

  final String styleId;
  final String styleTitle;
  final List<String> imageUrls;
  final int outputCount;
  final String photoshootId;
  final UserBalance? balance;

  factory PhotoshootGenerateResponse.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['image_urls'] as List<dynamic>? ?? [];
    final rawBalance = json['balance'];
    return PhotoshootGenerateResponse(
      styleId: json['style_id'] as String,
      styleTitle: json['style_title'] as String,
      imageUrls: rawUrls.map((url) => url as String).toList(),
      outputCount: json['output_count'] as int? ?? rawUrls.length,
      photoshootId: json['photoshoot_id'] as String? ?? '',
      balance: rawBalance is Map<String, dynamic>
          ? UserBalance.fromJson(rawBalance)
          : null,
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

class ApiService {
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

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
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
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/generate-with-photo'),
    );
    request.headers.addAll(_requestHeaders());
    request.fields['description'] = description;

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
          .toList();
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

  Future<MockVerifyRuStorePaymentResponse> mockVerifyRuStorePayment({
    required String packageId,
    required String providerPaymentId,
  }) async {
    final uri = Uri.parse('$baseUrl/payments/rustore/mock-verify');
    final response = await http.post(
      uri,
      headers: _requestHeaders(jsonBody: true),
      body: jsonEncode({
        'package_id': packageId,
        'provider_payment_id': providerPaymentId,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return MockVerifyRuStorePaymentResponse.fromJson(json);
    }
    if (response.statusCode == 403 || response.statusCode == 404) {
      throw const MockPaymentUnavailableException();
    }
    throw const MockPaymentFailedException();
  }

  Future<PhotoshootGenerateResponse> generatePhotoshoot({
    required String styleId,
    required String styleTitle,
    required XFile photoFile,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/photoshoots/generate'),
    );
    request.headers.addAll(_requestHeaders());
    request.fields['style_id'] = styleId;
    request.fields['style_title'] = styleTitle;

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
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PhotoshootGenerateResponse.fromJson(json);
    }
    throw Exception('Failed to prepare photoshoot');
  }
}
