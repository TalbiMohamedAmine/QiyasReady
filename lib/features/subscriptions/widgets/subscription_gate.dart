import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscriptions_provider.dart';

class SubscriptionGate extends ConsumerWidget {
  const SubscriptionGate({
    super.key,
    required this.allowedPlans,
    required this.child,
    required this.fallback,
  });

  final List<UserPlan> allowedPlans;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(userPlanProvider);

    return planAsync.when(
      data: (plan) {
        if (allowedPlans.contains(plan)) {
          return child;
        }
        return fallback;
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => fallback,
    );
  }
}
