import 'dart:async';

import 'package:flutter/material.dart';

class WellbeingStressScreen extends StatelessWidget {
  const WellbeingStressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellbeing and Stress Management'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IntroCard(colorScheme: colorScheme),
              const SizedBox(height: 16),
              const _BreathingExerciseCard(),
              const SizedBox(height: 16),
              const _TipCard(
                title: '1) Name what you feel',
                subtitle:
                    'Psychology research shows that labeling emotions lowers their intensity.',
                tips: [
                  'Use a simple sentence: "I am feeling overwhelmed because..."',
                  'Rate your stress from 0 to 10 to make it concrete.',
                  'Pick one small next action for the next 10 minutes.',
                ],
                icon: Icons.psychology_outlined,
                accentColor: Color(0xFF0F4C81),
                backgroundColor: Color(0xFFEAF3FF),
              ),
              const SizedBox(height: 12),
              const _TipCard(
                title: '2) Break the pressure cycle',
                subtitle:
                    'Stress reduces focus when tasks feel vague or too large.',
                tips: [
                  'Turn one big topic into a 25-minute mini-session.',
                  'After each session, take a 5-minute movement break.',
                  'Write one sentence about what you learned to close the loop.',
                ],
                icon: Icons.task_alt_outlined,
                accentColor: Color(0xFF1B7F5B),
                backgroundColor: Color(0xFFE7F7F0),
              ),
              const SizedBox(height: 12),
              const _TipCard(
                title: '3) Protect your energy daily',
                subtitle:
                    'Consistent sleep, hydration, and social support improve resilience.',
                tips: [
                  'Aim for regular sleep and wake times before exam weeks.',
                  'Drink water and avoid too much caffeine late in the day.',
                  'Talk to a trusted person when stress stays high for many days.',
                ],
                icon: Icons.favorite_outline,
                accentColor: Color(0xFF8A5A00),
                backgroundColor: Color(0xFFFFF4DC),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
                  child: Text(
                    'If stress starts affecting your sleep, mood, or daily life for more than two weeks, consider talking to a school counselor, a parent, or a mental health professional.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
  const _IntroCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF2A6F97)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.self_improvement_outlined,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Calm mind, stronger focus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Use these evidence-based tools before studying, after a hard session, or anytime stress rises.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
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
    if (_isRunning) {
      return;
    }

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guided Breathing (4-4-6-2)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Breathe slowly for 2 to 4 minutes to lower physical stress signals.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _currentPhase.icon,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPhase.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_secondsRemaining sec remaining',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Cycle $_cycleCount',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isRunning ? _pause : _start,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pause' : 'Start'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
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
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle, size: 7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium,
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
