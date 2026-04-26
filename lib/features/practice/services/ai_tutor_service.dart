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
    required bool isCorrect,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AITutorFailure(
        'OpenRouter API key is missing. Add OPENROUTER_API_KEY to your .env file.',
        code: 'missing-api-key',
      );
    }

    final String prompt;
    if (isCorrect) {
      prompt = '''
You are an expert, empathetic tutor for a $grade student in Saudi Arabia preparing for Qiyas (Qudurat/Tahsili) exams.
The student answered the question CORRECTLY. Your task is to reinforce their understanding and praise them.

[Question Data]
Question: "$questionText"
Student's Correct Answer: "$userAnswer"

[STRICT CONSTRAINTS]
1. OUTPUT LANGUAGE: You MUST write your entire response in Arabic (Fusha). Do NOT output any English words, letters, or punctuation.
2. NO REASONING: Do NOT output your internal thoughts, thinking process, or preambles. Output ONLY the final Arabic response.
3. FORMATTING: Use Markdown.

[REQUIRED OUTPUT STRUCTURE]
Follow this exact structure using these Arabic headings:

🌟 **إجابة رائعة وموفقة!**
(Write one short, encouraging sentence in Arabic praising them).

🎯 **لماذا هذه الإجابة صحيحة؟**
(Explain briefly in Arabic the logical rule or concept that makes this answer correct).

💡 **تلميحة سريعة:**
(Provide one quick, one-sentence tip in Arabic to help them remember this for the Qiyas exam).
''';
    } else {
      prompt = '''
You are an expert, empathetic tutor for a $grade student in Saudi Arabia preparing for Qiyas (Qudurat/Tahsili) exams.
The student answered the question INCORRECTLY. Your task is to clearly explain the concept and why they were wrong.

[Question Data]
Question: "$questionText"
Student's Wrong Answer: "$userAnswer"
Correct Answer: "$correctAnswer"

[STRICT CONSTRAINTS]
1. OUTPUT LANGUAGE: You MUST write your entire response in Arabic (Fusha). Do NOT output any English words, letters, or punctuation.
2. NO REASONING: Do NOT output your internal thoughts, thinking process, or preambles. Output ONLY the final Arabic response.
3. NO HALLUCINATION: Do not invent numbers or rules not present in the question.
4. FORMATTING: Use Markdown.

[REQUIRED OUTPUT STRUCTURE]
Follow this exact structure using these Arabic headings:

💡 **محاولة جيدة!**
(Write one short sentence in Arabic encouraging them and saying mistakes are how we learn).

🎯 **المفهوم الأساسي:**
(Explain the core mathematical or scientific rule behind this question briefly in Arabic).

🛠️ **كيف نصل للإجابة الصحيحة؟**
(Explain step-by-step in Arabic how to get to "$correctAnswer").

🔍 **أين كان الخلل؟**
(Explain gently in Arabic why their specific answer "$userAnswer" is incorrect and what trap they fell into).
''';
    }

    final requestBody = {
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
