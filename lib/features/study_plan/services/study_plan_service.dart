import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class StudyPlanFailure implements Exception {
  const StudyPlanFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class StudyPlanService {
  StudyPlanService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int standardTotalQuestions = 100;

  final FirebaseFirestore _firestore;

  int calculateDailyGoalQuestions({
    required double currentAccuracy,
    required int targetScore,
    required DateTime examDate,
    int standardQuestions = standardTotalQuestions,
  }) {
    final daysRemaining = examDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) {
      return 0;
    }

    final currentAccuracyPct = (currentAccuracy * 100).clamp(0.0, 100.0);
    final normalizedTarget = targetScore.clamp(0, 100).toDouble();
    final gap = normalizedTarget - currentAccuracyPct;
    if (gap <= 0) {
      return 0;
    }

    return max(0, ((gap * standardQuestions) / daysRemaining).ceil());
  }

  Future<int> updateUserGoal(
    String uid,
    DateTime examDate,
    int targetScore,
  ) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw const StudyPlanFailure(
        'A valid user id is required to update the study plan.',
        code: 'invalid-uid',
      );
    }

    final normalizedTargetScore = targetScore.clamp(0, 100);

    try {
      final userRef = _firestore.collection('users').doc(normalizedUid);
      final snapshot = await userRef.get();
      final data = snapshot.data();
      final profile = _readMap(data?['profile']);
      final globalStats = _readMap(profile['global_stats']);
      final currentAccuracy = _toDouble(globalStats['overall_accuracy']);
      final dailyGoalQuestions = calculateDailyGoalQuestions(
        currentAccuracy: currentAccuracy,
        targetScore: normalizedTargetScore,
        examDate: examDate,
      );

      await userRef.set(
        {
          'profile': {
            'study_plan': {
              'exam_date': Timestamp.fromDate(examDate),
              'target_score': normalizedTargetScore,
              'daily_goal_questions': dailyGoalQuestions,
            },
          },
        },
        SetOptions(merge: true),
      );

      return dailyGoalQuestions;
    } on FirebaseException catch (e) {
      throw StudyPlanFailure(
        e.message ?? 'Failed to save the study plan.',
        code: e.code,
      );
    } catch (_) {
      throw const StudyPlanFailure(
        'Unexpected error while saving the study plan.',
      );
    }
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

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}