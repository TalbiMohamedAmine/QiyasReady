import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class AdaptivePracticeFailure implements Exception {
  const AdaptivePracticeFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class PracticeOption {
  const PracticeOption({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;
}

class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.stem,
    required this.options,
    required this.correctOptionId,
    required this.chapterId,
    required this.lessonId,
    required this.avgSolveSec,
    required this.explanationSteps,
  });

  final String id;
  final String stem;
  final List<PracticeOption> options;
  final String? correctOptionId;
  final String chapterId;
  final String lessonId;
  final int avgSolveSec;
  final List<String> explanationSteps;
}

class AdaptivePracticeService {
  AdaptivePracticeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<PracticeQuestion>> fetchPracticeQuestions({
    String? chapterId,
    String? lessonId,
    int limit = 20,
  }) async {
    if ((chapterId == null || chapterId.trim().isEmpty) &&
        (lessonId == null || lessonId.trim().isEmpty)) {
      throw const AdaptivePracticeFailure(
        'Please provide chapterId or lessonId to fetch practice questions.',
      );
    }

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('questions');

      if (lessonId != null && lessonId.trim().isNotEmpty) {
        query = query.where('lessonId', isEqualTo: lessonId.trim());
      } else if (chapterId != null && chapterId.trim().isNotEmpty) {
        query = query.where('chapterId', isEqualTo: chapterId.trim());
      }

      query = query.where('status', isEqualTo: 'active').limit(limit);

      final snapshot = await query.get();
      final questions = <PracticeQuestion>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final stem = (data['stem'] as String?)?.trim();
          final options = _parseOptions(data['options']);

          if (stem == null || stem.isEmpty || options.isEmpty) {
            continue;
          }

          questions.add(
            PracticeQuestion(
              id: doc.id,
              stem: stem,
              options: options,
              correctOptionId: data['correctOptionId'] as String?,
              chapterId: (data['chapterId'] as String?) ?? '',
              lessonId: (data['lessonId'] as String?) ?? '',
              avgSolveSec: _parseAvgSolveSec(data['avgSolveSec']),
              explanationSteps:
                  _parseExplanationSteps(data['explanationSteps']),
            ),
          );
        } catch (_) {
          // Skip malformed question documents to keep sessions usable.
          continue;
        }
      }

      if (questions.isEmpty) {
        throw const AdaptivePracticeFailure(
          'No practice questions found for the selected scope.',
          code: 'no-questions',
        );
      }

      return questions;
    } on FirebaseException catch (e) {
      throw AdaptivePracticeFailure(
        e.message ?? 'Failed to load practice questions. Please try again.',
        code: e.code,
      );
    } on SocketException {
      throw const AdaptivePracticeFailure(
        'No internet connection. Please check your network and try again.',
        code: 'network',
      );
    } on AdaptivePracticeFailure {
      rethrow;
    } catch (_) {
      throw const AdaptivePracticeFailure(
        'Unexpected error while loading practice questions.',
      );
    }
  }

  List<PracticeOption> _parseOptions(dynamic rawOptions) {
    if (rawOptions is! List) {
      return const [];
    }

    final options = <PracticeOption>[];

    for (var i = 0; i < rawOptions.length; i++) {
      final item = rawOptions[i];
      if (item is Map<String, dynamic>) {
        final id = (item['id'] as String?)?.trim();
        final text = (item['text'] as String?)?.trim();
        if (id != null && id.isNotEmpty && text != null && text.isNotEmpty) {
          options.add(PracticeOption(id: id, text: text));
        }
      } else if (item is String) {
        final text = item.trim();
        if (text.isNotEmpty) {
          options.add(
            PracticeOption(id: 'option_${i + 1}', text: text),
          );
        }
      }
    }

    return options;
  }

  int _parseAvgSolveSec(dynamic value) {
    if (value is int && value > 0) {
      return value;
    }
    if (value is num && value > 0) {
      return value.round();
    }
    return 60;
  }

  List<String> _parseExplanationSteps(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
