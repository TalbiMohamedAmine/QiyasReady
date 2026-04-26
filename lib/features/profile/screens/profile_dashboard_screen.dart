import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../adaptive_practice/providers/adaptive_practice_provider.dart';
import '../../adaptive_practice/screens/subject_selection_screen.dart';
import '../../analytics/screens/global_report_screen.dart';
import '../../adaptive_practice/screens/practice_runner_screen.dart';
import '../../onboarding/screens/welcome_screen.dart';
import '../screens/bookmarked_questions_screen.dart';
import '../../practice/services/bookmark_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mock_exam/screens/mock_exam_screen.dart';
import '../../subscriptions/providers/subscriptions_provider.dart';
import '../../subscriptions/screens/plan_selection_screen.dart';
import 'wellbeing_stress_screen.dart';
import '../providers/profile_onboarding_provider.dart';
import '../providers/session_history_provider.dart';
import '../providers/user_profile_provider.dart';
import '../../../shared/widgets/upgrade_banner.dart';
import '../../goals/screens/goal_setting_screen.dart';
import '../../subscriptions/widgets/upgrade_modal.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';

enum DashboardStudyMode { practice, mock }

final dashboardStudyModeProvider = StateProvider<DashboardStudyMode>((ref) {
  return DashboardStudyMode.practice;
});

final gradeDialogShownProvider = StateProvider<Set<String>>((ref) {
  return <String>{};
});

// ─── Colors ────────────────────────────────────────────────────────────────
class _C {
  static const primary       = Color(0xFF1A6BFF);
  static const primaryLight  = Color(0xFFE8F0FF);
  static const bg            = Color(0xFFFFFFFF);
  static const surface       = Color(0xFFF7F8FC);
  static const textPrimary   = Color(0xFF1A1A2E);
  static const textMuted     = Color(0xFF6B7280);
  static const border        = Color(0xFFE0E0E0);
  static const cardBg        = Color(0xFFFFFFFF);
  static const dark          = Color(0xFF1A1A2E);
}

class ProfileDashboardScreen extends ConsumerWidget {
  const ProfileDashboardScreen({super.key});

  static const _gradeOptions = ['Grade 10', 'Grade 11', 'Grade 12'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final authAsync = ref.watch(authStateChangesProvider);
    final actionState = ref.watch(authControllerProvider);
    final gradeAsync = ref.watch(userGradeProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final sessionHistoryAsync = ref.watch(sessionHistoryProvider);
    final selectedMode = ref.watch(dashboardStudyModeProvider);
    final currentUserId = authAsync.valueOrNull?.uid;

    final planAsync = ref.watch(userPlanProvider);
    final plan = planAsync.valueOrNull;
    final isPlanLoading = planAsync.isLoading;
    final isFree = plan?.isFree ?? true;

    final mockExamCountAsync = ref.watch(mockExamCountProvider);
    final mockExamCount = mockExamCountAsync.valueOrNull ?? 0;

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

    final shouldShowGradeDialog = gradeAsync.hasValue &&
        (gradeAsync.valueOrNull == null ||
            gradeAsync.valueOrNull!.trim().isEmpty);

    final hasShownForCurrentUser = currentUserId != null &&
        ref.read(gradeDialogShownProvider).contains(currentUserId);

    if (shouldShowGradeDialog &&
        currentUserId != null &&
        !hasShownForCurrentUser) {
      _scheduleGradeDialog(context, ref, currentUserId);
    }

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
      backgroundColor: _C.surface,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: _C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _C.bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _C.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _C.border, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined, color: _C.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LeaderboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.track_changes, color: _C.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GoalSettingScreen(),
                ),
              );
            },
          ),
        ],
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
                  if (isPlanLoading) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 16),
                  ],
                  if (!isPlanLoading && isFree) ...[
                    const UpgradeBanner(),
                    const SizedBox(height: 16),
                  ],
                  _ProfileHeader(colorScheme: colorScheme),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;
                      final crossAxisCount = isWide ? 2 : 1;

                    final bookmarksAsync = ref.watch(bookmarkedQuestionsProvider);
                    final savedCount = bookmarksAsync.valueOrNull?.length ?? 0;

                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: isWide ? 1.4 : 2.5,
                        ),
                        children: profileAsync.when(
                          loading: () => [
                            const _StatsLoadingCard(
                                label: 'Total Questions Answered'),
                            const _StatsLoadingCard(label: 'Overall Accuracy'),
                            const _StatsLoadingCard(label: 'Average Solve Time'),
                            _BookmarkStatCard(
                              value: '$savedCount',
                            ),
                          ],
                          error: (_, __) => [
                            const StatCard(
                              label: 'Total Questions Answered',
                              value: '0',
                              icon: Icons.quiz_outlined,
                              accentColor: _C.primary,
                              backgroundColor: Colors.transparent,
                            ),
                            const StatCard(
                              label: 'Overall Accuracy',
                              value: '0%',
                              icon: Icons.track_changes_outlined,
                              accentColor: Color(0xFF10B981),
                              backgroundColor: Colors.transparent,
                            ),
                            const StatCard(
                              label: 'Average Solve Time',
                              value: '0s',
                              icon: Icons.timer_outlined,
                              accentColor: Color(0xFF8B5CF6),
                              backgroundColor: Colors.transparent,
                            ),
                            _BookmarkStatCard(
                              value: '$savedCount',
                            ),
                          ],
                          data: (_) => [
                            StatCard(
                              label: 'Total Questions Answered',
                              value: '$totalAnswered',
                              icon: Icons.quiz_outlined,
                              accentColor: _C.primary,
                              backgroundColor: Colors.transparent,
                            ),
                            StatCard(
                              label: 'Overall Accuracy',
                              value: accuracyLabel,
                              icon: Icons.track_changes_outlined,
                              accentColor: const Color(0xFF10B981),
                              backgroundColor: Colors.transparent,
                            ),
                            StatCard(
                              label: 'Average Solve Time',
                              value: avgSolveLabel,
                              icon: Icons.timer_outlined,
                              accentColor: const Color(0xFF8B5CF6),
                              backgroundColor: Colors.transparent,
                            ),
                            _BookmarkStatCard(
                              value: '$savedCount',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: _C.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _C.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          sessionHistoryAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary),
                              ),
                            ),
                            error: (_, __) => const Text(
                              'Unable to load recent sessions right now.',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                            data: (sessions) {
                              if (sessions.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'No sessions yet. Start your first practice!',
                                    style: TextStyle(color: _C.textMuted, fontSize: 14),
                                  ),
                                );
                              }

                              final displaySessions = isFree && sessions.length > 3 
                                  ? sessions.sublist(0, 3) 
                                  : sessions;

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sessions.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemCount: displaySessions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final session = sessions[index];
                                  final subject = (session['subject'] as String?)?.trim().isNotEmpty == true
                                  final session = displaySessions[index];
                                  final subject = (session['subject']
                                                  as String?)
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? (session['subject'] as String).trim()
                                      : 'Session';
                                  final scoreMap = session['score'];
                                  final correct = scoreMap is Map<String, dynamic> ? _readIntFromMap(scoreMap, 'correct') : 0;
                                  final total = scoreMap is Map<String, dynamic> ? _readIntFromMap(scoreMap, 'total') : _readIntFromMap(session, 'total_questions');
                                  final date = _readSessionDate(session['date']);

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: _C.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _C.border),
                                    ),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _C.primaryLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(_subjectIcon(subject), color: _C.primary),
                                      ),
                                      title: Text(
                                        '$subject - $correct/$total - ${_formatActivityDate(date)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: _C.textPrimary, fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        (session['mode'] as String?) ?? 'Practice',
                                        style: const TextStyle(color: _C.textMuted, fontSize: 13),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (isFree) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Upgrade to see complete history and Time-Series charts.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: _C.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _C.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Choose Your Study Mode',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pick how you want to study today: practice, full mock, or global insights from all students.',
                            style: TextStyle(color: _C.textMuted, fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          _ExamModeActionCard(
                            title: 'Subject Practice',
                            description: 'Practice by subject with adaptive question flow.',
                            icon: Icons.book,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SubjectSelectionScreen(selectedGrade: selectedGrade)));
                            },
                          ),
                          const SizedBox(height: 12),
                          _ExamModeActionCard(
                            title: 'Mock Test',
                            description: 'Simulate exam conditions with a timed run.',
                            icon: Icons.fact_check_outlined,
                            isSelected: selectedMode == DashboardStudyMode.mock,
                            onTap: () {
                              if (isFree && mockExamCount >= 1) {
                                UpgradeModal.show(context);
                                return;
                              }

                              if (selectedGrade == null) {
                                ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Select a grade before starting the mock test.')));
                                return;
                              }
                              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MockExamScreen(grade: selectedGrade)));
                            },
                          ),
                          const SizedBox(height: 12),
                          _ExamModeActionCard(
                            title: 'Global Difficulty Report',
                            description: 'See the most failed questions across all students and learn from them.',
                            icon: Icons.public_rounded,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GlobalReportScreen()));
                            },
                          ),
                          if (selectedGrade != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Current grade: $selectedGrade',
                              style: const TextStyle(color: _C.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: _C.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _C.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PlanRow(
                            isFree: isFree,
                            planLabel: planAsync.valueOrNull?.label ?? 'Beginner',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _C.border),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF6FB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.self_improvement_outlined, color: Color(0xFF2A6F97)),
                              ),
                              title: const Text('Wellbeing and Stress Management', style: TextStyle(fontWeight: FontWeight.w600, color: _C.textPrimary, fontSize: 14)),
                              subtitle: const Text('Breathing exercise and proven stress tips', style: TextStyle(color: _C.textMuted, fontSize: 13)),
                              trailing: const Icon(Icons.chevron_right, color: _C.textMuted),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WellbeingStressScreen()));
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _C.border),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _C.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.settings_outlined, color: _C.primary),
                              ),
                              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600, color: _C.textPrimary, fontSize: 14)),
                              subtitle: const Text('Manage app preferences and exam options', style: TextStyle(color: _C.textMuted, fontSize: 13)),
                              trailing: const Icon(Icons.chevron_right, color: _C.textMuted),
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: actionState.isLoading
                                ? null
                                : () async {
                                    final success = await ref.read(authControllerProvider.notifier).signOut();
                                    if (!context.mounted || !success) return;

                                    ref.read(pendingPlanProvider.notifier).state = null;
                                    ref.read(dashboardStudyModeProvider.notifier).state = DashboardStudyMode.practice;
                                    ref.read(gradeDialogShownProvider.notifier).state = <String>{};

                                    ref.invalidate(subscriptionsControllerProvider);
                                    ref.invalidate(userPlanProvider);
                                    ref.invalidate(userProfileStreamProvider);
                                    ref.invalidate(userGradeProvider);
                                    ref.invalidate(gradeSelectionControllerProvider);
                                    ref.invalidate(adaptivePracticeControllerProvider);

                                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()), (route) => false);
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(color: _C.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              foregroundColor: _C.textPrimary,
                            ),
                            icon: actionState.isLoading
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_C.primary)),
                                  )
                                : const Icon(Icons.logout_outlined, size: 20),
                            label: Text(
                              actionState.isLoading ? 'Signing out...' : 'Logout',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (actionState.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              actionState.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
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

  void _scheduleGradeDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        return;
      }

      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) {
        _scheduleGradeDialog(context, ref, currentUserId);
        return;
      }

      final latestGradeAsync = ref.read(userGradeProvider);
      if (!latestGradeAsync.hasValue) {
        return;
      }

      final latestGrade = latestGradeAsync.valueOrNull;
      final stillNeedsGrade = latestGrade == null || latestGrade.trim().isEmpty;
      final alreadyShownForCurrentUser =
          ref.read(gradeDialogShownProvider).contains(currentUserId);

      // Authoritative check from Firestore to prevent showing popup when
      // grade already exists for this account.
      final userDoc = await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(currentUserId)
          .get();

      final data = userDoc.data();
      final profile = data?['profile'];
      final nestedGrade =
          profile is Map<String, dynamic> ? profile['grade'] as String? : null;
      final topLevelGrade = data?['grade'] as String?;
      final firestoreGrade = (nestedGrade ?? topLevelGrade)?.trim();
      final hasFirestoreGrade =
          firestoreGrade != null && firestoreGrade.isNotEmpty;

      if (hasFirestoreGrade) {
        final shownUsers = ref.read(gradeDialogShownProvider);
        ref.read(gradeDialogShownProvider.notifier).state = {
          ...shownUsers,
          currentUserId,
        };
        return;
      }

      if (!stillNeedsGrade || alreadyShownForCurrentUser) {
        return;
      }

      final shownUsers = ref.read(gradeDialogShownProvider);
      ref.read(gradeDialogShownProvider.notifier).state = {
        ...shownUsers,
        currentUserId,
      };
      _showGradeSelectionDialog(context, ref);
    });
  }

  Future<void> _showGradeSelectionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, dialogRef, _) {
            final saveState = dialogRef.watch(gradeSelectionControllerProvider);
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
                                  final saved = await dialogRef
                                      .read(
                                        gradeSelectionControllerProvider
                                            .notifier,
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
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.isFree,
    required this.planLabel,
  });

  final bool isFree;
  final String planLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isFree ? const Color(0xFFE8F0FF) : const Color(0xFFE7F7F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFree ? const Color(0xFFBDD3FF) : const Color(0xFFB2DEC8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              isFree ? Icons.lock_outline : Icons.workspace_premium_outlined,
              color: isFree ? const Color(0xFF1A6BFF) : const Color(0xFF1B7F5B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFree ? 'You’re on the Free plan' : '$planLabel Plan active',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isFree
                        ? const Color(0xFF1A6BFF)
                        : const Color(0xFF1B7F5B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFree
                      ? 'Upgrade to unlock unlimited exams & AI tools.'
                      : 'Full access to all premium features.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isFree)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PlanSelectionScreen(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A6BFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B7F5B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF1B7F5B),
                size: 18,
              ),
            ),
        ],
      ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6BFF), Color(0xFF0F4C81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331A6BFF),
            blurRadius: 20,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back, Student!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your latest progress and learning shortcuts are ready.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 34,
                color: Colors.white,
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
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              icon,
              size: 100,
              color: accentColor.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.15),
                        accentColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 26,
                          color: _C.textPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _C.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkStatCard extends StatelessWidget {
  const _BookmarkStatCard({
    required this.value,
  });

  final String value;

  static const _accentColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BookmarkedQuestionsScreen(),
            ),
          );
        },
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                Icons.bookmark_rounded,
                size: 100,
                color: _accentColor.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _accentColor.withValues(alpha: 0.15),
                          _accentColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: _accentColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 26,
                            color: _C.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Saved Questions',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: _C.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _C.textMuted.withValues(alpha: 0.5),
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
    this.isSelected = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? _C.primaryLight : _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? _C.primary : _C.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected ? _C.primary : _C.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected ? null : Border.all(color: _C.border),
                ),
                child: Icon(icon, color: isSelected ? Colors.white : _C.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? _C.primary : _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: _C.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? _C.primary : _C.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
