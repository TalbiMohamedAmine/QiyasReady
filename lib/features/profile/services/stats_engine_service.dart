import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsEngineFailure implements Exception {
  const StatsEngineFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class StatsEngineService {
  StatsEngineService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> finalizeSessionAndUpdateStats(
    String uid,
    Map<String, dynamic> sessionData,
  ) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw const StatsEngineFailure(
        'A valid user id is required to update statistics.',
        code: 'invalid-uid',
      );
    }

    final sessionTotals = _extractSessionTotals(sessionData);
    if (sessionTotals.totalAnswered <= 0) {
      throw const StatsEngineFailure(
        'Session data did not contain any answered questions.',
        code: 'invalid-session',
      );
    }

    final userRef = _firestore.collection('users').doc(normalizedUid);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data();
        final profile = _readMap(data?['profile']);
        final globalStats = _readMap(profile['global_stats']);

        final previousAnswered =
            _toInt(globalStats['total_questions_answered']);
        final previousCorrect = _toInt(globalStats['total_correct_answers']);
        final previousAverageSolveTime =
            _toDouble(globalStats['avg_solve_time']);

        final updatedAnswered = previousAnswered + sessionTotals.totalAnswered;
        final updatedCorrect = previousCorrect + sessionTotals.totalCorrect;
        final sessionAverageSolveTime = sessionTotals.totalAnswered > 0
            ? sessionTotals.totalTimeSpentSec / sessionTotals.totalAnswered
            : 0.0;

        final updatedAverageSolveTime = updatedAnswered > 0
            ? ((previousAverageSolveTime * previousAnswered) +
                    (sessionAverageSolveTime * sessionTotals.totalAnswered)) /
                updatedAnswered
            : sessionAverageSolveTime;

        final updatedProfile = <String, dynamic>{
          ...profile,
          'global_stats': {
            ...globalStats,
            'total_questions_answered': updatedAnswered,
            'total_correct_answers': updatedCorrect,
            'overall_accuracy':
                updatedAnswered > 0 ? (updatedCorrect / updatedAnswered) : 0.0,
            'avg_solve_time': updatedAverageSolveTime,
          },
        };

        transaction.set(
          userRef,
          {
            'profile': updatedProfile,
          },
          SetOptions(merge: true),
        );
      });
    } on FirebaseException catch (e) {
      throw StatsEngineFailure(
        e.message ?? 'Failed to update user statistics.',
        code: e.code,
      );
    } catch (_) {
      throw const StatsEngineFailure(
        'Failed to update user statistics.',
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

  _SessionTotals _extractSessionTotals(Map<String, dynamic> sessionData) {
    final score = _readMap(sessionData['score']);

    final totalAnswered = _firstInt(
      [
        sessionData['total_questions_answered'],
        sessionData['questionsAnswered'],
        sessionData['answeredCount'],
        score['total'],
      ],
    );

    final totalCorrect = _firstInt(
      [
        sessionData['total_correct_answers'],
        sessionData['correctCount'],
        score['correct'],
      ],
    );

    final totalTimeSpentSec = _firstDouble(
      [
        sessionData['total_time_spent_sec'],
        sessionData['totalTimeSpentSec'],
        sessionData['durationSec'],
        sessionData['timeSpentSec'],
      ],
    );

    return _SessionTotals(
      totalAnswered: totalAnswered,
      totalCorrect: totalCorrect,
      totalTimeSpentSec: totalTimeSpentSec,
    );
  }

  int _firstInt(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final parsed = _toInt(candidate);
      if (parsed > 0) {
        return parsed;
      }
    }
    return 0;
  }

  double _firstDouble(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final parsed = _toDouble(candidate);
      if (parsed > 0) {
        return parsed;
      }
    }
    return 0.0;
  }
}

class _SessionTotals {
  const _SessionTotals({
    required this.totalAnswered,
    required this.totalCorrect,
    required this.totalTimeSpentSec,
  });

  final int totalAnswered;
  final int totalCorrect;
  final double totalTimeSpentSec;
}

final statsEngineProvider = Provider<StatsEngineService>((ref) {
  return StatsEngineService();
});
