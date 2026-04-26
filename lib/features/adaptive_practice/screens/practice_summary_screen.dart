import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/adaptive_practice_provider.dart';

class PracticeSummaryScreen extends ConsumerWidget {
  const PracticeSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adaptivePracticeControllerProvider);
    final totalQuestions = state.answeredCount;
    final correctCount = state.correctCount;
    final wrongCount = totalQuestions - correctCount;
    final accuracy = totalQuestions == 0
        ? 0
        : ((correctCount / totalQuestions) * 100).round();
    final elapsedMinutes = (state.elapsedSec / 60).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Summary'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your Score',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _SummaryCard(
                    label: 'Questions Answered',
                    value: '$totalQuestions',
                    icon: Icons.quiz_outlined,
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: 'Correct Answers',
                    value: '$correctCount',
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: 'Wrong Answers',
                    value: '$wrongCount',
                    icon: Icons.cancel_outlined,
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: 'Accuracy',
                    value: '$accuracy%',
                    icon: Icons.insights_outlined,
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: 'Time Spent',
                    value: '$elapsedMinutes min',
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Setup'),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
