import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../adaptive_practice_service.dart';
import 'practice_review_screen.dart';

class PracticeSummaryScreen extends StatefulWidget {
  const PracticeSummaryScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageTimePerQuestion,
    required this.userId,
    required this.sessionId,
    required this.statsSynced,
    required this.questions,
    required this.answeredOptions,
  });

  final int totalQuestions;
  final int correctAnswers;
  final double averageTimePerQuestion;
  final String userId;
  final String sessionId;
  final bool statsSynced;
  final List<PracticeQuestion> questions;
  final Map<String, String> answeredOptions;

  @override
  State<PracticeSummaryScreen> createState() => _PracticeSummaryScreenState();
}

class _PracticeSummaryScreenState extends State<PracticeSummaryScreen> {
  bool _isSyncingStats = false;

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

  @override
  void initState() {
    super.initState();
    if (!widget.statsSynced) {
      _syncGlobalStatsIfNeeded();
    }
  }

  Future<void> _syncGlobalStatsIfNeeded() async {
    if (_isSyncingStats) {
      return;
    }

    setState(() {
      _isSyncingStats = true;
    });

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(widget.userId);
    final sessionRef = userRef.collection('sessions').doc(widget.sessionId);

    try {
      await firestore.runTransaction((transaction) async {
        final sessionSnapshot = await transaction.get(sessionRef);
        final sessionData = sessionSnapshot.data() ?? <String, dynamic>{};

        if (sessionData['globalStatsUpdated'] == true) {
          return;
        }

        final userSnapshot = await transaction.get(userRef);
        final userData = userSnapshot.data() ?? <String, dynamic>{};
        final rootGlobalStats = _readMap(userData['global_stats']);
        final profile = _readMap(userData['profile']);
        final profileGlobalStats = _readMap(profile['global_stats']);
        final globalStats =
            rootGlobalStats.isNotEmpty ? rootGlobalStats : profileGlobalStats;

        final existingTotalAnswered =
            _toInt(globalStats['total_questions_answered']);
        final existingAccuracy = _toDouble(globalStats['overall_accuracy']);
        final existingAvgSolveTime = _toDouble(globalStats['avg_solve_time']);

        final previousCorrectApprox =
            (existingAccuracy * existingTotalAnswered).round();
        final combinedAnswered = existingTotalAnswered + widget.totalQuestions;
        final combinedCorrect = previousCorrectApprox + widget.correctAnswers;
        final updatedAccuracy =
            combinedAnswered > 0 ? (combinedCorrect / combinedAnswered) : 0.0;
        final sessionAverageSolveTime =
            widget.totalQuestions > 0 ? (widget.averageTimePerQuestion) : 0.0;
        final updatedAverageSolveTime = combinedAnswered > 0
            ? ((existingAvgSolveTime * existingTotalAnswered) +
                    (sessionAverageSolveTime * widget.totalQuestions)) /
                combinedAnswered
            : sessionAverageSolveTime;

        final updatedGlobalStats = <String, dynamic>{
          ...globalStats,
          'total_questions_answered': combinedAnswered,
          'total_correct_answers': combinedCorrect,
          'overall_accuracy': updatedAccuracy,
          'avg_solve_time': updatedAverageSolveTime,
        };

        transaction.set(
          userRef,
          {
            'global_stats': updatedGlobalStats,
            'profile': {
              ...profile,
              'global_stats': updatedGlobalStats,
            },
          },
          SetOptions(merge: true),
        );

        transaction.set(
          sessionRef,
          {
            'globalStatsUpdated': true,
          },
          SetOptions(merge: true),
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Summary loaded, but stats sync is pending.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accuracyRatio = widget.totalQuestions == 0
        ? 0.0
        : widget.correctAnswers / widget.totalQuestions;
    final accuracyPercent = (accuracyRatio * 100).round();
    final averageTime = widget.averageTimePerQuestion;

    final encouragement = accuracyPercent >= 80
        ? 'Excellent Work!'
        : (accuracyPercent < 50 ? 'Keep Practicing!' : 'Nice Progress!');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.surfaceContainerHighest,
                        ],
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          encouragement,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You completed your practice session. Here is your performance snapshot.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: SizedBox(
                            width: 190,
                            height: 190,
                            child: Stack(
                              fit: StackFit.expand,
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: accuracyRatio.clamp(0, 1),
                                  strokeWidth: 14,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHigh,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    accuracyPercent >= 80
                                        ? Colors.green
                                        : (accuracyPercent < 50
                                            ? colorScheme.error
                                            : colorScheme.primary),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${widget.correctAnswers}/${widget.totalQuestions}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Correct',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _PerformanceTag(
                        label: 'Speed',
                        value: '${averageTime.toStringAsFixed(1)} s/question',
                        icon: Icons.bolt_rounded,
                      ),
                      _PerformanceTag(
                        label: 'Accuracy',
                        value: '$accuracyPercent%',
                        icon: Icons.track_changes_rounded,
                      ),
                    ],
                  ),
                  if (_isSyncingStats) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(minHeight: 3),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Back to Dashboard'),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformanceTag extends StatelessWidget {
  const _PerformanceTag({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
