import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adaptive_practice_service.dart';
import '../../practice/services/ai_tutor_service.dart';

class PracticeReviewScreen extends ConsumerStatefulWidget {
  const PracticeReviewScreen({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.grade,
  });

  final List<PracticeQuestion> questions;

  /// Maps questionId → selectedOptionId
  final Map<String, String> selectedAnswers;

  final String grade;

  @override
  ConsumerState<PracticeReviewScreen> createState() =>
      _PracticeReviewScreenState();
}

class _PracticeReviewScreenState extends ConsumerState<PracticeReviewScreen> {
  int _currentIndex = 0;
  String? _loadingAiForQuestionId;
  final Map<String, String> _aiExplanations = {};

  PracticeQuestion get _current => widget.questions[_currentIndex];
  bool get _isFirst => _currentIndex == 0;
  bool get _isLast => _currentIndex == widget.questions.length - 1;

  Future<void> _askAiTutor() async {
    final question = _current;
    final correctOption =
        question.options.where((o) => o.id == question.correctOptionId).firstOrNull;
    final selectedOptionId = widget.selectedAnswers[question.id] ?? '';
    final userOption =
        question.options.where((o) => o.id == selectedOptionId).firstOrNull;

    if (correctOption == null || userOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot build AI explanation for this question.')),
      );
      return;
    }

    setState(() => _loadingAiForQuestionId = question.id);

    try {
      final explanation = await ref.read(aiTutorProvider).generateExplanation(
            questionText: question.stem,
            correctAnswer: correctOption.text,
            userAnswer: userOption.text,
            grade: widget.grade,
            isCorrect: selectedOptionId == question.correctOptionId,
          );
      if (!mounted) return;
      setState(() => _aiExplanations[question.id] = explanation);
    } on AITutorFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Tutor is temporarily unavailable.')),
      );
    } finally {
      if (mounted) setState(() => _loadingAiForQuestionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final question = _current;
    final selectedOptionId = widget.selectedAnswers[question.id] ?? '';
    final isCorrect = selectedOptionId == question.correctOptionId;
    final isLoadingAi = _loadingAiForQuestionId == question.id;
    final aiExplanation = _aiExplanations[question.id];

    return Scaffold(
      appBar: AppBar(
        title: Text('Review — ${_currentIndex + 1} of ${widget.questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Result chip
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFFE7F7F0)
                            : colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: isCorrect
                                ? const Color(0xFF1B7F5B)
                                : colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCorrect ? 'Correct' : 'Incorrect',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isCorrect
                                  ? const Color(0xFF1B7F5B)
                                  : colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Question stem
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        question.stem,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700, height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Options
                  ...question.options.map((option) {
                    final isSelected = option.id == selectedOptionId;
                    final isCorrectOption = option.id == question.correctOptionId;

                    Color borderColor = colorScheme.outlineVariant;
                    Color bgColor = colorScheme.surface;
                    IconData icon = Icons.circle_outlined;
                    Color iconColor = colorScheme.outlineVariant;

                    if (isCorrectOption) {
                      borderColor = const Color(0xFF1B7F5B);
                      bgColor = const Color(0xFFE7F7F0);
                      icon = Icons.check_circle_outline;
                      iconColor = const Color(0xFF1B7F5B);
                    } else if (isSelected) {
                      borderColor = colorScheme.error;
                      bgColor = colorScheme.errorContainer.withValues(alpha: 0.3);
                      icon = Icons.cancel_outlined;
                      iconColor = colorScheme.error;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: iconColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                option.text,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: (isSelected || isCorrectOption)
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isCorrectOption)
                              Text('Correct',
                                  style: TextStyle(
                                      color: const Color(0xFF1B7F5B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12))
                            else if (isSelected)
                              Text('Your choice',
                                  style: TextStyle(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 4),

                  // Static explanation
                  if (question.staticExplanation.isNotEmpty) ...[
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: colorScheme.primary),
                                const SizedBox(width: 6),
                                Text('Explanation',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(question.staticExplanation,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // AI Tutor button
                  if (!isCorrect)
                    OutlinedButton.icon(
                      onPressed: isLoadingAi ? null : _askAiTutor,
                      icon: isLoadingAi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_outlined),
                      label: Text(isLoadingAi ? 'Generating...' : 'Explain with AI'),
                    ),

                  // AI explanation card
                  if (aiExplanation != null && aiExplanation.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer.withValues(alpha: 0.4),
                            colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                          ],
                        ),
                        border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 16, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Text('AI Tutor',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          MarkdownBody(
                            data: aiExplanation,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Navigation row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isFirst
                              ? null
                              : () => setState(() => _currentIndex--),
                          icon: const Icon(Icons.chevron_left_rounded),
                          label: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLast
                            ? FilledButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                                icon: const Icon(Icons.done_rounded),
                                label: const Text('Done'),
                              )
                            : FilledButton.icon(
                                onPressed: () =>
                                    setState(() => _currentIndex++),
                                icon: const Icon(Icons.chevron_right_rounded),
                                label: const Text('Next'),
                              ),
                      ),
                    ],
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
