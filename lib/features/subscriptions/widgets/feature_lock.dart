import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscriptions_provider.dart';
import 'upgrade_modal.dart';

class FeatureLock extends ConsumerWidget {
  const FeatureLock({
    super.key,
    required this.child,
    this.lockedText = 'Upgrade to Basic to unlock this feature.',
  });

  final Widget child;
  final String lockedText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(userPlanProvider);

    return planAsync.when(
      data: (plan) {
        if (plan != UserPlan.beginner) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.white.withOpacity(0.6),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            lockedText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => UpgradeModal.show(context),
                            icon: const Icon(Icons.star_rounded, color: Colors.orange),
                            label: const Text('Upgrade to Basic'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A6BFF),
                              side: const BorderSide(color: Color(0xFF1A6BFF)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}
