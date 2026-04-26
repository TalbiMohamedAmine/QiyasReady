  // ─── Upgrade banner widget ──────────────────────────────────────────────────
// Add this widget at the TOP of ProfileDashboardScreen's body,
// shown only when the user is on the Beginner (free) plan.
//
// File: lib/shared/widgets/upgrade_banner.dart

import 'package:flutter/material.dart';
import '../../features/subscriptions/screens/plan_selection_screen.dart';

class UpgradeBanner extends StatelessWidget {
  const UpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6BFF), Color(0xFF4F8EFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(
          color: Color(0x221A6BFF), blurRadius: 12, offset: Offset(0, 4))]),
      child: Row(children: [
        const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("You're on the Free plan",
              style: TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text("Upgrade to unlock unlimited exams & AI tools.",
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PlanSelectionScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8)),
            child: const Text("Upgrade",
              style: TextStyle(color: Color(0xFF1A6BFF), fontSize: 13,
                fontWeight: FontWeight.bold)))),
      ]));
  }
}
