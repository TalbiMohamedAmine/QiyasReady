import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/exam_security_service.dart';
import '../../../core/security/security_overlay.dart';
import '../mock_exam_service.dart';
import '../providers/mock_exam_provider.dart';
import 'mock_result_screen.dart';

class MockExamScreen extends ConsumerStatefulWidget {
  const MockExamScreen({super.key, required this.grade});

  final String grade;

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen>
    with WidgetsBindingObserver {
  late final MockExamArgs _args;
  bool _showedLifecycleWarning = false;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    _args = MockExamArgs(grade: widget.grade);
    WidgetsBinding.instance.addObserver(this);

    _activateSecurityOrExit();

    ref.listenManual<MockExamState>(mockExamControllerProvider(_args),
        (previous, next) {
      if (next.status == MockExamStatus.finished && next.result != null) {
        _goToResult(next.result!);
      }

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });
  }

  Future<void> _activateSecurityOrExit() async {
    final isSecured = await ExamSecurityService.instance.enableProtection();
    if (isSecured || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Secure Exam Mode is unavailable on this device.'),
        ),
      );

    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    // Disable screen protection when leaving exam
    ExamSecurityService.instance.disableProtection();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(mockExamControllerProvider(_args).notifier)
          .syncTimerFromWallClock();
      return;
    }

    final movedToBackground = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;

    if (!movedToBackground || !mounted) {
      return;
    }

    if (kIsWeb) {
      return;
    }

    if (!_showedLifecycleWarning) {
      _showedLifecycleWarning = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mock exam is running. Leaving the app again will forfeit and submit.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _submitExamAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockExamControllerProvider(_args));

    return PopScope(
      canPop: false,
      child: SecurityOverlay(
        child: SecureShortcutBlocker(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Mock Exam - ${widget.grade}'),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Exam actions',
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    icon: const Icon(Icons.menu_open_rounded),
                  ),
                ),
              ],
            ),
            endDrawer: _MockExamDrawer(
              state: state,
              onSubmit: _submitExamAndNavigate,
              onForfeit: _confirmForfeit,
            ),
            body: SafeArea(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.errorMessage != null && state.questions.isEmpty
                      ? _MockExamErrorView(
                          message: state.errorMessage!,
                          onDismiss: () => Navigator.of(context).pop(),
                        )
                      : SecureContentWrapper(
                          child: _MockExamBody(
                            state: state,
                            onSelectOption: (optionId) => ref
                                .read(
                                    mockExamControllerProvider(_args).notifier)
                                .selectOption(optionId),
                            onNext: () => ref
                                .read(
                                    mockExamControllerProvider(_args).notifier)
                                .nextQuestion(),
                            onPrevious: () => ref
                                .read(
                                    mockExamControllerProvider(_args).notifier)
                                .previousQuestion(),
                            onSubmit: () {
                              _submitExamAndNavigate();
                            },
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitExamAndNavigate() async {
    try {
      final result = await ref
          .read(mockExamControllerProvider(_args).notifier)
          .submitExam();
      if (result != null) {
        _goToResult(result);
      }
    } catch (error, stackTrace) {
      debugPrint('MockExamScreen submit error: ${error.toString()}');
      debugPrintStack(
        label: 'MockExamScreen submit stackTrace',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to submit exam right now. Please try again.'),
          ),
        );
    }
  }

  Future<void> _confirmForfeit() async {
    final shouldForfeit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Forfeit Exam?'),
            content: const Text(
              'Forfeiting will submit the exam immediately with your current answers.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Forfeit & Submit'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldForfeit || !mounted) {
      return;
    }

    Navigator.of(context).pop();
    await _submitExamAndNavigate();
  }

  void _goToResult(MockExamResult result) {
    if (!mounted || _navigatedToResult) {
      return;
    }
    _navigatedToResult = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MockResultScreen(result: result),
        ),
      );
    });
  }
}

class _MockExamBody extends StatelessWidget {
  const _MockExamBody({
    required this.state,
    required this.onSelectOption,
    required this.onNext,
    required this.onPrevious,
    required this.onSubmit,
  });

  final MockExamState state;
  final ValueChanged<String> onSelectOption;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = state.questions.isEmpty
        ? 0.0
        : (state.currentQuestionIndex + 1) / state.questions.length;
    final formattedTime = _formatDuration(state.remainingTime);
    final timeColor = state.remainingTime <= 300
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;
    final selectedOptionId = state.userAnswers[question.id];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricChip(
                      label: 'Time left',
                      value: formattedTime,
                      color: timeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricChip(
                      label: 'Answered',
                      value: '${state.answeredCount}/${state.questions.length}',
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(
                'Question ${state.currentQuestionIndex + 1} of ${state.questions.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.stem,
                        style: theme.textTheme.titleLarge?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No explanations are shown during the mock exam. Select the best answer and keep moving.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...question.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExamOptionTile(
                      optionText: option.text,
                      selected: option.id == selectedOptionId,
                      enabled: !state.isSaving,
                      onTap: () => onSelectOption(option.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.currentQuestionIndex > 0 ? onPrevious : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      state.currentQuestionIndex < state.questions.length - 1
                          ? onNext
                          : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Next'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.isFinalQuestion ? onSubmit : null,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(state.isFinalQuestion
                      ? 'Submit Exam'
                      : 'Submit in drawer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int remainingSeconds) {
    final safeSeconds = remainingSeconds < 0 ? 0 : remainingSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ExamOptionTile extends StatelessWidget {
  const _ExamOptionTile({
    required this.optionText,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String optionText;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor =
        selected ? colorScheme.primary : colorScheme.outlineVariant;
    final backgroundColor = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.55)
        : colorScheme.surface;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.circle_outlined,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockExamDrawer extends StatelessWidget {
  const _MockExamDrawer({
    required this.state,
    required this.onSubmit,
    required this.onForfeit,
  });

  final MockExamState state;
  final VoidCallback onSubmit;
  final VoidCallback onForfeit;

  @override
  Widget build(BuildContext context) {
    final canSubmit = state.isFinalQuestion;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Exam Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The mock exam is non-pausable. Use these controls carefully.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _DrawerActionCard(
              title: 'Submit exam',
              subtitle: canSubmit
                  ? 'You are on the final question, so submission is enabled.'
                  : 'Submission is only enabled on the final question.',
              icon: Icons.send_rounded,
              enabled: canSubmit,
              onTap: canSubmit
                  ? () {
                      Navigator.of(context).pop();
                      onSubmit();
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            _DrawerActionCard(
              title: 'Forfeit exam',
              subtitle:
                  'End the exam now and submit with unanswered questions counted wrong.',
              icon: Icons.flag_outlined,
              enabled: true,
              onTap: onForfeit,
            ),
            const SizedBox(height: 12),
            const _DrawerActionCard(
              title: 'Common mistakes report',
              subtitle: 'Coming soon after scoring is finalized.',
              icon: Icons.auto_graph_rounded,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerActionCard extends StatelessWidget {
  const _DrawerActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}

class _MockExamErrorView extends StatelessWidget {
  const _MockExamErrorView({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not start mock exam',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onDismiss,
              child: const Text('Return'),
            ),
          ],
        ),
      ),
    );
  }
}
