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

class ApiService {
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
      headers: {'Content-Type': 'application/json'},
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
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = json['generations'] as List<dynamic>? ?? [];
      return rawList
          .map(
            (item) => GenerationHistoryItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }
    throw Exception('Failed to fetch generations');
  }
}
