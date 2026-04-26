import 'package:flutter/material.dart';
import 'paywall_screen.dart';

// ─── Standalone test entry ──────────────────────────────────────────────────
void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: PlanSelectionScreen(),
));

class _C {
  static const primary      = Color(0xFF1A6BFF);
  static const primaryLight = Color(0xFFE8F0FF);
  static const bg           = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFF7F8FC);
  static const textPrimary  = Color(0xFF1A1A2E);
  static const textMuted    = Color(0xFF6B7280);
  static const border       = Color(0xFFE0E0E0);
}

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  bool get _isMobile  => false; // replaced at runtime
  bool get _isDesktop => false;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile  = w < 768;
    final isDesktop = w >= 1100;
    final hp        = isDesktop ? 120.0 : (isMobile ? 24.0 : 48.0);

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(child: SingleChildScrollView(
        child: Column(children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            height: 56,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.border))),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chevron_left, color: _C.primary, size: 22),
                  Text("Back", style: TextStyle(color: _C.primary, fontSize: 15,
                    fontWeight: FontWeight.w500)),
                ])),
              const SizedBox(width: 16),
              const Text("Upgrade your plan", style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold, color: _C.textPrimary)),
            ])),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp, vertical: 40),
            child: Column(children: [

              // Hero text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: const Text("You're currently on the Free plan",
                  style: TextStyle(color: _C.primary, fontSize: 13,
                    fontWeight: FontWeight.w600))),
              const SizedBox(height: 16),
              Text("Choose Your Path",
                style: TextStyle(fontSize: isDesktop ? 34 : 26,
                  fontWeight: FontWeight.bold, color: _C.textPrimary),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text("Unlock the full QiyasReady experience.",
                style: TextStyle(fontSize: 15, color: _C.textMuted)),
              const SizedBox(height: 40),

              // Plan cards
              LayoutBuilder(builder: (ctx, c) {
                final cols = c.maxWidth >= 800 ? 3 : 1;
                final cardW = cols == 3 ? (c.maxWidth - 40) / 3 : c.maxWidth;
                return Wrap(spacing: 20, runSpacing: 20, children: [
                  SizedBox(width: cardW, child: _PlanCard(
                    context: context,
                    name: "Beginner",
                    badge: "Current Plan",
                    badgeBg: const Color(0xFFF3F4F6),
                    badgeColor: _C.textMuted,
                    highlighted: false,
                    isCurrent: true,
                    desc: "Your current free plan",
                    features: const [
                      "1 Full Mock Exam",
                      "Limited Practice Questions",
                      "Basic Performance Stats",
                      "Exam Tips & Reminders",
                    ],
                    cta: "Current Plan",
                    ctaEnabled: false,
                  )),
                  SizedBox(width: cardW, child: _PlanCard(
                    context: context,
                    name: "Basic",
                    badge: "Most Popular",
                    badgeBg: _C.primaryLight,
                    badgeColor: _C.primary,
                    highlighted: true,
                    isCurrent: false,
                    desc: "Full access to practice tools and analytics",
                    features: const [
                      "Unlimited Mock Exams",
                      "Practice by Section/Chapter",
                      "Full Performance Analytics",
                      "AI Study Plan",
                      "Step-by-step Answers",
                      "Goal Setting & Reminders",
                    ],
                    cta: "Upgrade to Basic",
                    ctaEnabled: true,
                  )),
                  SizedBox(width: cardW, child: _PlanCard(
                    context: context,
                    name: "Expert",
                    badge: "Best Value",
                    badgeBg: const Color(0xFFFEF3C7),
                    badgeColor: const Color(0xFFD97706),
                    highlighted: false,
                    isCurrent: false,
                    desc: "Maximum prep with AI, offline & more",
                    features: const [
                      "Everything in Basic",
                      "AI Hints (no spoilers)",
                      "Customized Tests",
                      "Offline Mode",
                      "Common Mistakes Report",
                      "Adaptive Fonts & Themes",
                      "Gamification & Leaderboards",
                    ],
                    cta: "Upgrade to Expert",
                    ctaEnabled: true,
                  )),
                ]);
              }),

              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.lock_outline, size: 14, color: _C.textMuted),
                SizedBox(width: 6),
                Text("Cancel anytime · 256-bit SSL encryption",
                  style: TextStyle(fontSize: 13, color: _C.textMuted)),
              ]),
            ]),
          ),
        ]),
      )),
    );
  }
}

// ─── Plan card widget ────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.context,
    required this.name,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    required this.highlighted,
    required this.isCurrent,
    required this.desc,
    required this.features,
    required this.cta,
    required this.ctaEnabled,
  });

  final BuildContext context;
  final String name, badge, desc, cta;
  final Color badgeBg, badgeColor;
  final bool highlighted, isCurrent, ctaEnabled;
  final List<String> features;

  static const _featuresByPlan = {
    'Basic': [
      'Unlimited Mock Exams', 'Practice by Section/Chapter',
      'Full Performance Analytics', 'AI Study Plan',
      'Step-by-step Answers', 'Goal Setting & Reminders',
    ],
    'Expert': [
      'Everything in Basic', 'AI Hints (no spoilers)',
      'Customized Tests', 'Offline Mode',
      'Common Mistakes Report', 'Adaptive Fonts & Themes',
      'Gamification & Leaderboards',
    ],
  };

  void _onUpgrade() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PaywallScreen(
        planName: name,
        planFeatures: _featuresByPlan[name] ?? features,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bg   = highlighted ? _C.primary : _C.surface;
    final tc   = highlighted ? Colors.white : _C.textPrimary;
    final mc   = highlighted ? Colors.white70 : _C.textMuted;
    final ic   = highlighted ? Colors.white : _C.primary;
    final divC = highlighted ? Colors.white24 : _C.border;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? _C.primary : _C.border, width: highlighted ? 2 : 1),
        boxShadow: highlighted
          ? const [BoxShadow(color: Color(0x331A6BFF), blurRadius: 32, offset: Offset(0, 8))]
          : const [BoxShadow(color: Color(0x08000000), blurRadius: 16)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
          child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 12,
            fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tc)),
        const SizedBox(height: 6),
        Text(desc, style: TextStyle(fontSize: 14, color: mc, height: 1.5)),
        const SizedBox(height: 20),
        Divider(color: divC),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Icon(isCurrent ? Icons.check_circle_outline : Icons.check_circle_outline,
              color: isCurrent ? _C.textMuted : ic, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(f, style: TextStyle(fontSize: 13, color: tc))),
          ]))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: ctaEnabled ? _onUpgrade : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: highlighted ? Colors.white : (ctaEnabled ? _C.primary : const Color(0xFFE5E7EB)),
              foregroundColor: highlighted ? _C.primary : (ctaEnabled ? Colors.white : _C.textMuted),
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: _C.textMuted,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            child: Text(cta))),
      ]));
  }
}
