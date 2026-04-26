import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../onboarding/screens/welcome_screen.dart';
import '../../profile/providers/profile_onboarding_provider.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../../profile/screens/profile_dashboard_screen.dart';
import '../../subscriptions/providers/subscriptions_provider.dart';
import '../providers/adaptive_practice_provider.dart';
import 'practice_runner_screen.dart';

class PracticeFilterScreen extends ConsumerStatefulWidget {
  const PracticeFilterScreen({super.key});

  @override
  ConsumerState<PracticeFilterScreen> createState() =>
      _PracticeFilterScreenState();
}

class _PracticeFilterScreenState extends ConsumerState<PracticeFilterScreen> {
  static const _grades = ['10th Grade', '11th Grade', '12th Grade'];
  static const _practiceMode = 'practice';
  static const _mockMode = 'mock';

  static const _subjects = [
    _PracticeSubject(label: 'Math', chapterId: 'chapter_seed_001'),
  ];

  String _selectedGrade = '10th Grade';
  String _selectedMode = _practiceMode;
  String? _selectedChapterId;

  @override
  void initState() {
    super.initState();
    _selectedChapterId = _subjects.first.chapterId;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthActionState>(authControllerProvider, (previous, next) {
      final previousError = previous?.errorMessage;
      final nextError = next.errorMessage;
      if (nextError != null && nextError != previousError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(nextError)));
      }
    });

    ref.listen<AdaptivePracticeState>(
      adaptivePracticeControllerProvider,
      (previous, next) {
        final previousError = previous?.errorMessage;
        final nextError = next.errorMessage;
        if (nextError != null && nextError != previousError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(nextError)));
        }
      },
    );

    final authActionState = ref.watch(authControllerProvider);
    final practiceState = ref.watch(adaptivePracticeControllerProvider);
    final isPracticeMode = _selectedMode == _practiceMode;

    final canStart = (!isPracticeMode || _selectedChapterId != null) &&
        practiceState.status != PracticeLoadStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Setup'),
        actions: [
          TextButton.icon(
            onPressed: authActionState.isLoading
                ? null
                : () async {
                    final success =
                        await ref.read(authControllerProvider.notifier).signOut();

                    if (!context.mounted || !success) {
                      return;
                    }

                    ref.read(pendingPlanProvider.notifier).state = null;
                    ref.read(dashboardStudyModeProvider.notifier).state =
                        DashboardStudyMode.practice;
                    ref.read(gradeDialogShownProvider.notifier).state =
                        <String>{};

                    ref.invalidate(subscriptionsControllerProvider);
                    ref.invalidate(userPlanProvider);
                    ref.invalidate(userProfileStreamProvider);
                    ref.invalidate(userGradeProvider);
                    ref.invalidate(gradeSelectionControllerProvider);
                    ref.invalidate(adaptivePracticeControllerProvider);

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const WelcomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
            icon: authActionState.isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose your setup',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select grade, mode, and subject to start your session.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Grade',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final grade in _grades)
                        ChoiceChip(
                          label: Text(grade),
                          selected: _selectedGrade == grade,
                          onSelected: (_) {
                            setState(() {
                              _selectedGrade = grade;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Mode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _ModeSelectionCard(
                    title: 'Full Mock Exam',
                    description: 'Simulate full exam conditions and timing.',
                    icon: Icons.fact_check_outlined,
                    isSelected: _selectedMode == _mockMode,
                    onTap: () {
                      setState(() {
                        _selectedMode = _mockMode;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _ModeSelectionCard(
                    title: 'Practice by Subject',
                    description: 'Focus on one subject with adaptive pacing.',
                    icon: Icons.menu_book_outlined,
                    isSelected: _selectedMode == _practiceMode,
                    onTap: () {
                      setState(() {
                        _selectedMode = _practiceMode;
                        _selectedChapterId ??= _subjects.first.chapterId;
                      });
                    },
                  ),
                  if (isPracticeMode) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Subject',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final subject in _subjects)
                          ChoiceChip(
                            label: Text(subject.label),
                            selected: _selectedChapterId == subject.chapterId,
                            onSelected: (_) {
                              setState(() {
                                _selectedChapterId = subject.chapterId;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: canStart ? _startPractice : null,
                      child: practiceState.status == PracticeLoadStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Start Practice'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startPractice() async {
    final selectedChapter = _selectedChapterId;
    final isPracticeMode = _selectedMode == _practiceMode;

    if (isPracticeMode &&
        (selectedChapter == null || selectedChapter.isEmpty)) {
      return;
    }

    final controller = ref.read(adaptivePracticeControllerProvider.notifier);

    unawaited(
      controller.loadQuestions(
        selectedGrade: _selectedGrade,
        selectedMode: _selectedMode,
        chapterId: isPracticeMode ? selectedChapter : null,
      ),
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeRunnerScreen(
          chapterId: isPracticeMode ? selectedChapter : null,
        ),
      ),
    );
  }
}

class _PracticeSubject {
  const _PracticeSubject({
    required this.label,
    required this.chapterId,
  });

  final String label;
  final String chapterId;
}

class _ModeSelectionCard extends StatelessWidget {
  const _ModeSelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
