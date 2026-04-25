import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adaptive_practice_service.dart';

enum PracticeLoadStatus {
  initial,
  loading,
  ready,
  completed,
  error,
}

class AdaptivePracticeState {
  const AdaptivePracticeState({
    this.status = PracticeLoadStatus.initial,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.questionTimeLimitSec = 60,
    this.remainingSec = 60,
    this.isSubmitting = false,
    this.errorMessage,
    this.chapterId,
    this.lessonId,
  });

  final PracticeLoadStatus status;
  final List<PracticeQuestion> questions;
  final int currentQuestionIndex;
  final Map<String, String> selectedAnswers;
  final int questionTimeLimitSec;
  final int remainingSec;
  final bool isSubmitting;
  final String? errorMessage;
  final String? chapterId;
  final String? lessonId;

  PracticeQuestion? get currentQuestion {
    if (questions.isEmpty || currentQuestionIndex < 0) {
      return null;
    }
    if (currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  bool get isLastQuestion {
    if (questions.isEmpty) {
      return false;
    }
    return currentQuestionIndex == questions.length - 1;
  }

  int get answeredCount => selectedAnswers.length;

  int get correctCount {
    var count = 0;
    for (final question in questions) {
      final selected = selectedAnswers[question.id];
      if (selected != null && selected == question.correctOptionId) {
        count++;
      }
    }
    return count;
  }

  AdaptivePracticeState copyWith({
    PracticeLoadStatus? status,
    List<PracticeQuestion>? questions,
    int? currentQuestionIndex,
    Map<String, String>? selectedAnswers,
    int? questionTimeLimitSec,
    int? remainingSec,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? chapterId,
    String? lessonId,
    bool clearScope = false,
  }) {
    return AdaptivePracticeState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      questionTimeLimitSec: questionTimeLimitSec ?? this.questionTimeLimitSec,
      remainingSec: remainingSec ?? this.remainingSec,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      chapterId: clearScope ? null : (chapterId ?? this.chapterId),
      lessonId: clearScope ? null : (lessonId ?? this.lessonId),
    );
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final adaptivePracticeServiceProvider =
    Provider<AdaptivePracticeService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AdaptivePracticeService(firestore: firestore);
});

class AdaptivePracticeController extends StateNotifier<AdaptivePracticeState> {
  AdaptivePracticeController(this._service)
      : super(const AdaptivePracticeState());

  final AdaptivePracticeService _service;
  Timer? _timer;

  Future<void> loadQuestions({
    String? chapterId,
    String? lessonId,
    int? questionTimeLimitSec,
    int limit = 20,
  }) async {
    state = state.copyWith(
      status: PracticeLoadStatus.loading,
      clearError: true,
      chapterId: chapterId,
      lessonId: lessonId,
      clearScope: false,
    );

    try {
      final questions = await _service.fetchPracticeQuestions(
        chapterId: chapterId,
        lessonId: lessonId,
        limit: limit,
      );

      final effectiveTimeLimit =
          questionTimeLimitSec != null && questionTimeLimitSec > 0
              ? questionTimeLimitSec
              : questions.first.avgSolveSec;

      state = state.copyWith(
        status: PracticeLoadStatus.ready,
        questions: questions,
        currentQuestionIndex: 0,
        selectedAnswers: <String, String>{},
        questionTimeLimitSec: effectiveTimeLimit,
        remainingSec: effectiveTimeLimit,
        isSubmitting: false,
        clearError: true,
      );

      _startTimer();
    } on AdaptivePracticeFailure catch (e) {
      _cancelTimer();
      state = state.copyWith(
        status: PracticeLoadStatus.error,
        errorMessage: e.message,
        isSubmitting: false,
      );
    } catch (_) {
      _cancelTimer();
      state = state.copyWith(
        status: PracticeLoadStatus.error,
        errorMessage: 'Failed to start adaptive practice. Please try again.',
        isSubmitting: false,
      );
    }
  }

  void selectAnswer(String optionId) {
    final question = state.currentQuestion;
    if (question == null || state.status != PracticeLoadStatus.ready) {
      return;
    }

    final updatedAnswers = Map<String, String>.from(state.selectedAnswers)
      ..[question.id] = optionId;

    state = state.copyWith(selectedAnswers: updatedAnswers);
  }

  Future<void> nextQuestion() async {
    if (state.status != PracticeLoadStatus.ready) {
      return;
    }

    if (state.isLastQuestion) {
      await submitPracticeSession();
      return;
    }

    final nextIndex = state.currentQuestionIndex + 1;
    state = state.copyWith(
      currentQuestionIndex: nextIndex,
      remainingSec: state.questionTimeLimitSec,
      clearError: true,
    );
  }

  Future<void> submitPracticeSession() async {
    if (state.isSubmitting) {
      return;
    }

    _cancelTimer();
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      state = state.copyWith(
        isSubmitting: false,
        status: PracticeLoadStatus.completed,
      );
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        status: PracticeLoadStatus.error,
        errorMessage: 'Failed to submit practice session. Please try again.',
      );
    }
  }

  void reset() {
    _cancelTimer();
    state = const AdaptivePracticeState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _startTimer() {
    _cancelTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentStatus = state.status;
      if (currentStatus != PracticeLoadStatus.ready) {
        return;
      }

      if (state.remainingSec <= 1) {
        state = state.copyWith(remainingSec: 0);
        unawaited(nextQuestion());
        return;
      }

      state = state.copyWith(remainingSec: state.remainingSec - 1);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}

final adaptivePracticeControllerProvider =
    StateNotifierProvider<AdaptivePracticeController, AdaptivePracticeState>(
        (ref) {
  final service = ref.watch(adaptivePracticeServiceProvider);
  return AdaptivePracticeController(service);
});
