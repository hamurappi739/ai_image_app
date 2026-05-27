import 'dart:convert';

import 'package:ai_image_generator/models/generated_image_item.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GenerateImageResponse {
  const GenerateImageResponse({
    required this.imageUrl,
    required this.prompt,
    this.paymentType,
    this.creditConsumed = false,
    this.remainingFreeGenerations,
    this.remainingPaidCredits,
  });

  final String imageUrl;
  final String prompt;
  final String? paymentType;
  final bool creditConsumed;
  final int? remainingFreeGenerations;
  final int? remainingPaidCredits;

  factory GenerateImageResponse.fromJson(Map<String, dynamic> json) {
    return GenerateImageResponse(
      imageUrl: json['image_url'] as String,
      prompt: json['prompt'] as String,
      paymentType: json['payment_type'] as String?,
      creditConsumed: json['credit_consumed'] as bool? ?? false,
      remainingFreeGenerations: json['remaining_free_generations'] as int?,
      remainingPaidCredits: json['remaining_paid_credits'] as int?,
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
  });

  final String id;
  final String prompt;
  final String imageUrl;
  final String paymentType;
  final DateTime createdAt;

  factory GenerationHistoryItem.fromJson(Map<String, dynamic> json) {
    return GenerationHistoryItem(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      imageUrl: json['image_url'] as String,
      paymentType: json['payment_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  GeneratedImageItem toGalleryItem() {
    return GeneratedImageItem(
      id: id,
      description: prompt,
      imageUrl: imageUrl,
      createdAt: createdAt,
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
      throw Exception('No available generations');
    }
    throw Exception('Failed to generate image');
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
    throw Exception('Failed to fetch generations');
  }
}
