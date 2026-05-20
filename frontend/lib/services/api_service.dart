import 'dart:convert';

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
}
