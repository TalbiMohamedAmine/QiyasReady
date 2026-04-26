import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class AITutorFailure implements Exception {
  const AITutorFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AITutorService {
  const AITutorService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<String> generateExplanation({
    required String questionText,
    required String correctAnswer,
    required String userAnswer,
    required String grade,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AITutorFailure(
        'OpenRouter API key is missing. Add OPENROUTER_API_KEY to your .env file.',
        code: 'missing-api-key',
      );
    }

    final prompt =
        'You are an expert tutor for a $grade student in Saudi Arabia preparing for Qudurat/Tahsili. '
        "The student answered '$userAnswer' instead of the correct answer '$correctAnswer' "
        "for the question: '$questionText'. Explain briefly and kindly why their answer is wrong "
        'and how to find the correct one.';

    final requestBody = {
      // FIX: Changed from 'google/gemini-flash-1.5' to 'google/gemini-1.5-flash'
      'model': 'nvidia/nemotron-3-super-120b-a12b:free', 
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a concise, supportive exam tutor. Keep explanations practical and friendly.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.3,
      'max_tokens': 220,
    };

    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final response = await client.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://qiyas-ready.local',
          'X-Title': 'Qiyas Ready AI Tutor',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AITutorFailure(
          'AI Tutor failed (${response.statusCode}). Please try again.',
          code: 'http-${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const AITutorFailure('Invalid AI response format.');
      }

      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const AITutorFailure('AI response did not include any explanation.');
      }

      final firstChoice = choices.first;
      if (firstChoice is! Map<String, dynamic>) {
        throw const AITutorFailure('Invalid AI response choice format.');
      }

      final message = firstChoice['message'];
      if (message is! Map<String, dynamic>) {
        throw const AITutorFailure('Invalid AI response message format.');
      }

      final content = (message['content'] as String?)?.trim();
      if (content == null || content.isEmpty) {
        throw const AITutorFailure('AI Tutor returned an empty explanation.');
      }

      return content;
    } catch (error) {
      if (error is AITutorFailure) {
        rethrow;
      }

      throw const AITutorFailure(
        'Unable to generate AI explanation right now. Please try again.',
      );
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }
}

final aiTutorProvider = Provider<AITutorService>((ref) {
  return const AITutorService();
});
