import 'package:flutter/material.dart';

import 'practice_engine_screen.dart';

class SubjectSelectionScreen extends StatelessWidget {
  const SubjectSelectionScreen({
    super.key,
    this.selectedGrade,
  });

  final String? selectedGrade;

  static const _subjects = <_SubjectOption>[
    _SubjectOption(
      title: 'Arithmetic',
      subtitle: 'Numbers, operations, and quantitative practice',
      icon: Icons.calculate_rounded,
      chapterId: 'quantitative',
      lessonId: 'arithmetic',
    ),
    _SubjectOption(
      title: 'Analogy',
      subtitle: 'Word relationship and pattern matching',
      icon: Icons.hub_outlined,
      chapterId: 'verbal',
      lessonId: 'analogy',
    ),
    _SubjectOption(
      title: 'Completion',
      subtitle: 'Sentence completion and vocabulary context',
      icon: Icons.short_text_rounded,
      chapterId: 'verbal',
      lessonId: 'completion',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Select Subject'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return GridView.builder(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 2 : 1,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: isWide ? 1.8 : 2.0,
              ),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                return _SubjectCard(
                  subject: subject,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PracticeEngineScreen(
                          selectedSubject: subject.title,
                          chapterId: subject.chapterId,
                          lessonId: subject.lessonId,
                          selectedGrade: selectedGrade,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubjectOption {
  const _SubjectOption({
    required this.title,
    required this.subtitle,
    required this.chapterId,
    required this.lessonId,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String chapterId;
  final String lessonId;
  final IconData icon;
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.onTap,
  });

  final _SubjectOption subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(subject.icon, color: colorScheme.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subject.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
