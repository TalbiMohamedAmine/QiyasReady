import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/study_plan_service.dart';

final studyPlanFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final studyPlanServiceProvider = Provider<StudyPlanService>((ref) {
  return StudyPlanService(firestore: ref.watch(studyPlanFirestoreProvider));
});

class StudyPlanSnapshot {
  const StudyPlanSnapshot({
    required this.examDate,
    required this.targetScore,
    required this.dailyGoalQuestions,
    required this.currentAccuracy,
    required this.daysRemaining,
  });

  final DateTime examDate;
  final int targetScore;
  final int dailyGoalQuestions;
  final double currentAccuracy;
  final int daysRemaining;

  int get questionsAwayFromGoal => dailyGoalQuestions;

  String get progressMessage {
    if (dailyGoalQuestions <= 0) {
      return 'You are on track with your daily goal.';
    }

    return 'You are $dailyGoalQuestions questions away from your daily goal!';
  }
}

final studyPlanProvider = StreamProvider<StudyPlanSnapshot?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestore = ref.watch(studyPlanFirestoreProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream<StudyPlanSnapshot?>.value(null);
      }

      return firestore.collection('users').doc(user.uid).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) {
          return null;
        }

        final profile = _readMap(data['profile']);
        final studyPlan = _readMap(profile['study_plan']);
        if (studyPlan.isEmpty) {
          return null;
        }

        final globalStats = _readMap(profile['global_stats']);
        final examDate = _readDate(studyPlan['exam_date']);
        final targetScore = _toInt(studyPlan['target_score']);
        final dailyGoalQuestions = _toInt(studyPlan['daily_goal_questions']);
        final currentAccuracy = _toDouble(globalStats['overall_accuracy']);

        if (examDate == null) {
          return null;
        }

        final daysRemaining = max(0, examDate.difference(DateTime.now()).inDays);

        return StudyPlanSnapshot(
          examDate: examDate,
          targetScore: targetScore,
          dailyGoalQuestions: dailyGoalQuestions,
          currentAccuracy: currentAccuracy,
          daysRemaining: daysRemaining,
        );
      });
    },
    loading: () => const Stream<StudyPlanSnapshot?>.empty(),
    error: (_, __) => const Stream<StudyPlanSnapshot?>.empty(),
  );
});

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

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
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