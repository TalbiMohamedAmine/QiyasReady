import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../practice/services/ai_tutor_service.dart';
import '../models/global_mistake.dart';
import '../repositories/global_analytics_service.dart';

class GlobalReportScreen extends ConsumerStatefulWidget {
  const GlobalReportScreen({super.key});

  @override
  ConsumerState<GlobalReportScreen> createState() => _GlobalReportScreenState();
}

class _GlobalReportScreenState extends ConsumerState<GlobalReportScreen> {
  final GlobalAnalyticsService _service = GlobalAnalyticsService();

  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _hasPurchased = false;
  String? _errorMessage;
  String _selectedSubject = 'All';
  List<GlobalMistake> _allMistakes = const [];
  final Map<String, String> _aiByQuestionId = <String, String>{};
  String? _loadingAiQuestionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Please sign in to access the global report.');
      }

      final hasPurchased = await _service.hasPurchasedReport(user.uid);
      final mistakes = await _service.fetchGlobalMistakes(maxItems: 200);

      if (!mounted) {
        return;
      }

      setState(() {
        _hasPurchased = hasPurchased;
        _allMistakes = mistakes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load global insights right now.';
      });
      debugPrint('GlobalReportScreen._loadData error: $error');
    }
  }

  Future<void> _purchaseReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
              content: Text('Please sign in to purchase the report.')),
        );
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    try {
      await _service.purchaseReport(user.uid);
      if (!mounted) {
        return;
      }

      setState(() {
        _hasPurchased = true;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Global report unlocked. You now have full access.'),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to purchase report right now.')),
        );
      debugPrint('GlobalReportScreen._purchaseReport error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  Future<void> _explainWithAi(GlobalMistake mistake) async {
    if (!mistake.hasAiInputs) {
      return;
    }

    setState(() {
      _loadingAiQuestionId = mistake.questionId;
      _aiByQuestionId.remove(mistake.questionId);
    });

    try {
      final explanation = await ref.read(aiTutorProvider).generateExplanation(
            questionText: mistake.questionText,
            correctAnswer: mistake.correctAnswer,
            userAnswer: mistake.popularWrongAnswer,
            grade: 'Grade 10',
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _aiByQuestionId[mistake.questionId] = explanation;
      });
    } on AITutorFailure catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('AI Tutor is temporarily unavailable.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loadingAiQuestionId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Common Mistakes (All Students)'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'See what students are getting wrong the most across the entire platform.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 14),
                        _buildSubjectFilterChips(colorScheme),
                        const SizedBox(height: 14),
                        _buildPaywallCard(colorScheme),
                        const SizedBox(height: 14),
                        ..._buildMistakeCards(
                          colorScheme: colorScheme,
                          mistakes: _filteredMistakes,
                          locked: !_hasPurchased,
                        ),
                        if (_filteredMistakes.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                'No global mistakes found for this subject yet.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  List<GlobalMistake> get _filteredMistakes {
    if (_selectedSubject == 'All') {
      return _allMistakes;
    }

    final target = _selectedSubject.toLowerCase();
    return _allMistakes
        .where((item) => item.subject.toLowerCase() == target)
        .toList(growable: false);
  }

  Widget _buildSubjectFilterChips(ColorScheme colorScheme) {
    final subjects = <String>{'All'};
    for (final mistake in _allMistakes) {
      if (mistake.subject.trim().isNotEmpty) {
        subjects.add(mistake.subject);
      }
    }

    final sorted = subjects.toList()..sort();
    if (sorted.remove('All')) {
      sorted.insert(0, 'All');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sorted
          .map(
            (subject) => ChoiceChip(
              label: Text(subject),
              selected: _selectedSubject == subject,
              onSelected: (_) {
                setState(() {
                  _selectedSubject = subject;
                });
              },
              selectedColor: colorScheme.primaryContainer,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildPaywallCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_outlined),
                const SizedBox(width: 8),
                Text(
                  _hasPurchased
                      ? 'Full Global Report Unlocked'
                      : 'Purchase Full Report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _hasPurchased
                  ? 'You can now view every high-failure question and use AI Tutor for each one.'
                  : 'Free users can only see a locked Top 5 preview. Unlock all insights for the full national difficulty report.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  _hasPurchased || _isPurchasing ? null : _purchaseReport,
              icon: _isPurchasing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_hasPurchased ? Icons.check_rounded : Icons.lock_open),
              label: Text(
                _hasPurchased
                    ? 'Purchased'
                    : (_isPurchasing
                        ? 'Processing...'
                        : 'Purchase Full Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMistakeCards({
    required ColorScheme colorScheme,
    required List<GlobalMistake> mistakes,
    required bool locked,
  }) {
    final visible = locked
        ? mistakes.take(5).toList(growable: false)
        : mistakes.toList(growable: false);

    return visible.map((mistake) {
      final aiExplanation = _aiByQuestionId[mistake.questionId];
      final isLoadingAi = _loadingAiQuestionId == mistake.questionId;

      final card = Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mistake.subject,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Text(
                    '${mistake.failureRate.toStringAsFixed(1)}% fail',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Attempts: ${mistake.totalAttempts}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                mistake.questionText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Correct answer: ${mistake.correctAnswer.isEmpty ? '--' : mistake.correctAnswer}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Most common wrong answer: ${mistake.popularWrongAnswer.isEmpty ? '--' : mistake.popularWrongAnswer}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                mistake.staticExplanation.isEmpty
                    ? 'No explanation available.'
                    : mistake.staticExplanation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: !mistake.hasAiInputs || isLoadingAi
                    ? null
                    : () => _explainWithAi(mistake),
                icon: isLoadingAi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(isLoadingAi ? 'Generating...' : 'Explain with AI'),
              ),
              if (aiExplanation != null && aiExplanation.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    aiExplanation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

      if (!locked) {
        return card;
      }

      return Stack(
        children: [
          card,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Locked Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }).toList(growable: false);
  }
}
