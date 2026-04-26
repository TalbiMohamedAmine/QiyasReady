// ─── Plan state provider ────────────────────────────────────────────────────
// File: lib/features/subscriptions/providers/subscriptions_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

// ════════════════════════════════════════════════════════════════════════════
// Plan enum
// ════════════════════════════════════════════════════════════════════════════
enum UserPlan { beginner, basic, expert }

extension UserPlanX on UserPlan {
  String get label => name[0].toUpperCase() + name.substring(1);
  bool get isFree  => this == UserPlan.beginner;
}

// ════════════════════════════════════════════════════════════════════════════
// SubscriptionsState  —  consumed by PaywallScreen
// ════════════════════════════════════════════════════════════════════════════
class SubscriptionsState {
  const SubscriptionsState({
    this.isLoading    = false,
    this.isSuccess    = false,
    this.errorMessage,
    this.activePlan,
  });

  final bool     isLoading;
  final bool     isSuccess;
  final String?  errorMessage;
  final UserPlan? activePlan;

  SubscriptionsState copyWith({
    bool?     isLoading,
    bool?     isSuccess,
    String?   errorMessage,
    UserPlan? activePlan,
    bool      clearError = false,
  }) {
    return SubscriptionsState(
      isLoading:    isLoading    ?? this.isLoading,
      isSuccess:    isSuccess    ?? this.isSuccess,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activePlan:   activePlan   ?? this.activePlan,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SubscriptionsController
// ════════════════════════════════════════════════════════════════════════════
class SubscriptionsController
    extends StateNotifier<SubscriptionsState> {
  SubscriptionsController(this._ref) : super(const SubscriptionsState());

  final Ref _ref;

  /// Called from PaywallScreen after payment is confirmed.
  /// Writes the plan to Firestore and updates local state.
  Future<bool> assignPlan(String planName) async {
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      clearError: true,
    );

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You must be signed in to subscribe.',
        );
        return false;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'user_tier': planName.toLowerCase()}, SetOptions(merge: true));

      final assignedPlan = UserPlan.values.firstWhere(
        (p) => p.name == planName.toLowerCase(),
        orElse: () => UserPlan.beginner,
      );

      state = state.copyWith(
        isLoading:  false,
        isSuccess:  true,
        activePlan: assignedPlan,
        clearError: true,
      );

      // Invalidate the stream so _ProfileDashboardScreen re-reads the plan
      _ref.invalidate(userPlanProvider);

      return true;
    } on FirebaseException catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.message ?? 'Firestore error. Please try again.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  /// Resets success/error banners without changing the plan.
  void clearStatus() {
    state = state.copyWith(
      isSuccess:  false,
      clearError: true,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Providers
// ════════════════════════════════════════════════════════════════════════════

/// Controller provider — used by PaywallScreen for write operations.
final subscriptionsControllerProvider =
    StateNotifierProvider<SubscriptionsController, SubscriptionsState>(
  (ref) => SubscriptionsController(ref),
);

/// Stream provider — used by ProfileDashboardScreen to read the current plan.
final userPlanProvider = StreamProvider<UserPlan>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      final uid = user?.uid;
      if (uid == null) {
        return Stream.value(UserPlan.beginner);
      }

      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .map((snap) {
        final planStr = snap.data()?['user_tier'] as String? ?? 'beginner';
        return UserPlan.values.firstWhere(
          (p) => p.name == planStr,
          orElse: () => UserPlan.beginner,
        );
      });
    },
    loading: () => const Stream<UserPlan>.empty(),
    error: (_, __) => const Stream<UserPlan>.empty(),
  );
});

// ════════════════════════════════════════════════════════════════════════════
// Standalone write helpers  (for use outside Riverpod widgets, e.g. auth flow)
// ════════════════════════════════════════════════════════════════════════════

/// Assigns a plan directly — use only from non-widget code (e.g. auth_service).
Future<void> assignPlanDirect(String planName) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .set({'user_tier': planName.toLowerCase()}, SetOptions(merge: true));
}
// Stores the plan the user tapped before signing up (null = no pending plan)
final pendingPlanProvider = StateProvider<String?>((ref) => null);
/// Sets the default plan to 'beginner' right after sign-up.
Future<void> assignDefaultPlan() => assignPlanDirect('beginner');
