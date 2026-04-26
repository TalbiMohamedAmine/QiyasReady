import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adaptive_practice/providers/adaptive_practice_provider.dart';
import '../../adaptive_practice/screens/practice_runner_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_onboarding_provider.dart';

enum DashboardStudyMode { practice, mock }

class ProfileDashboardScreen extends ConsumerStatefulWidget {
  const ProfileDashboardScreen({super.key});

  @override
  ConsumerState<ProfileDashboardScreen> createState() =>
      _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState
    extends ConsumerState<ProfileDashboardScreen> {
  static const _practiceChapterId = 'chapter_seed_001';
  static const _gradeOptions = ['Grade 10', 'Grade 11', 'Grade 12'];

  bool _gradeDialogShown = false;
  DashboardStudyMode _selectedMode = DashboardStudyMode.practice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actionState = ref.watch(authControllerProvider);
    final practiceState = ref.watch(adaptivePracticeControllerProvider);
    final gradeAsync = ref.watch(userGradeProvider);

    ref.listen<AsyncValue<UserLifecycleStatus>>(userLifecycleStatusProvider,
        (previous, next) {
      if (!mounted || _gradeDialogShown) {
        return;
      }

      next.whenData((status) {
        if (status == UserLifecycleStatus.newUser) {
          _gradeDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            _showGradeSelectionDialog();
          });
        }
      });
    });

    ref.listen<AuthActionState>(authControllerProvider, (previous, next) {
      final previousError = previous?.errorMessage;
      final nextError = next.errorMessage;
      if (nextError != null && nextError != previousError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(nextError)));
      }
    });

    ref.listen<AdaptivePracticeState>(adaptivePracticeControllerProvider,
        (previous, next) {
      final previousError = previous?.errorMessage;
      final nextError = next.errorMessage;
      if (nextError != null && nextError != previousError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(nextError)));
      }
    });

    final selectedGrade = gradeAsync.valueOrNull;
    final canStartMode = selectedGrade != null &&
        practiceState.status != PracticeLoadStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(colorScheme: colorScheme),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;
                      final crossAxisCount = isWide ? 2 : 1;

                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: isWide ? 1.65 : 2.9,
                        ),
                        children: const [
                          StatCard(
                            label: 'Total Questions Answered',
                            value: '142',
                            icon: Icons.quiz_outlined,
                            accentColor: Color(0xFF0F4C81),
                            backgroundColor: Color(0xFFEAF3FF),
                          ),
                          StatCard(
                            label: 'Overall Accuracy',
                            value: '78%',
                            icon: Icons.track_changes_outlined,
                            accentColor: Color(0xFF1B7F5B),
                            backgroundColor: Color(0xFFE7F7F0),
                          ),
                          StatCard(
                            label: 'Average Solve Time',
                            value: '45s',
                            icon: Icons.timer_outlined,
                            accentColor: Color(0xFF2A6F97),
                            backgroundColor: Color(0xFFEAF6FB),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Choose Your Study Mode',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start quickly with a focused practice session or a full mock exam.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          _ModePickerCard(
                            title: 'Practice Mode',
                            description:
                                'Adaptive question flow for targeted skill-building.',
                            icon: Icons.menu_book_outlined,
                            isSelected:
                                _selectedMode == DashboardStudyMode.practice,
                            onTap: () {
                              setState(() {
                                _selectedMode = DashboardStudyMode.practice;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _ModePickerCard(
                            title: 'Mock Exam',
                            description:
                                'Simulate exam conditions with a timed run.',
                            icon: Icons.fact_check_outlined,
                            isSelected:
                                _selectedMode == DashboardStudyMode.mock,
                            onTap: () {
                              setState(() {
                                _selectedMode = DashboardStudyMode.mock;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: canStartMode
                                ? () => _startMode(selectedGrade: selectedGrade)
                                : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: practiceState.status ==
                                    PracticeLoadStatus.loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _selectedMode == DashboardStudyMode.practice
                                        ? 'Start Practice Mode'
                                        : 'Start Mock Exam',
                                  ),
                          ),
                          if (selectedGrade != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Current grade: $selectedGrade',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Upgrade your learning flow',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unlock premium practice packs, deeper analytics, and personalized exam guidance.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: const Color(0xFF0F4C81),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: const Text('Upgrade to Premium'),
                          ),
                          const SizedBox(height: 12),
                          Material(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              contentPadding:
                                  const EdgeInsetsDirectional.fromSTEB(
                                16,
                                4,
                                12,
                                4,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.settings_outlined,
                                  color: Color(0xFF0F4C81),
                                ),
                              ),
                              title: const Text('Settings'),
                              subtitle: Text(
                                'Manage app preferences and exam options',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: actionState.isLoading
                                ? null
                                : () {
                                    ref
                                        .read(authControllerProvider.notifier)
                                        .signOut();
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: BorderSide(color: colorScheme.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: actionState.isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.logout_outlined),
                            label: Text(
                              actionState.isLoading
                                  ? 'Signing out...'
                                  : 'Logout',
                            ),
                          ),
                          if (actionState.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              actionState.errorMessage!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
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

  Future<void> _showGradeSelectionDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final saveState = ref.watch(gradeSelectionControllerProvider);
            final isSaving = saveState.isLoading;

            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Text('Welcome! Select your Grade'),
                contentPadding:
                    const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 12),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose your current grade to personalize practice.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    for (final grade in _gradeOptions)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 10),
                        child: FilledButton.tonal(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final saved = await ref
                                      .read(
                                        gradeSelectionControllerProvider
                                            .notifier,
                                      )
                                      .saveGrade(grade);

                                  if (saved && mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: Text(grade),
                        ),
                      ),
                    if (saveState.hasError)
                      Text(
                        'Unable to save grade. Please try again.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.start,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startMode({required String? selectedGrade}) async {
    if (selectedGrade == null || selectedGrade.trim().isEmpty) {
      return;
    }

    final selectedMode =
        _selectedMode == DashboardStudyMode.practice ? 'practice' : 'mock';

    final controller = ref.read(adaptivePracticeControllerProvider.notifier);
    final chapterId = _selectedMode == DashboardStudyMode.practice
        ? _practiceChapterId
        : null;

    await controller.loadQuestions(
      selectedGrade: selectedGrade,
      selectedMode: selectedMode,
      chapterId: chapterId,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeRunnerScreen(chapterId: chapterId),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, Student!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your latest progress and learning shortcuts are ready.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.82,
                          ),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(
                Icons.person_outline,
                size: 34,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: accentColor.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModePickerCard extends StatelessWidget {
  const _ModePickerCard({
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
