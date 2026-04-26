import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../adaptive_practice/providers/adaptive_practice_provider.dart';
import '../../adaptive_practice/screens/subject_selection_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mock_exam/screens/mock_exam_screen.dart';
import '../providers/profile_onboarding_provider.dart';
import '../providers/session_history_provider.dart';
import '../providers/user_profile_provider.dart';

final gradeDialogShownProvider = StateProvider<bool>((ref) {
  return false;
});

class ProfileDashboardScreen extends ConsumerWidget {
  const ProfileDashboardScreen({super.key});

  static const _gradeOptions = ['Grade 10', 'Grade 11', 'Grade 12'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final actionState = ref.watch(authControllerProvider);
    final gradeAsync = ref.watch(userGradeProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final sessionHistoryAsync = ref.watch(sessionHistoryProvider);

    final totalAnswered = _readIntFromProfile(
      profileAsync.valueOrNull,
      'total_questions_answered',
    );
    final overallAccuracyRatio = _readDoubleFromProfile(
      profileAsync.valueOrNull,
      'overall_accuracy',
    );
    final avgSolveTime = _readDoubleFromProfile(
      profileAsync.valueOrNull,
      'avg_solve_time',
    );
    final overallAccuracyPct = (overallAccuracyRatio * 100).clamp(0, 100);
    final accuracyLabel = '${overallAccuracyPct.round()}%';
    final avgSolveLabel = '${avgSolveTime.round()}s';

    ref.listen<AsyncValue<UserLifecycleStatus>>(userLifecycleStatusProvider,
        (previous, next) {
      if (!context.mounted || ref.read(gradeDialogShownProvider)) {
        return;
      }

      next.whenData((status) {
        if (status == UserLifecycleStatus.newUser) {
          ref.read(gradeDialogShownProvider.notifier).state = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            _showGradeSelectionDialog(context, ref);
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
                        children: profileAsync.when(
                          loading: () => const [
                            _StatsLoadingCard(
                                label: 'Total Questions Answered'),
                            _StatsLoadingCard(label: 'Overall Accuracy'),
                            _StatsLoadingCard(label: 'Average Solve Time'),
                          ],
                          error: (_, __) => const [
                            StatCard(
                              label: 'Total Questions Answered',
                              value: '0',
                              icon: Icons.quiz_outlined,
                              accentColor: Color(0xFF0F4C81),
                              backgroundColor: Color(0xFFEAF3FF),
                            ),
                            StatCard(
                              label: 'Overall Accuracy',
                              value: '0%',
                              icon: Icons.track_changes_outlined,
                              accentColor: Color(0xFF1B7F5B),
                              backgroundColor: Color(0xFFE7F7F0),
                            ),
                            StatCard(
                              label: 'Average Solve Time',
                              value: '0s',
                              icon: Icons.timer_outlined,
                              accentColor: Color(0xFF2A6F97),
                              backgroundColor: Color(0xFFEAF6FB),
                            ),
                          ],
                          data: (_) => [
                            StatCard(
                              label: 'Total Questions Answered',
                              value: '$totalAnswered',
                              icon: Icons.quiz_outlined,
                              accentColor: const Color(0xFF0F4C81),
                              backgroundColor: const Color(0xFFEAF3FF),
                            ),
                            StatCard(
                              label: 'Overall Accuracy',
                              value: accuracyLabel,
                              icon: Icons.track_changes_outlined,
                              accentColor: const Color(0xFF1B7F5B),
                              backgroundColor: const Color(0xFFE7F7F0),
                            ),
                            StatCard(
                              label: 'Average Solve Time',
                              value: avgSolveLabel,
                              icon: Icons.timer_outlined,
                              accentColor: const Color(0xFF2A6F97),
                              backgroundColor: const Color(0xFFEAF6FB),
                            ),
                          ],
                        ),
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
                            'Recent Activity',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          sessionHistoryAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (_, __) => Text(
                              'Unable to load recent sessions right now.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colorScheme.error),
                            ),
                            data: (sessions) {
                              if (sessions.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'No sessions yet. Start your first practice!',
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sessions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final session = sessions[index];
                                  final subject = (session['subject']
                                                  as String?)
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? (session['subject'] as String).trim()
                                      : 'Session';
                                  final scoreMap = session['score'];
                                  final correct =
                                      scoreMap is Map<String, dynamic>
                                          ? _readIntFromMap(scoreMap, 'correct')
                                          : 0;
                                  final total = scoreMap is Map<String, dynamic>
                                      ? _readIntFromMap(scoreMap, 'total')
                                      : _readIntFromMap(
                                          session, 'total_questions');
                                  final date =
                                      _readSessionDate(session['date']);

                                  return Material(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      leading: Icon(
                                        _subjectIcon(subject),
                                        color: colorScheme.primary,
                                      ),
                                      title: Text(
                                        '$subject - $correct/$total - ${_formatActivityDate(date)}',
                                      ),
                                      subtitle: Text(
                                        (session['mode'] as String?) ??
                                            'Practice',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
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
                            'Pick how you want to study today. Subject Practice is ready now, and Mock Test is coming soon.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          _ExamModeActionCard(
                            title: 'Subject Practice',
                            description:
                                'Practice by subject with adaptive question flow.',
                            icon: Icons.book,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SubjectSelectionScreen(
                                    selectedGrade: selectedGrade,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _ExamModeActionCard(
                            title: 'Mock Test',
                            description:
                                'Simulate full test timing and pressure conditions.',
                            icon: Icons.timer,
                            onTap: () {
                              if (selectedGrade == null) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Select a grade before starting the mock test.',
                                      ),
                                    ),
                                  );
                                return;
                              }

                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => MockExamScreen(
                                    grade: selectedGrade,
                                  ),
                                ),
                              );
                            },
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

  Future<void> _showGradeSelectionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final saveState = ref.watch(gradeSelectionControllerProvider);
        final isSaving = saveState.isLoading;

        return PopScope(
          canPop: false,
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
                                    gradeSelectionControllerProvider.notifier,
                                  )
                                  .saveGrade(grade);

                              if (saved && context.mounted) {
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.start,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

int _readIntFromProfile(Map<String, dynamic>? profile, String key) {
  final stats = _readGlobalStats(profile);
  final value = stats[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return 0;
}

double _readDoubleFromProfile(Map<String, dynamic>? profile, String key) {
  final stats = _readGlobalStats(profile);
  final value = stats[key];
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

Map<String, dynamic> _readGlobalStats(Map<String, dynamic>? profile) {
  if (profile == null) {
    return const <String, dynamic>{};
  }
  final stats = profile['global_stats'];
  if (stats is Map<String, dynamic>) {
    return stats;
  }
  if (stats is Map) {
    return Map<String, dynamic>.fromEntries(
      stats.entries.where((entry) => entry.key is String).map(
            (entry) => MapEntry(entry.key as String, entry.value),
          ),
    );
  }
  return const <String, dynamic>{};
}

int _readIntFromMap(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return 0;
}

DateTime _readSessionDate(dynamic rawDate) {
  if (rawDate is Timestamp) {
    return rawDate.toDate();
  }
  if (rawDate is DateTime) {
    return rawDate;
  }
  return DateTime.now();
}

String _formatActivityDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final month = months[date.month - 1];
  return '$month ${date.day}';
}

IconData _subjectIcon(String subject) {
  final normalized = subject.toLowerCase();
  if (normalized.contains('math')) {
    return Icons.calculate_outlined;
  }
  if (normalized.contains('mock')) {
    return Icons.fact_check_outlined;
  }
  return Icons.menu_book_outlined;
}

class _StatsLoadingCard extends StatelessWidget {
  const _StatsLoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        child: Row(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
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

class _ExamModeActionCard extends StatelessWidget {
  const _ExamModeActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.onPrimary),
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
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
