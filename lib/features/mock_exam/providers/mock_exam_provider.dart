import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adaptive_practice/adaptive_practice_service.dart';
import '../mock_exam_service.dart';

const int _defaultMockExamQuestionCount = 10;
const int _secondsPerQuestion = 60;
const int _defaultMockExamDurationSec =
    _defaultMockExamQuestionCount * _secondsPerQuestion;

class MockExamArgs {
  MockExamArgs({
    required this.grade,
    this.totalQuestions = _defaultMockExamQuestionCount,
    int? durationSec,
  }) : durationSec = durationSec ?? (totalQuestions * _secondsPerQuestion);

  final String grade;
  final int totalQuestions;
  final int durationSec;
}

enum MockExamStatus {
  notStarted,
  inProgress,
  finished,
}

class MockExamState {
  const MockExamState({
    this.status = MockExamStatus.notStarted,
    this.isLoading = true,
    this.isSaving = false,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.remainingTime = _defaultMockExamDurationSec,
    this.sessionId,
    this.startedAt,
    this.userAnswers = const {},
    this.result,
    this.errorMessage,
  });

  final MockExamStatus status;
  final bool isLoading;
  final bool isSaving;
  final List<PracticeQuestion> questions;
  final int currentQuestionIndex;
  final int remainingTime;
  final String? sessionId;
  final DateTime? startedAt;
  final Map<String, String> userAnswers;
  final MockExamResult? result;
  final String? errorMessage;

  PracticeQuestion? get currentQuestion {
    if (questions.isEmpty || currentQuestionIndex < 0) {
      return null;
    }
    if (currentQuestionIndex >= questions.length) {
      return questions.isEmpty ? null : questions.last;
    }
    return questions[currentQuestionIndex];
  }

  bool get isFinalQuestion =>
      questions.isNotEmpty && currentQuestionIndex >= questions.length - 1;

  int get answeredCount => userAnswers.length;

  MockExamState copyWith({
    MockExamStatus? status,
    bool? isLoading,
    bool? isSaving,
    List<PracticeQuestion>? questions,
    int? currentQuestionIndex,
    int? remainingTime,
    String? sessionId,
    DateTime? startedAt,
    Map<String, String>? userAnswers,
    MockExamResult? result,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearResult = false,
  }) {
    return MockExamState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      userAnswers: userAnswers ?? this.userAnswers,
      result: clearResult ? null : (result ?? this.result),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final mockExamServiceProvider = Provider<MockExamService>((ref) {
  return MockExamService();
});

final mockExamControllerProvider =
    StateNotifierProvider.family<MockExamNotifier, MockExamState, MockExamArgs>(
        (ref, args) {
  return MockExamNotifier(
    service: ref.read(mockExamServiceProvider),
    auth: FirebaseAuth.instance,
    args: args,
  );
});

class MockExamNotifier extends StateNotifier<MockExamState> {
  MockExamNotifier({
    required MockExamService service,
    required FirebaseAuth auth,
    required MockExamArgs args,
  })  : _service = service,
        _auth = auth,
        _args = args,
        super(const MockExamState()) {
    unawaited(_initialize());
  }

  final MockExamService _service;
  final FirebaseAuth _auth;
  final MockExamArgs _args;
  Timer? _timer;
  DateTime? _questionStartedAt;
  bool _isSubmitting = false;

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
      final user = _auth.currentUser;
      if (user == null) {
        throw StateError('You must be signed in to start a mock exam.');
      }

      final questions = await _service.fetchQuestionsForGrade(
        grade: _args.grade,
        limit: _args.totalQuestions,
      );
      final sessionId = await _service.createSession(
        uid: user.uid,
        grade: _args.grade,
        totalQuestions: questions.length,
        examDurationSec: _args.durationSec,
      );
      final startedAt = DateTime.now();

      state = state.copyWith(
        status: MockExamStatus.inProgress,
        isLoading: false,
        questions: questions,
        currentQuestionIndex: 0,
        remainingTime: _args.durationSec,
        sessionId: sessionId,
        startedAt: startedAt,
        userAnswers: const {},
        clearResult: true,
        clearErrorMessage: true,
      );
      _questionStartedAt = startedAt;
      _startTimer();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        status: MockExamStatus.notStarted,
        errorMessage: error.toString(),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      syncTimerFromWallClock();
    });
  }

  void syncTimerFromWallClock() {
    final startedAt = state.startedAt;
    if (startedAt == null || state.status != MockExamStatus.inProgress) {
      return;
    }

    final elapsedSec = DateTime.now().difference(startedAt).inSeconds;
    final nextRemaining = _args.durationSec - elapsedSec;
    if (nextRemaining <= 0) {
      state = state.copyWith(remainingTime: 0);
      unawaited(submitExam());
      return;
    }

    if (nextRemaining != state.remainingTime) {
      state = state.copyWith(remainingTime: nextRemaining);
    }
  }

  Future<void> selectOption(String optionId) async {
    final currentQuestion = state.currentQuestion;
    final user = _auth.currentUser;
    final sessionId = state.sessionId;
    if (currentQuestion == null || user == null || sessionId == null) {
      return;
    }

    final selectedOption = optionId.trim();
    if (selectedOption.isEmpty) {
      return;
    }

    final isCorrect = selectedOption == currentQuestion.correctOptionId;
    final durationSec = _questionDurationSec();
    final updatedAnswers = Map<String, String>.from(state.userAnswers)
      ..[currentQuestion.id] = selectedOption;

    state = state.copyWith(
      isSaving: true,
      userAnswers: updatedAnswers,
      clearErrorMessage: true,
    );

    try {
      await _service.saveAnswer(
        uid: user.uid,
        sessionId: sessionId,
        questionId: currentQuestion.id,
        selectedOption: selectedOption,
        isCorrect: isCorrect,
        durationSec: durationSec,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        clearErrorMessage: true,
      );
      _questionStartedAt = DateTime.now();
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
        clearErrorMessage: true,
      );
      _questionStartedAt = DateTime.now();
    }
  }

  Future<MockExamResult?> submitExam() async {
    if (_isSubmitting || state.status == MockExamStatus.finished) {
      return state.result;
    }

    final user = _auth.currentUser;
    final sessionId = state.sessionId;
    if (user == null || sessionId == null) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Unable to submit exam: missing user or session id.',
      );
      return null;
    }

    _isSubmitting = true;
    _timer?.cancel();
    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final totalQuestions = state.questions.length;
      final correctAnswers = state.questions.where((question) {
        final selectedOption = state.userAnswers[question.id];
        return selectedOption != null &&
            selectedOption == question.correctOptionId;
      }).length;
      final totalTimeSpentSec = _elapsedSec().clamp(1, _args.durationSec);

      final result = await _service.submitExam(
        uid: user.uid,
        sessionId: sessionId,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        totalTimeSpentSec: totalTimeSpentSec,
      );

      state = state.copyWith(
        status: MockExamStatus.finished,
        isSaving: false,
        remainingTime: 0,
        result: result,
        clearErrorMessage: true,
      );
      return result;
    } catch (error, stackTrace) {
      debugPrint('MockExamNotifier.submitExam error: ${error.toString()}');
      debugPrintStack(
        label: 'MockExamNotifier.submitExam stackTrace',
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: error.toString(),
      );
      return null;
    } finally {
      _isSubmitting = false;
    }
  }

  int _questionDurationSec() {
    final startedAt = _questionStartedAt ?? state.startedAt ?? DateTime.now();
    return DateTime.now().difference(startedAt).inSeconds.clamp(1, 999999);
  }

  int _elapsedSec() {
    final startedAt = state.startedAt ?? DateTime.now();
    return DateTime.now().difference(startedAt).inSeconds.clamp(1, 999999);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
