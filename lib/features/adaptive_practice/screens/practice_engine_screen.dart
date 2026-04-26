import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../practice/services/ai_tutor_service.dart';
import '../../practice/services/bookmark_service.dart';
import '../adaptive_practice_service.dart';
import '../providers/adaptive_practice_provider.dart';
import 'practice_summary_screen.dart';

class PracticeEngineArgs {
  const PracticeEngineArgs({
    required this.selectedSubject,
    required this.chapterId,
    this.lessonId,
    this.selectedGrade,
  });

  final String selectedSubject;
  final String chapterId;
  final String? lessonId;
  final String? selectedGrade;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PracticeEngineArgs &&
        other.selectedSubject == selectedSubject &&
        other.chapterId == chapterId &&
        other.lessonId == lessonId &&
        other.selectedGrade == selectedGrade;
  }

  @override
  int get hashCode => Object.hash(
        selectedSubject,
        chapterId,
        lessonId,
        selectedGrade,
      );
}

class PracticeSessionResult {
  const PracticeSessionResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageTimePerQuestion,
    required this.userId,
    required this.sessionId,
    required this.statsSynced,
  });

  final int totalQuestions;
  final int correctAnswers;
  final double averageTimePerQuestion;
  final String userId;
  final String sessionId;
  final bool statsSynced;
}

class PracticeState {
  const PracticeState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.selectedOptionId,
    this.isAnswered = false,
    this.remainingSec = 60,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.sessionId,
    this.answeredCount = 0,
    this.totalDurationSec = 0,
  });

  final List<PracticeQuestion> questions;
  final int currentIndex;
  final int score;
  final String? selectedOptionId;
  final bool isAnswered;
  final int remainingSec;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? sessionId;
  final int answeredCount;
  final int totalDurationSec;

  PracticeQuestion? get currentQuestion {
    if (questions.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex == questions.length - 1;

  PracticeState copyWith({
    List<PracticeQuestion>? questions,
    int? currentIndex,
    int? score,
    String? selectedOptionId,
    bool clearSelectedOption = false,
    bool? isAnswered,
    int? remainingSec,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? sessionId,
    int? answeredCount,
    int? totalDurationSec,
  }) {
    return PracticeState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedOptionId: clearSelectedOption
          ? null
          : (selectedOptionId ?? this.selectedOptionId),
      isAnswered: isAnswered ?? this.isAnswered,
      remainingSec: remainingSec ?? this.remainingSec,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sessionId: sessionId ?? this.sessionId,
      answeredCount: answeredCount ?? this.answeredCount,
      totalDurationSec: totalDurationSec ?? this.totalDurationSec,
    );
  }
}

class PracticeController extends StateNotifier<PracticeState> {
  PracticeController(this._ref, this._args) : super(const PracticeState()) {
    unawaited(_initialize());
  }

  final Ref _ref;
  final PracticeEngineArgs _args;
  Timer? _timer;
  DateTime _questionStartedAt = DateTime.now();

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

  Future<void> _initialize() async {
    try {
      final auth = _ref.read(adaptivePracticeAuthProvider);
      final user = auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Please sign in to start practice.',
        );
        return;
      }

      final service = _ref.read(adaptivePracticeServiceProvider);
      final grade = _effectiveGrade;
      final questions = await service.fetchPracticeQuestions(
        chapterId: _args.chapterId,
        lessonId: _args.lessonId,
        mode: 'practice',
        limit: 20,
      );

      final sessionRef = _ref
          .read(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc();

      await sessionRef.set({
        'mode': 'practice',
        'grade': grade,
        'state': 'in_progress',
        'subject': _args.selectedSubject,
        'chapterId': _args.chapterId,
        'lessonId': _args.lessonId,
        'startedAt': FieldValue.serverTimestamp(),
        'globalStatsUpdated': false,
      });

      state = state.copyWith(
        isLoading: false,
        questions: questions,
        currentIndex: 0,
        score: 0,
        isAnswered: false,
        clearSelectedOption: true,
        remainingSec: 60,
        sessionId: sessionRef.id,
        answeredCount: 0,
        totalDurationSec: 0,
        clearError: true,
      );

      _startQuestionTimer();
    } on AdaptivePracticeFailure catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load practice session right now.',
      );
    }
  }

  String get _effectiveGrade {
    final raw = _args.selectedGrade?.trim();
    if (raw == null || raw.isEmpty) {
      return 'Grade 10';
    }
    return raw;
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    _questionStartedAt = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isAnswered || state.remainingSec <= 0) {
        if (state.remainingSec != 0) {
          state = state.copyWith(remainingSec: 0);
        }
        return;
      }

      state = state.copyWith(remainingSec: state.remainingSec - 1);
    });
  }

  int _questionDurationSec() {
    final elapsed = DateTime.now().difference(_questionStartedAt).inSeconds;
    if (elapsed < 0) {
      return 0;
    }
    if (elapsed == 0) {
      return 1;
    }
    return elapsed;
  }

  Future<void> selectOption(String optionId) async {
    if (state.isAnswered || state.isSaving) {
      return;
    }

    final question = state.currentQuestion;
    final sessionId = state.sessionId;
    final user = _ref.read(adaptivePracticeAuthProvider).currentUser;

    if (question == null || sessionId == null || user == null) {
      return;
    }

    final isCorrect = question.correctOptionId != null &&
        optionId == question.correctOptionId;
    final durationSec = _questionDurationSec();

    state = state.copyWith(
      selectedOptionId: optionId,
      isAnswered: true,
      score: isCorrect ? state.score + 1 : state.score,
      answeredCount: state.answeredCount + 1,
      totalDurationSec: state.totalDurationSec + durationSec,
      isSaving: true,
      clearError: true,
    );

    try {
      final answerRef = _ref
          .read(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId)
          .collection('answers')
          .doc(question.id);

      await answerRef.set({
        'selectedOption': optionId,
        'isCorrect': isCorrect,
        'durationSec': durationSec,
        'questionId': question.id,
      });

      state = state.copyWith(isSaving: false);
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            'Answer saved locally, but sync failed. Please check connection.',
      );
    }
  }

  Future<PracticeSessionResult?> nextQuestionOrFinish() async {
    if (!state.isAnswered) {
      return null;
    }

    if (!state.isLastQuestion) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearSelectedOption: true,
        isAnswered: false,
        remainingSec: 60,
        clearError: true,
      );
      _startQuestionTimer();
      return null;
    }

    final statsSynced = await _finishSessionAndUpdateStats();
    final user = _ref.read(adaptivePracticeAuthProvider).currentUser;
    final totalQuestions = state.answeredCount;

    if (user == null || state.sessionId == null) {
      return null;
    }

    final averageTimePerQuestion =
        totalQuestions > 0 ? (state.totalDurationSec / totalQuestions) : 0.0;

    return PracticeSessionResult(
      totalQuestions: totalQuestions,
      correctAnswers: state.score,
      averageTimePerQuestion: averageTimePerQuestion,
      userId: user.uid,
      sessionId: state.sessionId!,
      statsSynced: statsSynced,
    );
  }

  Future<bool> _finishSessionAndUpdateStats() async {
    _timer?.cancel();
    _timer = null;

    final user = _ref.read(adaptivePracticeAuthProvider).currentUser;
    final sessionId = state.sessionId;
    if (user == null || sessionId == null) {
      return false;
    }

    final firestore = _ref.read(firestoreProvider);
    final userRef = firestore.collection('users').doc(user.uid);
    final sessionRef = userRef.collection('sessions').doc(sessionId);

    final sessionAnswered = state.answeredCount;
    final sessionCorrect = state.score;

    try {
      await firestore.runTransaction((transaction) async {
        final sessionSnapshot = await transaction.get(sessionRef);
        final sessionData = sessionSnapshot.data() ?? <String, dynamic>{};
        final alreadyUpdated = sessionData['globalStatsUpdated'] == true;

        transaction.set(
          sessionRef,
          {
            'state': 'submitted',
            'endedAt': FieldValue.serverTimestamp(),
            'score': {
              'total': sessionAnswered,
              'correct': sessionCorrect,
              'wrong': sessionAnswered - sessionCorrect,
            },
            'globalStatsUpdated': true,
          },
          SetOptions(merge: true),
        );

        if (alreadyUpdated) {
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
        final combinedAnswered = existingTotalAnswered + sessionAnswered;
        final combinedCorrect = previousCorrectApprox + sessionCorrect;
        final updatedAccuracy =
            combinedAnswered > 0 ? (combinedCorrect / combinedAnswered) : 0.0;
        final sessionAverageSolveTime = sessionAnswered > 0
            ? (state.totalDurationSec / sessionAnswered)
            : 0.0;
        final updatedAverageSolveTime = combinedAnswered > 0
            ? ((existingAvgSolveTime * existingTotalAnswered) +
                    (sessionAverageSolveTime * sessionAnswered)) /
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
      });

      return true;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Session completed, but syncing final stats failed.',
      );
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final practiceControllerProvider = StateNotifierProvider.autoDispose
    .family<PracticeController, PracticeState, PracticeEngineArgs>((ref, args) {
  return PracticeController(ref, args);
});

class PracticeEngineScreen extends ConsumerStatefulWidget {
  const PracticeEngineScreen({
    super.key,
    required this.selectedSubject,
    required this.chapterId,
    this.lessonId,
    this.selectedGrade,
  });

  final String selectedSubject;
  final String chapterId;
  final String? lessonId;
  final String? selectedGrade;

  @override
  ConsumerState<PracticeEngineScreen> createState() =>
      _PracticeEngineScreenState();
}

class _PracticeEngineScreenState extends ConsumerState<PracticeEngineScreen> {
  bool _isLoadingAI = false;
  String? _aiExplanation;
  String? _activeQuestionId;

  Future<void> _askAiTutor({
    required String questionText,
    required String correctAnswer,
    required String userAnswer,
    required String grade,
    required bool isCorrect,
  }) async {
    setState(() {
      _isLoadingAI = true;
      _aiExplanation = null;
    });

    try {
      final explanation = await ref.read(aiTutorProvider).generateExplanation(
            questionText: questionText,
            correctAnswer: correctAnswer,
            userAnswer: userAnswer,
            grade: grade,
            isCorrect: isCorrect,
          );

      if (!mounted) return;

      setState(() {
        _aiExplanation = explanation;
      });
    } on AITutorFailure catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('AI Tutor is temporarily unavailable. Please retry.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAI = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final args = PracticeEngineArgs(
      selectedSubject: widget.selectedSubject,
      chapterId: widget.chapterId,
      lessonId: widget.lessonId,
      selectedGrade: widget.selectedGrade,
    );

    final state = ref.watch(practiceControllerProvider(args));
    final controller = ref.read(practiceControllerProvider(args).notifier);
    final question = state.currentQuestion;

    // Reset AI state when the question changes
    if (question != null && _activeQuestionId != question.id) {
      _activeQuestionId = question.id;
      _aiExplanation = null;
      _isLoadingAI = false;
    }

    ref.listen<PracticeState>(practiceControllerProvider(args),
        (previous, next) {
      final previousError = previous?.errorMessage;
      if (next.errorMessage != null && next.errorMessage != previousError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('${widget.selectedSubject} Practice'),
        actions: [
          if (question != null)
            _BookmarkButton(
              questionId: question.id,
              question: question,
              subject: widget.selectedSubject,
            ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : question == null
                ? const Center(child: Text('No questions available.'))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: SingleChildScrollView(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TimerCard(
                              questionIndex: state.currentIndex + 1,
                              questionCount: state.questions.length,
                              remainingSec: state.remainingSec,
                              isTimeExpired: state.remainingSec == 0,
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: colorScheme.outlineVariant),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  question.stem,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final option in question.options) ...[
                              _AnswerOptionCard(
                                option: option,
                                correctOptionId: question.correctOptionId,
                                selectedOptionId: state.selectedOptionId,
                                isAnswered: state.isAnswered,
                                onTap: () => controller.selectOption(option.id),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (state.isAnswered) ...[
                              const SizedBox(height: 10),
                              Card(
                                elevation: 0,
                                color: colorScheme.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                      color: colorScheme.outlineVariant),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Explanation',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        question.staticExplanation.isEmpty
                                            ? 'No explanation available.'
                                            : question.staticExplanation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.tonalIcon(
                                        onPressed: _isLoadingAI
                                            ? null
                                            : () {
                                                final correctOpt = question
                                                    .options
                                                    .where((o) =>
                                                        o.id ==
                                                        question
                                                            .correctOptionId)
                                                    .firstOrNull;
                                                final userOpt = question
                                                    .options
                                                    .where((o) =>
                                                        o.id ==
                                                        state
                                                            .selectedOptionId)
                                                    .firstOrNull;

                                                if (correctOpt == null ||
                                                    userOpt == null) {
                                                  return;
                                                }

                                                _askAiTutor(
                                                  questionText: question.stem,
                                                  correctAnswer:
                                                      correctOpt.text,
                                                  userAnswer: userOpt.text,
                                                  grade:
                                                      widget.selectedGrade ??
                                                          'Grade 10',
                                                  isCorrect: state.selectedOptionId ==
                                                      question.correctOptionId,
                                                );
                                              },
                                        icon: _isLoadingAI
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.auto_awesome),
                                        label: Text(
                                          _isLoadingAI
                                              ? 'Generating...'
                                              : 'Explain with AI',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // AI Tutor explanation card
                              if (_aiExplanation != null &&
                                  _aiExplanation!.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colorScheme.primaryContainer
                                            .withValues(alpha: 0.35),
                                        colorScheme.tertiaryContainer
                                            .withValues(alpha: 0.25),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'AI Tutor',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: MarkdownBody(
                                          data: _aiExplanation!,
                                          selectable: true,
                                          styleSheet: MarkdownStyleSheet(
                                            p: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                            if (state.isAnswered) ...[
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () async {
                                  final result =
                                      await controller.nextQuestionOrFinish();
                                  if (!context.mounted || result == null) {
                                    return;
                                  }

                                  await Navigator.of(context).pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => PracticeSummaryScreen(
                                        totalQuestions: result.totalQuestions,
                                        correctAnswers: result.correctAnswers,
                                        averageTimePerQuestion:
                                            result.averageTimePerQuestion,
                                        userId: result.userId,
                                        sessionId: result.sessionId,
                                        statsSynced: result.statsSynced,
                                      ),
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: Text(
                                  state.isLastQuestion
                                      ? 'Finish Session'
                                      : 'Next Question',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.questionIndex,
    required this.questionCount,
    required this.remainingSec,
    required this.isTimeExpired,
  });

  final int questionIndex;
  final int questionCount;
  final int remainingSec;
  final bool isTimeExpired;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
        child: Row(
          children: [
            Text(
              'Question $questionIndex/$questionCount',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Icon(
              Icons.timer_outlined,
              color: isTimeExpired ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '${remainingSec}s',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        isTimeExpired ? colorScheme.error : colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOptionCard extends StatelessWidget {
  const _AnswerOptionCard({
    required this.option,
    required this.correctOptionId,
    required this.selectedOptionId,
    required this.isAnswered,
    required this.onTap,
  });

  final PracticeOption option;
  final String? correctOptionId;
  final String? selectedOptionId;
  final bool isAnswered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    var backgroundColor = colorScheme.surface;
    var borderColor = colorScheme.outlineVariant;

    if (isAnswered) {
      final isCorrectOption =
          correctOptionId != null && option.id == correctOptionId;
      final isWrongSelected =
          selectedOptionId == option.id && selectedOptionId != correctOptionId;

      if (isCorrectOption) {
        backgroundColor = Colors.green.withValues(alpha: 0.16);
        borderColor = Colors.green;
      } else if (isWrongSelected) {
        backgroundColor = colorScheme.errorContainer.withValues(alpha: 0.55);
        borderColor = colorScheme.error;
      }
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isAnswered ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (isAnswered &&
                  correctOptionId != null &&
                  option.id == correctOptionId)
                const Icon(Icons.check_circle, color: Colors.green),
              if (isAnswered &&
                  selectedOptionId == option.id &&
                  selectedOptionId != correctOptionId)
                Icon(Icons.cancel, color: colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkButton extends ConsumerWidget {
  const _BookmarkButton({
    required this.questionId,
    required this.question,
    required this.subject,
  });

  final String questionId;
  final PracticeQuestion question;
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarkedAsync = ref.watch(isBookmarkedProvider(questionId));
    final isBookmarked = isBookmarkedAsync.valueOrNull ?? false;

    return IconButton(
      onPressed: () async {
        try {
          final nowBookmarked = await ref
              .read(bookmarkServiceProvider)
              .toggleBookmark(question: question, subject: subject);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  nowBookmarked
                      ? 'Question saved for later.'
                      : 'Bookmark removed.',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
        } catch (error) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
        }
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: Icon(
          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey(isBookmarked),
          color: isBookmarked
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
      tooltip: isBookmarked ? 'Remove bookmark' : 'Save for later',
    );
  }
}
