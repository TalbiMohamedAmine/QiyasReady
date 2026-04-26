import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/global_mistake.dart';

class GlobalAnalyticsService {
  GlobalAnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<GlobalMistake>> fetchGlobalMistakes({
    String? subjectFilter,
    int maxItems = 50,
  }) async {
    final answersSnapshot = await _firestore.collectionGroup('answers').get();

    final byQuestion = <String, _QuestionAggregate>{};
    for (final answerDoc in answersSnapshot.docs) {
      final data = answerDoc.data();
      final questionId =
          ((data['questionId'] as String?)?.trim().isNotEmpty ?? false)
              ? (data['questionId'] as String).trim()
              : answerDoc.id;

      if (questionId.isEmpty) {
        continue;
      }

      final aggregate = byQuestion.putIfAbsent(
        questionId,
        () => _QuestionAggregate(questionId: questionId),
      );

      aggregate.totalAttempts += 1;
      final isCorrect = data['isCorrect'] == true;
      if (!isCorrect) {
        aggregate.wrongCount += 1;
        final selectedOption = (data['selectedOption'] as String?)?.trim();
        if (selectedOption != null && selectedOption.isNotEmpty) {
          aggregate.wrongOptionCounts[selectedOption] =
              (aggregate.wrongOptionCounts[selectedOption] ?? 0) + 1;
        }
      }
    }

    if (byQuestion.isEmpty) {
      return const [];
    }

    final questionDocs = await _fetchQuestionDocs(byQuestion.keys.toList());

    final normalizedFilter = subjectFilter?.trim().toLowerCase();
    final results = <GlobalMistake>[];

    for (final entry in byQuestion.entries) {
      final questionData = questionDocs[entry.key];
      if (questionData == null) {
        continue;
      }

      final totalAttempts = entry.value.totalAttempts;
      if (totalAttempts <= 0) {
        continue;
      }

      final subject = _extractSubject(questionData);
      if (normalizedFilter != null &&
          normalizedFilter.isNotEmpty &&
          normalizedFilter != 'all' &&
          subject.toLowerCase() != normalizedFilter) {
        continue;
      }

      final wrongCount = entry.value.wrongCount;
      final failureRate = (wrongCount / totalAttempts) * 100;
      final options = _extractOptions(questionData['options']);
      final correctOptionId = _extractCorrectOptionId(questionData, options);
      final mostCommonWrongOptionId = _mostCommonWrongOptionId(
        entry.value.wrongOptionCounts,
      );

      results.add(
        GlobalMistake(
          questionId: entry.key,
          totalAttempts: totalAttempts,
          failureRate:
              failureRate.isNaN || failureRate.isInfinite ? 0.0 : failureRate,
          subject: subject,
          questionText: (questionData['stem'] as String?)?.trim() ?? '',
          staticExplanation:
              (questionData['static_explanation'] as String?)?.trim() ?? '',
          correctAnswer: _resolveOptionText(options, correctOptionId),
          popularWrongAnswer:
              _resolveOptionText(options, mostCommonWrongOptionId),
        ),
      );
    }

    results.sort((a, b) {
      final failCompare = b.failureRate.compareTo(a.failureRate);
      if (failCompare != 0) {
        return failCompare;
      }
      return b.totalAttempts.compareTo(a.totalAttempts);
    });

    return results.take(max(0, maxItems)).toList(growable: false);
  }

  Future<bool> hasPurchasedReport(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return false;
    }

    final userDoc =
        await _firestore.collection('users').doc(normalizedUid).get();
    final data = userDoc.data() ?? <String, dynamic>{};

    if (data['hasPurchasedGlobalReport'] == true) {
      return true;
    }

    final entitlement = data['entitlement'];
    if (entitlement is Map<String, dynamic>) {
      return entitlement['hasPurchasedGlobalReport'] == true;
    }
    if (entitlement is Map) {
      final cast = Map<String, dynamic>.fromEntries(
        entitlement.entries
            .where((entry) => entry.key is String)
            .map((entry) => MapEntry(entry.key as String, entry.value)),
      );
      return cast['hasPurchasedGlobalReport'] == true;
    }

    return false;
  }

  Future<void> purchaseReport(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'A valid uid is required to purchase the report.',
      );
    }

    await _firestore.collection('users').doc(normalizedUid).set(
      {
        'hasPurchasedGlobalReport': true,
        'entitlement': {
          'hasPurchasedGlobalReport': true,
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, Map<String, dynamic>>> _fetchQuestionDocs(
    List<String> questionIds,
  ) async {
    final ids = questionIds.where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return const {};
    }

    final docs = await Future.wait(
      ids.map((id) => _firestore.collection('questions').doc(id).get()),
    );

    final result = <String, Map<String, dynamic>>{};
    for (final doc in docs) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        continue;
      }
      result[doc.id] = data;
    }
    return result;
  }

  String _extractSubject(Map<String, dynamic> questionData) {
    final subject = (questionData['subject'] as String?)?.trim();
    if (subject != null && subject.isNotEmpty) {
      return subject;
    }

    final chapterId = (questionData['chapterId'] as String?)?.trim();
    if (chapterId == null || chapterId.isEmpty) {
      return 'General';
    }

    if (chapterId.toLowerCase().contains('arith')) {
      return 'Arithmetic';
    }
    if (chapterId.toLowerCase().contains('analog')) {
      return 'Analogy';
    }
    if (chapterId.toLowerCase().contains('complet')) {
      return 'Completion';
    }

    return chapterId;
  }

  List<Map<String, String>> _extractOptions(dynamic rawOptions) {
    if (rawOptions is! List) {
      return const [];
    }

    final options = <Map<String, String>>[];
    for (var index = 0; index < rawOptions.length; index++) {
      final item = rawOptions[index];
      if (item is Map<String, dynamic>) {
        final id = (item['id'] as String?)?.trim();
        final text = (item['text'] as String?)?.trim();
        if (id != null && id.isNotEmpty && text != null && text.isNotEmpty) {
          options.add({'id': id, 'text': text});
        }
      } else if (item is String) {
        final text = item.trim();
        if (text.isNotEmpty) {
          options.add({'id': 'option_${index + 1}', 'text': text});
        }
      }
    }

    return options;
  }

  String _extractCorrectOptionId(
    Map<String, dynamic> questionData,
    List<Map<String, String>> options,
  ) {
    final raw = questionData['correctOptionId'];

    if (raw is String) {
      final trimmed = raw.trim();
      if (options.any((option) => option['id'] == trimmed)) {
        return trimmed;
      }

      final index = int.tryParse(trimmed);
      if (index != null && index >= 0 && index < options.length) {
        return options[index]['id'] ?? '';
      }
    }

    if (raw is int && raw >= 0 && raw < options.length) {
      return options[raw]['id'] ?? '';
    }

    return '';
  }

  String _resolveOptionText(
      List<Map<String, String>> options, String optionId) {
    if (optionId.trim().isEmpty) {
      return '';
    }

    for (final option in options) {
      if (option['id'] == optionId) {
        return option['text'] ?? '';
      }
    }
    return '';
  }

  String _mostCommonWrongOptionId(Map<String, int> wrongOptionCounts) {
    if (wrongOptionCounts.isEmpty) {
      return '';
    }

    final sorted = wrongOptionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

class _QuestionAggregate {
  _QuestionAggregate({required this.questionId});

  final String questionId;
  int totalAttempts = 0;
  int wrongCount = 0;
  final Map<String, int> wrongOptionCounts = <String, int>{};
}
