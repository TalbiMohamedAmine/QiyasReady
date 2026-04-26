import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../practice/services/ai_tutor_service.dart';
import '../adaptive_practice_service.dart';
import '../providers/adaptive_practice_provider.dart';

class PracticeRunnerScreen extends ConsumerStatefulWidget {
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
  ConsumerState<PracticeRunnerScreen> createState() =>
      _PracticeRunnerScreenState();
}

class _PracticeRunnerScreenState extends ConsumerState<PracticeRunnerScreen> {
  bool _isLoadingAI = false;
  String? _aiExplanation;
  String? _activeQuestionId;
  String? _activeAnswerId;

  @override
  Widget build(BuildContext context) {
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
    if (question == null || _activeQuestionId != question.id) {
      _activeQuestionId = question?.id;
      _activeAnswerId = null;
      _aiExplanation = null;
      _isLoadingAI = false;
    }

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
    required AdaptivePracticeState state,
    required PracticeQuestion? question,
  }) {
    switch (state.status) {
      case PracticeLoadStatus.initial:
        return _InitialPracticeView(
          chapterId: widget.chapterId,
          lessonId: widget.lessonId,
          onStart: () {
            ref.read(adaptivePracticeControllerProvider.notifier).loadQuestions(
                  chapterId: widget.chapterId,
                  lessonId: widget.lessonId,
                  questionTimeLimitSec: widget.questionTimeLimitSec,
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
                  chapterId: widget.chapterId,
                  lessonId: widget.lessonId,
                  questionTimeLimitSec: widget.questionTimeLimitSec,
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
                  chapterId: widget.chapterId,
                  lessonId: widget.lessonId,
                  questionTimeLimitSec: widget.questionTimeLimitSec,
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
        if (_activeAnswerId != selectedOptionId) {
          _activeAnswerId = selectedOptionId;
          _aiExplanation = null;
          _isLoadingAI = false;
        }

        final selectedOption =
            _findOptionById(question.options, selectedOptionId);
        final correctOption =
            _findOptionById(question.options, question.correctOptionId);
        final hasAnswered = selectedOption != null;
        final isCorrect =
            hasAnswered && selectedOption.id == question.correctOptionId;

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
                    if (hasAnswered) ...[
                      const SizedBox(height: 12),
                      _AnswerFeedbackCard(
                        isCorrect: isCorrect,
                        isLoadingAI: _isLoadingAI,
                        aiExplanation: _aiExplanation,
                        onAskAiTutor: isCorrect ||
                                _isLoadingAI ||
                                selectedOption == null ||
                                correctOption == null
                            ? null
                            : () {
                                _askAiTutor(
                                  context: context,
                                  questionText: question.stem,
                                  correctAnswer: correctOption.text,
                                  userAnswer: selectedOption.text,
                                  grade: state.selectedGrade,
                                  isCorrect: isCorrect,
                                );
                              },
                        onAskAiTutor:
                            isCorrect || _isLoadingAI || correctOption == null
                                ? null
                                : () {
                                    _askAiTutor(
                                      questionText: question.stem,
                                      correctAnswer: correctOption.text,
                                      userAnswer: selectedOption.text,
                                      grade: state.selectedGrade,
                                    );
                                  },
                      ),
                    ],
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

  PracticeOption? _findOptionById(List<PracticeOption> options, String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }

    for (final option in options) {
      if (option.id == id) {
        return option;
      }
    }

    return null;
  }

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

      if (!mounted) {
        return;
      }

      setState(() {
        _aiExplanation = explanation;
      });
    } on AITutorFailure catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

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
}

class _AnswerFeedbackCard extends StatelessWidget {
  const _AnswerFeedbackCard({
    required this.isCorrect,
    required this.isLoadingAI,
    required this.aiExplanation,
    required this.onAskAiTutor,
  });

  final bool isCorrect;
  final bool isLoadingAI;
  final String? aiExplanation;
  final VoidCallback? onAskAiTutor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isCorrect
            ? const LinearGradient(
                colors: [Color(0xFFE8F8EE), Color(0xFFF6FCF8)],
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF1F2), Color(0xFFFFF9F6)],
              ),
        border: Border.all(
          color: isCorrect ? const Color(0xFF9FD8AE) : const Color(0xFFF1B0B7),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.error_outline,
                color: isCorrect ? const Color(0xFF1C7C54) : colorScheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCorrect
                      ? 'Great job! That answer is correct.'
                      : 'Not quite right. Let AI Tutor explain it.',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAskAiTutor,
              icon: isLoadingAI
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(isLoadingAI ? 'Generating...' : 'Ask AI Tutor'),
            ),
          ],
          if (aiExplanation != null && aiExplanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F0FF), Color(0xFFF4FAFF)],
                ),
                border: Border.all(color: const Color(0xFFB5CCF5)),
              ),
              padding: const EdgeInsets.all(12),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: MarkdownBody(
                  data: aiExplanation!,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
