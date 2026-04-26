import 'package:flutter/material.dart';
import '../../auth/screens/sign_in_screen.dart';
import '../../auth/screens/sign_up_screen.dart';
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

// ─── Entry point (for isolated testing) ────────────────────────────────────
void main() => runApp(const MaterialApp(home: WelcomeScreen(), debugShowCheckedModeBanner: false));

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // ── Responsive helpers ──────────────────────────────────────────────────
  bool get _isMobile  => MediaQuery.of(context).size.width < 768;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1200;
  double get _hp => _isDesktop ? 120 : (_isMobile ? 24 : 48);
  double get _maxW => _isDesktop ? 1100 : double.infinity;

  // ── Navigation stubs ────────────────────────────────────────────────────
  void _goSignIn() {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SignInScreen()),
  );
}

void _goSignUp({String? planName}) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => SignUpScreen(redirectToPlan: planName)),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(children: [
        _navbar(),
        Expanded(child: SingleChildScrollView(
          child: Column(children: [
            _hero(),
            _statsBar(),
            _features(),
            _howItWorks(),
            _pricing(),
            _wellbeing(),
            _ctaBanner(),
            _footer(),
          ]),
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NAVBAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _navbar() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: _C.bg,
        border: Border(bottom: BorderSide(color: _C.border))),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxW),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _hp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand
              Row(children: [
                _logoBox(32),
                const SizedBox(width: 10),
                const Text('QiyasReady',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                   color: _C.textPrimary)),
              ]),
              // Buttons
              Row(children: [
                if (!_isMobile)
                  TextButton(
                    onPressed: _goSignIn,
                    style: TextButton.styleFrom(foregroundColor: _C.textPrimary),
                    child: const Text('Log in',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                if (!_isMobile) const SizedBox(width: 8),
                _btn(
                  label: _isMobile ? 'Sign up' : "Sign up — it's free",
                  onTap: _goSignUp,
                  minW: _isMobile ? 80 : 150,
                  h: _isMobile ? 36 : 40,
                  fz: _isMobile ? 13 : 14,
                ),
              ]),
            ],
          ),
        ),
      )),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HERO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _hero() {
    return Container(
      color: _C.surface,
      padding: EdgeInsets.symmetric(horizontal: _hp, vertical: _isDesktop ? 80 : 48),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxW),
        child: _isDesktop
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(flex: 6, child: _heroText()),
              const SizedBox(width: 60),
              Expanded(flex: 5, child: _examCard()),
            ])
          : Column(children: [_heroText(), const SizedBox(height: 40), _examCard()]),
      )),
    );
  }

  Widget _heroText() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _C.primaryLight, borderRadius: BorderRadius.circular(20)),
        child: const Text('🎯  The #1 Qiyas Exam Prep Platform',
          style: TextStyle(color: _C.primary, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: 20),
      Text('Ace the Qiyas Exam\nwith Confidence',
        style: TextStyle(
          fontSize: _isDesktop ? 44 : 32,
          fontWeight: FontWeight.bold,
          color: _C.textPrimary,
          height: 1.2,
        )),
      const SizedBox(height: 16),
      const Text(
        'Realistic mock exams, smart practice sessions, AI-powered study plans '
        'and deep performance analytics — everything you need from free onboarding '
        'to advanced exam mastery.',
        style: TextStyle(fontSize: 16, color: _C.textMuted, height: 1.6)),
      const SizedBox(height: 32),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _btn(label: 'Start Free Today', onTap: _goSignUp, minW: 180, h: 52, fz: 15),
        OutlinedButton(
          onPressed: _goSignIn,
          style: OutlinedButton.styleFrom(
            foregroundColor: _C.primary,
            side: const BorderSide(color: _C.primary),
            minimumSize: const Size(140, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          child: const Text('Log in'),
        ),
      ]),
      const SizedBox(height: 20),
      Row(children: const [
        Icon(Icons.check_circle, color: _C.primary, size: 16),
        SizedBox(width: 6),
        Text('1 free mock exam • No credit card required',
          style: TextStyle(fontSize: 13, color: _C.textMuted)),
      ]),
    ]);
  }

  Widget _examCard() {
    const options = ['A.  255 km', 'B.  285 km', 'C.  300 km', 'D.  315 km'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: const [BoxShadow(
          color: Color(0x1A1A6BFF), blurRadius: 40, offset: Offset(0, 16))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Mock Exam — Section 1',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.primary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEF), borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              Icon(Icons.timer_outlined, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text('45:23', style: TextStyle(fontSize: 13, color: Colors.red,
                                              fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.4,
            backgroundColor: _C.border,
            valueColor: const AlwaysStoppedAnimation(_C.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        const Text('Question 12 of 30',
          style: TextStyle(fontSize: 11, color: _C.textMuted)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surface, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'If a train travels at 90 km/h for 2.5 hours, then slows to 60 km/h '
            'for the next hour, what is the total distance covered?',
            style: TextStyle(fontSize: 14, color: _C.textPrimary, height: 1.5)),
        ),
        const SizedBox(height: 16),
        ...options.asMap().entries.map((e) {
          final sel = e.key == 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: sel ? _C.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: sel ? _C.primary : _C.border, width: sel ? 1.5 : 1)),
            child: Text(e.value,
              style: TextStyle(
                fontSize: 14,
                color: sel ? _C.primary : _C.textPrimary,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
          );
        }),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _statsBar() {
    final items = [
      ('34+',        'Platform Features'),
      ('10s',        'Mock Exams Available'),
      ('3 Tiers',    'Subscription Plans'),
      ('AI-Powered', 'Study Plans & Hints'),
    ];
    return Container(
      color: _C.primary,
      padding: EdgeInsets.symmetric(vertical: 28, horizontal: _hp),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxW),
        child: _isMobile
          ? Column(children: items.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _statItem(s.$1, s.$2))).toList())
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((s) => _statItem(s.$1, s.$2)).toList()),
      )),
    );
  }

  Widget _statItem(String val, String label) => Column(children: [
    Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                                     color: Colors.white)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
  ]);

  // ══════════════════════════════════════════════════════════════════════════
  // FEATURES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _features() {
    return Container(
      color: _C.bg,
      padding: EdgeInsets.symmetric(vertical: _isDesktop ? 80 : 48, horizontal: _hp),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxW),
        child: Column(children: [
          _label('WHAT YOU GET'),
          const SizedBox(height: 12),
          _title('Everything You Need to\nConquer the Qiyas'),
          const SizedBox(height: 48),
          LayoutBuilder(builder: (ctx, c) {
            final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
            final w = (c.maxWidth - (cols - 1) * 20) / cols;
            final cards = [
              _fCard(Icons.assignment_outlined, const Color(0xFF1A6BFF),
                const Color(0xFFE8F0FF), 'Realistic Mock Exams',
                'Access dozens of full mock exams that simulate the real Qiyas — '
                'same questions, sections, timing and breaks. No pausing, no retakes.'),
              _fCard(Icons.school_outlined, const Color(0xFF10B981),
                const Color(0xFFD1FAE5), 'Practice by Section',
                'Train at your own pace per chapter, section or lesson. '
                'Each question is timed to 1 min — matching real exam pressure.'),
              _fCard(Icons.bar_chart_rounded, const Color(0xFF8B5CF6),
                const Color(0xFFEDE9FE), 'Deep Performance Analytics',
                'Full accuracy and duration analysis per exam and section. '
                'Track your improvement over days and weeks.'),
              _fCard(Icons.auto_awesome_outlined, const Color(0xFFF59E0B),
                const Color(0xFFFEF3C7), 'AI-Powered Study Plan',
                'The platform reads your performance and time remaining, then '
                'generates a personalized study plan with targets and deadlines.'),
              _fCard(Icons.tune_outlined, const Color(0xFFEF4444),
                const Color(0xFFFEE2E2), 'Customized Tests',
                'Build your own practice exams — choose number of questions, '
                'chapters and sections. Your test, your rules.'),
              _fCard(Icons.wifi_off_outlined, const Color(0xFF06B6D4),
                const Color(0xFFCFFAFE), 'Offline Mode',
                'Download mock exams or practice questions and study anywhere — '
                'no internet connection required. Perfect for travel.'),
            ];
            return Wrap(spacing: 20, runSpacing: 20,
              children: cards.map((c) => SizedBox(width: w, child: c)).toList());
          }),
        ]),
      )),
    );
  }

  Widget _fCard(IconData icon, Color ic, Color ibg, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16,
                                    offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: ibg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: ic, size: 24)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                            color: _C.textPrimary)),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(fontSize: 14, color: _C.textMuted, height: 1.6)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HOW IT WORKS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _howItWorks() {
    return Container(
      color: _C.surface,
      padding: EdgeInsets.symmetric(vertical: _isDesktop ? 80 : 48, horizontal: _hp),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxW),
        child: Column(children: [
          _label('HOW IT WORKS'),
          const SizedBox(height: 12),
          _title('Your Journey to\nQiyas Success'),
          const SizedBox(height: 48),
          _isMobile
            ? Column(children: _steps())
            : Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: _steps().map((s) => Expanded(child: s)).toList()),
        ]),
      )),
    );
  }

  List<Widget> _steps() => [
    _step('1', 'Sign Up Free',
      'Create your account in seconds. Get instant access to 1 free full mock exam '
      'and limited practice questions — no credit card needed.',
      Icons.person_add_outlined),
    _step('2', 'Practice & Analyze',
      'Take mock exams, practice by section, and review step-by-step answer '
      'explanations. Track your accuracy and improvement over time.',
      Icons.insights_outlined),
    _step('3', 'Upgrade & Master',
      'Subscribe to Beginner, Basic, or Expert plans to unlock unlimited exams, '
      'AI study plans, offline mode, hints, and much more.',
      Icons.emoji_events_outlined),
  ];

  Widget _step(String num, String title, String desc, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: _isMobile ? 16 : 0),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          Container(width: 64, height: 64,
            decoration: const BoxDecoration(
              color: _C.primaryLight, shape: BoxShape.circle)),
          Icon(icon, color: _C.primary, size: 28),
          Positioned(top: 0, right: 0,
            child: Container(width: 22, height: 22,
              decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle),
              child: Center(child: Text(num,
                style: const TextStyle(color: Colors.white, fontSize: 12,
                                        fontWeight: FontWeight.bold))))),
        ]),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                                            color: _C.textPrimary),
             textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(fontSize: 14, color: _C.textMuted, height: 1.6),
             textAlign: TextAlign.center),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRICING
  // ══════════════════════════════════════════════════════════════════════════
  Widget _pricing() {
    return Container(
      color: _C.bg,
      padding: EdgeInsets.symmetric(vertical: _isDesktop ? 80 : 48, horizontal: _hp),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxW),
        child: Column(children: [
          _label('PRICING'),
          const SizedBox(height: 12),
          _title('Choose Your Path'),
          const SizedBox(height: 8),
          const Text('Start free. Upgrade when you\'re ready.',
            style: TextStyle(fontSize: 15, color: _C.textMuted)),
          const SizedBox(height: 48),
          LayoutBuilder(builder: (ctx, c) {
            final cols = c.maxWidth >= 800 ? 3 : 1;
            final w = cols == 3
              ? (c.maxWidth - 40) / 3
              : c.maxWidth;
            return Wrap(spacing: 20, runSpacing: 20, children: [
              SizedBox(width: w, child: _planCard(
                name: 'Beginner', badge: null, highlighted: false,
                desc: 'Explore the platform and test your starting level',
                features: const ['1 Full Mock Exam', 'Limited Practice Questions',
                  'Basic Performance Stats', 'Exam Tips & Reminders'],
                cta: 'Start Free',
              )),
              SizedBox(width: w, child: _planCard(
                name: 'Basic', badge: 'Most Popular', highlighted: true,
                desc: 'Full access to practice tools and performance tracking',
                features: const ['Unlimited Mock Exams', 'Practice by Section/Chapter',
                  'Full Performance Analytics', 'AI Study Plan',
                  'Step-by-step Answers', 'Goal Setting & Reminders'],
                cta: 'Get Basic',
              )),
              SizedBox(width: w, child: _planCard(
                name: 'Expert', badge: null, highlighted: false,
                desc: 'Maximum preparation with AI, offline mode, and more',
                features: const ['Everything in Basic', 'AI Hints (no spoilers)',
                  'Customized Tests', 'Offline Mode', 'Common Mistakes Report',
                  'Adaptive Fonts & Themes', 'Gamification & Leaderboards'],
                cta: 'Go Expert',
              )),
            ]);
          }),
        ]),
      )),
    );
  }

  Widget _planCard({
    required String name,
    required String? badge,
    required bool highlighted,
    required String desc,
    required List<String> features,
    required String cta,
  }) {
    final bg    = highlighted ? _C.primary : _C.cardBg;
    final tc    = highlighted ? Colors.white : _C.textPrimary;
    final mc    = highlighted ? Colors.white70 : _C.textMuted;
    final ic    = highlighted ? Colors.white : _C.primary;
    final divC  = highlighted ? Colors.white24 : _C.border;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? _C.primary : _C.border, width: highlighted ? 2 : 1),
        boxShadow: highlighted
          ? const [BoxShadow(color: Color(0x331A6BFF), blurRadius: 32, offset: Offset(0, 8))]
          : const [BoxShadow(color: Color(0x08000000), blurRadius: 16)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (badge != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: highlighted ? Colors.white24 : _C.primaryLight,
              borderRadius: BorderRadius.circular(20)),
            child: Text(badge,
              style: TextStyle(color: ic, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
        Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tc)),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(fontSize: 14, color: mc, height: 1.5)),
        const SizedBox(height: 24),
        Divider(color: divC),
        const SizedBox(height: 20),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: ic, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(f, style: TextStyle(fontSize: 14, color: tc))),
          ]),
        )),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: name == 'Beginner' 
              ? () => _goSignUp() 
              : () => _goSignUp(planName: name),
            style: ElevatedButton.styleFrom(
              backgroundColor: highlighted ? Colors.white : _C.primary,
              foregroundColor: highlighted ? _C.primary : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            child: Text(cta),
          )),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WELLBEING
  // ══════════════════════════════════════════════════════════════════════════
  Widget _wellbeing() {
    return Container(
      color: _C.surface,
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: _hp),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxW),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F0FF), Color(0xFFF0FDF4)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.border),
          ),
          child: _isMobile
            ? _wellbeingText()
            : Row(children: [
                Expanded(child: _wellbeingText()),
                const SizedBox(width: 32),
                _wellbeingBadges(),
              ]),
        ),
      )),
    );
  }

  Widget _wellbeingText() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('🧘  Wellbeing & Stress Management',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.primary)),
    const SizedBox(height: 12),
    const Text('Your mental health matters.',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.textPrimary)),
    const SizedBox(height: 8),
    const Text(
      'QiyasReady includes built-in wellbeing tools — breathing exercises, '
      'exam stress tips, and psychology-backed strategies to keep you focused '
      'and calm before and during the exam.',
      style: TextStyle(fontSize: 14, color: _C.textMuted, height: 1.6)),
  ]);

  Widget _wellbeingBadges() => Row(mainAxisSize: MainAxisSize.min, children: [
    _badge('🧠', 'Focus'), const SizedBox(width: 16),
    _badge('🌬️', 'Breathe'), const SizedBox(width: 16),
    _badge('💪', 'Confidence'),
  ]);

  Widget _badge(String e, String l) => Column(children: [
    Text(e, style: const TextStyle(fontSize: 32)),
    const SizedBox(height: 6),
    Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: _C.textMuted)),
  ]);

  // ══════════════════════════════════════════════════════════════════════════
  // CTA BANNER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _ctaBanner() {
    return Container(
      color: _C.primary,
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: _hp),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(children: [
          Text('Ready to Start Your\nQiyas Journey?',
            style: TextStyle(fontSize: _isDesktop ? 36 : 26,
                             fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of students preparing smarter with QiyasReady. '
            'Your first mock exam is completely free.',
            style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _goSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _C.primary,
              minimumSize: const Size(200, 52),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            child: const Text('Create Free Account'),
          ),
        ]),
      )),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _footer() {
    return Container(
      color: _C.dark,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: _hp),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxW),
        child: _isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _footerBrand(), const SizedBox(height: 24),
              _footerLinks(), const SizedBox(height: 24),
              _footerCopy(),
            ])
          : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [_footerBrand(), _footerLinks(), _footerCopy()]),
      )),
    );
  }

  Widget _footerBrand() => Row(mainAxisSize: MainAxisSize.min, children: [
    _logoBox(28),
    const SizedBox(width: 8),
    const Text('QiyasReady',
      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
  ]);

  Widget _footerLinks() => Wrap(spacing: 24, children: [
    _footerLink('Terms of Service'),
    _footerLink('Privacy Policy'),
    _footerLink('Contact Us'),
  ]);

  Widget _footerLink(String t) => GestureDetector(
    onTap: () {},
    child: Text(t, style: const TextStyle(color: Colors.white60, fontSize: 13)));

  Widget _footerCopy() => const Text('© 2026 QiyasReady. All rights reserved.',
    style: TextStyle(color: Colors.white38, fontSize: 12));

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _logoBox(double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: _C.primary, borderRadius: BorderRadius.circular(6)),
    child: Center(child: Text('Q',
      style: TextStyle(color: Colors.white,
                        fontSize: size * 0.55, fontWeight: FontWeight.bold))));

  Widget _label(String t) => Text(t,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            letterSpacing: 1.2, color: _C.primary),
    textAlign: TextAlign.center);

  Widget _title(String t) => Text(t,
    style: TextStyle(fontSize: _isDesktop ? 34 : 26, fontWeight: FontWeight.bold,
                     color: _C.textPrimary, height: 1.25),
    textAlign: TextAlign.center);

  Widget _btn({
    required String label,
    required VoidCallback onTap,
    double minW = 100,
    double h = 44,
    double fz = 14,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(minW, h),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(fontSize: fz, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }
}
