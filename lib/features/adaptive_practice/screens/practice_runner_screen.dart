import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adaptive_practice_service.dart';
import '../providers/adaptive_practice_provider.dart';

class PracticeRunnerScreen extends ConsumerWidget {
  const PracticeRunnerScreen({
    super.key,
    this.chapterId,
    this.lessonId,
    this.questionTimeLimitSec = 60,
  });

  final String? chapterId;
  final String? lessonId;
  final int questionTimeLimitSec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adaptivePracticeControllerProvider);

    ref.listen<AdaptivePracticeState>(
      adaptivePracticeControllerProvider,
      (previous, next) {
        final previousError = previous?.errorMessage;
        if (next.errorMessage != null && next.errorMessage != previousError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        }
      },
    );

    final question = state.currentQuestion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Practice'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBody(
                context: context,
                ref: ref,
                state: state,
                question: question,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required AdaptivePracticeState state,
    required PracticeQuestion? question,
  }) {
    switch (state.status) {
      case PracticeLoadStatus.initial:
        return _InitialPracticeView(
          chapterId: chapterId,
          lessonId: lessonId,
          onStart: () {
            ref.read(adaptivePracticeControllerProvider.notifier).loadQuestions(
                  chapterId: chapterId,
                  lessonId: lessonId,
                  questionTimeLimitSec: questionTimeLimitSec,
                );
          },
        );
      case PracticeLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PracticeLoadStatus.error:
        return _ErrorView(
          message: state.errorMessage ??
              'Failed to load practice questions. Please try again.',
          onRetry: () {
            ref.read(adaptivePracticeControllerProvider.notifier).loadQuestions(
                  chapterId: chapterId,
                  lessonId: lessonId,
                  questionTimeLimitSec: questionTimeLimitSec,
                );
          },
        );
      case PracticeLoadStatus.completed:
        return _CompletedView(
          answeredCount: state.answeredCount,
          totalQuestions: state.questions.length,
          correctCount: state.correctCount,
          onRestart: () {
            ref.read(adaptivePracticeControllerProvider.notifier).loadQuestions(
                  chapterId: chapterId,
                  lessonId: lessonId,
                  questionTimeLimitSec: questionTimeLimitSec,
                );
          },
        );
      case PracticeLoadStatus.ready:
        if (question == null) {
          return _ErrorView(
            message: 'No active question available. Restart the practice.',
            onRetry: () {
              ref.read(adaptivePracticeControllerProvider.notifier).reset();
            },
          );
        }

        final selectedOptionId = state.selectedAnswers[question.id];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PracticeHeader(
              currentIndex: state.currentQuestionIndex + 1,
              totalQuestions: state.questions.length,
              remainingSec: state.remainingSec,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.stem,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    for (final option in question.options)
                      _OptionTile(
                        optionText: option.text,
                        isSelected: selectedOptionId == option.id,
                        onTap: () {
                          ref
                              .read(adaptivePracticeControllerProvider.notifier)
                              .selectAnswer(option.id);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        ref
                            .read(adaptivePracticeControllerProvider.notifier)
                            .nextQuestion();
                      },
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(state.isLastQuestion ? 'Submit' : 'Next'),
              ),
            ),
          ],
        );
    }
  }
}

class _InitialPracticeView extends StatelessWidget {
  const _InitialPracticeView({
    required this.chapterId,
    required this.lessonId,
    required this.onStart,
  });

  final String? chapterId;
  final String? lessonId;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ready to begin adaptive practice?',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          lessonId != null && lessonId!.trim().isNotEmpty
              ? 'Scope: Lesson ${lessonId!.trim()}'
              : chapterId != null && chapterId!.trim().isNotEmpty
                  ? 'Scope: Chapter ${chapterId!.trim()}'
                  : 'Select chapterId or lessonId in this screen constructor.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: onStart,
            child: const Text('Start Practice'),
          ),
        ),
      ],
    );
  }
}

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({
    required this.currentIndex,
    required this.totalQuestions,
    required this.remainingSec,
  });

  final int currentIndex;
  final int totalQuestions;
  final int remainingSec;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSec ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSec % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        Expanded(
          child: Text(
            'Question $currentIndex / $totalQuestions',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Chip(
          label: Text('Time: $minutes:$seconds'),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.optionText,
    required this.isSelected,
    required this.onTap,
  });

  final String optionText;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(optionText),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({
    required this.answeredCount,
    required this.totalQuestions,
    required this.correctCount,
    required this.onRestart,
  });

  final int answeredCount;
  final int totalQuestions;
  final int correctCount;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final accuracy = totalQuestions == 0
        ? 0
        : ((correctCount / totalQuestions) * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Practice session completed',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text('Answered: $answeredCount / $totalQuestions'),
        Text('Correct: $correctCount / $totalQuestions'),
        Text('Accuracy: $accuracy%'),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onRestart,
          child: const Text('Start Again'),
        ),
      ],
    );
  }
}
