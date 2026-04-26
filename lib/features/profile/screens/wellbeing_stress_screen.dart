import 'dart:async';

import 'package:flutter/material.dart';

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
}

class WellbeingStressScreen extends StatelessWidget {
  const WellbeingStressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        title: const Text(
          'Wellbeing & Stress',
          style: TextStyle(
            color: _C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _C.bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _C.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _C.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _IntroCard(),
              const SizedBox(height: 24),
              const _BreathingExerciseCard(),
              const SizedBox(height: 24),
              const Text(
                'Practical Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const _TipCard(
                title: 'Name what you feel',
                subtitle:
                    'Psychology research shows that labeling emotions lowers their intensity.',
                tips: [
                  'Use a simple sentence: "I am feeling overwhelmed because..."',
                  'Rate your stress from 0 to 10 to make it concrete.',
                  'Pick one small next action for the next 10 minutes.',
                ],
                icon: Icons.psychology_outlined,
                accentColor: Color(0xFF1A6BFF),
                backgroundColor: Color(0xFFE8F0FF),
              ),
              const SizedBox(height: 16),
              const _TipCard(
                title: 'Break the pressure cycle',
                subtitle:
                    'Stress reduces focus when tasks feel vague or too large.',
                tips: [
                  'Turn one big topic into a 25-minute mini-session.',
                  'After each session, take a 5-minute movement break.',
                  'Write one sentence about what you learned to close the loop.',
                ],
                icon: Icons.task_alt_outlined,
                accentColor: Color(0xFF10B981),
                backgroundColor: Color(0xFFD1FAE5),
              ),
              const SizedBox(height: 16),
              const _TipCard(
                title: 'Protect your energy daily',
                subtitle:
                    'Consistent sleep, hydration, and social support improve resilience.',
                tips: [
                  'Aim for regular sleep and wake times before exam weeks.',
                  'Drink water and avoid too much caffeine late in the day.',
                  'Talk to a trusted person when stress stays high for many days.',
                ],
                icon: Icons.favorite_outline,
                accentColor: Color(0xFFF59E0B),
                backgroundColor: Color(0xFFFEF3C7),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: _C.textMuted, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'If stress starts affecting your sleep, mood, or daily life for more than two weeks, consider talking to a school counselor, a parent, or a mental health professional.',
                        style: TextStyle(
                          fontSize: 14,
                          color: _C.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F0FF), Color(0xFFF0FDF4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.self_improvement_outlined,
                    color: _C.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Calm mind, stronger focus',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _C.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Use these evidence-based tools before studying, after a hard session, or anytime stress rises.',
              style: TextStyle(
                fontSize: 15,
                color: _C.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingExerciseCard extends StatefulWidget {
  const _BreathingExerciseCard();

  @override
  State<_BreathingExerciseCard> createState() => _BreathingExerciseCardState();
}

class _BreathingExerciseCardState extends State<_BreathingExerciseCard> {
  static const List<_BreathingPhase> _phases = [
    _BreathingPhase(label: 'Inhale', seconds: 4, icon: Icons.south),
    _BreathingPhase(label: 'Hold', seconds: 4, icon: Icons.pause),
    _BreathingPhase(label: 'Exhale', seconds: 6, icon: Icons.north),
    _BreathingPhase(label: 'Pause', seconds: 2, icon: Icons.air),
  ];

  Timer? _timer;
  int _phaseIndex = 0;
  int _secondsRemaining = _phases.first.seconds;
  int _cycleCount = 0;
  bool _isRunning = false;

  _BreathingPhase get _currentPhase => _phases[_phaseIndex];

  void _start() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining -= 1;
          return;
        }

        _phaseIndex = (_phaseIndex + 1) % _phases.length;
        _secondsRemaining = _phases[_phaseIndex].seconds;

        if (_phaseIndex == 0) {
          _cycleCount += 1;
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _phaseIndex = 0;
      _secondsRemaining = _phases.first.seconds;
      _cycleCount = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guided Breathing (4-4-6-2)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Breathe slowly for 2 to 4 minutes to lower physical stress signals.',
              style: TextStyle(
                fontSize: 14,
                color: _C.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _C.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _currentPhase.icon,
                      color: _C.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPhase.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _C.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_secondsRemaining sec remaining',
                          style: const TextStyle(
                            fontSize: 14,
                            color: _C.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.border),
                    ),
                    child: Text(
                      'Cycle $_cycleCount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? _pause : _start,
                    icon: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    label: Text(
                      _isRunning ? 'Pause' : 'Start',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? _C.bg : _C.primary,
                      foregroundColor: _isRunning ? _C.textPrimary : Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: _isRunning
                            ? const BorderSide(color: _C.border)
                            : BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.textPrimary,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    side: const BorderSide(color: _C.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.subtitle,
    required this.tips,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String title;
  final String subtitle;
  final List<String> tips;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _C.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: _C.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _C.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _BreathingPhase {
  const _BreathingPhase({
    required this.label,
    required this.seconds,
    required this.icon,
  });

  final String label;
  final int seconds;
  final IconData icon;
}
