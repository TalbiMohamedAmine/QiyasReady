import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../adaptive_practice/adaptive_practice_service.dart';

class MockExamResult {
  const MockExamResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalTimeSpentSec,
    required this.averageTimePerQuestion,
    required this.userId,
    required this.sessionId,
    required this.statsSynced,
  });

  final int totalQuestions;
  final int correctAnswers;
  final int totalTimeSpentSec;
  final double averageTimePerQuestion;
  final String userId;
  final String sessionId;
  final bool statsSynced;
}

class MockExamService {
  MockExamService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Random _random = Random();

  Future<List<PracticeQuestion>> fetchQuestionsForGrade({
    required String grade,
    int limit = 120,
  }) async {
    final normalizedGrade = grade.trim();
    if (normalizedGrade.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'A valid grade is required for mock exam questions.',
      );
    }

    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('target_grade', arrayContains: normalizedGrade)
          .get();

      final questions = <PracticeQuestion>[];
      for (final doc in snapshot.docs) {
        final parsed = _parseQuestion(doc.id, doc.data());
        if (parsed != null) {
          questions.add(parsed);
        }
      }

      if (questions.isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No mock exam questions were found for the selected grade.',
        );
      }

      questions.shuffle(_random);
      if (questions.length > limit) {
        return questions.take(limit).toList(growable: false);
      }
      return questions;
    } on FirebaseException {
      rethrow;
    } catch (error) {
      debugPrint('MockExamService.fetchQuestionsForGrade error: $error');
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unknown',
        message: 'Failed to load mock exam questions.',
      );
    }
  }

  Future<String> createSession({
    required String uid,
    required String grade,
    required int totalQuestions,
    required int examDurationSec,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'A valid user id is required to start a mock exam.',
      );
    }

    final startedAt = DateTime.now();
    final userRef = _firestore.collection('users').doc(normalizedUid);
    final sessionRef = userRef.collection('sessions').doc();

    try {
      await userRef.set(
        {
          'last_mock_exam_started_at': Timestamp.fromDate(startedAt),
        },
        SetOptions(merge: true),
      );

      await sessionRef.set({
        'mode': 'mock',
        'grade': grade,
        'state': 'in_progress',
        'totalQuestions': totalQuestions,
        'startedAt': Timestamp.fromDate(startedAt),
        'examDurationSec': examDurationSec,
        'ai_analysis_status': 'pending',
      });
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
          'MockExamService.createSession Firebase error: ${error.toString()}');
      debugPrintStack(
        label: 'MockExamService.createSession stackTrace',
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('MockExamService.createSession error: ${error.toString()}');
      debugPrintStack(
        label: 'MockExamService.createSession stackTrace',
        stackTrace: stackTrace,
      );
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unknown',
        message: 'Failed to create mock exam session.',
      );
    }

    return sessionRef.id;
  }

  Future<void> saveAnswer({
    required String uid,
    required String sessionId,
    required String questionId,
    required String selectedOption,
    required bool isCorrect,
    required int durationSec,
  }) async {
    final answerRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .doc(questionId);

    try {
      await answerRef.set({
        'selectedOption': selectedOption,
        'isCorrect': isCorrect,
        'durationSec': durationSec,
        'questionId': questionId,
      });
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
          'MockExamService.saveAnswer Firebase error: ${error.toString()}');
      debugPrintStack(
        label: 'MockExamService.saveAnswer stackTrace',
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('MockExamService.saveAnswer error: ${error.toString()}');
      debugPrintStack(
        label: 'MockExamService.saveAnswer stackTrace',
        stackTrace: stackTrace,
      );
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unknown',
        message: 'Failed to save mock exam answer.',
      );
    }
  }

  Future<MockExamResult> submitExam({
    required String uid,
    required String sessionId,
    required int totalQuestions,
    required int correctAnswers,
    required int totalTimeSpentSec,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'A valid user id is required to submit the mock exam.',
      );
    }

    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'A valid session id is required to submit the mock exam.',
      );
    }

    final userRef = _firestore.collection('users').doc(normalizedUid);
    final sessionRef = userRef.collection('sessions').doc(normalizedSessionId);

    final sessionPayload = <String, dynamic>{
      'state': 'submitted',
      'endedAt': FieldValue.serverTimestamp(),
      'totalQuestions': totalQuestions,
      'score': {
        'total': totalQuestions,
        'correct': correctAnswers,
        'wrong': totalQuestions - correctAnswers,
      },
      'totalTimeSpentSec': totalTimeSpentSec,
      'ai_analysis_status': 'pending',
    };

    var statsSynced = false;

    try {
      await _firestore.runTransaction((transaction) async {
        final sessionSnapshot = await transaction.get(sessionRef);
        final sessionData = sessionSnapshot.data() ?? <String, dynamic>{};
        final alreadySubmitted = sessionData['state'] == 'submitted';

        debugPrint(
          'MockExamService.submitExam paths: userRef=${userRef.path}, sessionRef=${sessionRef.path}',
        );
        debugPrint(
            'MockExamService.submitExam session payload: $sessionPayload');

        transaction.set(
          sessionRef,
          sessionPayload,
          SetOptions(merge: true),
        );

        if (alreadySubmitted) {
          return;
        }

        final userSnapshot = await transaction.get(userRef);
        final userData = userSnapshot.data() ?? <String, dynamic>{};
        final rootGlobalStats = _readMap(userData['global_stats']);
        final profile = _readMap(userData['profile']);
        final profileGlobalStats = _readMap(profile['global_stats']);
        final globalStats =
            rootGlobalStats.isNotEmpty ? rootGlobalStats : profileGlobalStats;

        final previousAnswered =
            _toInt(globalStats['total_questions_answered']);
        final previousCorrect = _toInt(globalStats['total_correct_answers']);
        final previousTimeSpent = _toInt(globalStats['total_time_spent_sec']);

        final updatedAnswered = previousAnswered + totalQuestions;
        final updatedCorrect = previousCorrect + correctAnswers;
        final updatedTimeSpent = previousTimeSpent + totalTimeSpentSec;
        final updatedAccuracy = _safeFiniteDouble(
          updatedAnswered > 0 ? (updatedCorrect / updatedAnswered) : 0.0,
        );
        final updatedAverageSolveTime = _safeFiniteDouble(
          updatedAnswered > 0 ? (updatedTimeSpent / updatedAnswered) : 0.0,
        );

        final updatedGlobalStats = <String, dynamic>{
          ...globalStats,
          'total_questions_answered': FieldValue.increment(totalQuestions),
          'total_correct_answers': FieldValue.increment(correctAnswers),
          'total_time_spent_sec': FieldValue.increment(totalTimeSpentSec),
          'overall_accuracy': updatedAccuracy,
          'avg_solve_time': updatedAverageSolveTime,
        };

        final userPayload = <String, dynamic>{
          'global_stats': updatedGlobalStats,
          'profile': {
            ...profile,
            'global_stats': updatedGlobalStats,
          },
        };

        debugPrint('MockExamService.submitExam user payload: $userPayload');

        transaction.set(
          userRef,
          userPayload,
          SetOptions(merge: true),
        );

        statsSynced = true;
      });
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
          'MockExamService.submitExam Firebase error: ${error.toString()}');
      debugPrintStack(
        label: 'MockExamService.submitExam stackTrace',
        stackTrace: stackTrace,
      );

      final recovered = await _submitExamWithoutReadTransaction(
        userRef: userRef,
        sessionRef: sessionRef,
        sessionPayload: sessionPayload,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        totalTimeSpentSec: totalTimeSpentSec,
      );

      if (!recovered) {
        rethrow;
      }
      statsSynced = true;
    } catch (error, stackTrace) {
      debugPrint('MockExamService.submitExam error: ${error.toString()}');
      debugPrint(
          'MockExamService.submitExam error runtimeType: ${error.runtimeType}');
      debugPrintStack(
        label: 'MockExamService.submitExam stackTrace',
        stackTrace: stackTrace,
      );

      final recovered = await _submitExamWithoutReadTransaction(
        userRef: userRef,
        sessionRef: sessionRef,
        sessionPayload: sessionPayload,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        totalTimeSpentSec: totalTimeSpentSec,
      );

      if (!recovered) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unknown',
          message: 'Failed to submit mock exam session.',
        );
      }
      statsSynced = true;
    }

    final averageTimePerQuestion = _safeFiniteDouble(
      totalQuestions > 0 ? (totalTimeSpentSec / totalQuestions) : 0.0,
    );

    return MockExamResult(
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      totalTimeSpentSec: totalTimeSpentSec,
      averageTimePerQuestion: averageTimePerQuestion,
      userId: normalizedUid,
      sessionId: normalizedSessionId,
      statsSynced: statsSynced,
    );
  }

  Future<bool> _submitExamWithoutReadTransaction({
    required DocumentReference<Map<String, dynamic>> userRef,
    required DocumentReference<Map<String, dynamic>> sessionRef,
    required Map<String, dynamic> sessionPayload,
    required int totalQuestions,
    required int correctAnswers,
    required int totalTimeSpentSec,
  }) async {
    try {
      final statsPayload = <String, dynamic>{
        'total_questions_answered': FieldValue.increment(totalQuestions),
        'total_correct_answers': FieldValue.increment(correctAnswers),
        'total_time_spent_sec': FieldValue.increment(totalTimeSpentSec),
      };

      final userPayload = <String, dynamic>{
        'global_stats': statsPayload,
        'profile': {
          'global_stats': statsPayload,
        },
      };

      debugPrint(
        'MockExamService.submitExam fallback paths: userRef=${userRef.path}, sessionRef=${sessionRef.path}',
      );
      debugPrint(
          'MockExamService.submitExam fallback session payload: $sessionPayload');
      debugPrint(
          'MockExamService.submitExam fallback user payload: $userPayload');

      final batch = _firestore.batch();
      batch.set(sessionRef, sessionPayload, SetOptions(merge: true));
      batch.set(userRef, userPayload, SetOptions(merge: true));
      await batch.commit();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
          'MockExamService.submitExam fallback failed: ${error.toString()}');
      debugPrintStack(
        label: 'MockExamService.submitExam fallback stackTrace',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  double _safeFiniteDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }
    return value;
  }

  PracticeQuestion? _parseQuestion(String docId, Map<String, dynamic> data) {
    final stem = (data['stem'] as String?)?.trim();
    final options = _parseOptions(data['options']);
    if (stem == null || stem.isEmpty || options.isEmpty) {
      return null;
    }

    final status = (data['status'] as String?)?.trim().toLowerCase();
    if (status != null && status.isNotEmpty && status != 'active') {
      return null;
    }

    final correctOptionId = _normalizeCorrectOptionId(
      data['correctOptionId'],
      options,
    );
    if (correctOptionId == null) {
      return null;
    }

    return PracticeQuestion(
      id: docId,
      stem: stem,
      options: options,
      correctOptionId: correctOptionId,
      chapterId: (data['chapterId'] as String?)?.trim() ?? '',
      lessonId: (data['lessonId'] as String?)?.trim() ?? '',
      avgSolveSec: _parseAvgSolveSec(data['avgSolveSec']),
      staticExplanation: (data['static_explanation'] as String?)?.trim() ?? '',
      explanationSteps: const [],
    );
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
          options.add(PracticeOption(id: 'option_${i + 1}', text: text));
        }
      }
    }

    if (options.length > 1) {
      options.shuffle(_random);
    }

    return options;
  }

  String? _normalizeCorrectOptionId(
      dynamic value, List<PracticeOption> options) {
    if (value is String) {
      final trimmed = value.trim();
      if (options.any((option) => option.id == trimmed)) {
        return trimmed;
      }

      final parsedIndex = int.tryParse(trimmed);
      if (parsedIndex != null &&
          parsedIndex >= 0 &&
          parsedIndex < options.length) {
        return options[parsedIndex].id;
      }
    } else if (value is int && value >= 0 && value < options.length) {
      return options[value].id;
    }

    return null;
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

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.where((entry) => entry.key is String).map(
              (entry) => MapEntry(entry.key as String, entry.value),
            ),
      );
    }
    return <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return 0;
  }
}
