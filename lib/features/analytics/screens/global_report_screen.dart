import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/exam_security_service.dart';
import '../../../core/security/security_overlay.dart';
import '../../practice/services/ai_tutor_service.dart';
import '../models/global_mistake.dart';
import '../repositories/global_analytics_service.dart';
import '../../subscriptions/widgets/feature_lock.dart';

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
    // Enable screen protection for report security
    ExamSecurityService.instance.enableProtection();
    _loadData();
  }

  @override
  void dispose() {
    // Disable screen protection when leaving report
    ExamSecurityService.instance.disableProtection();
    super.dispose();
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
            isCorrect: false,
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
    return SecurityOverlay(
      child: SecureShortcutBlocker(
        child: Scaffold(
          backgroundColor: _C.surface,
          appBar: AppBar(
            title: const Text(
              'Global Mistakes',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _C.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : FeatureLock(
                        lockedText: 'Upgrade to Basic to access the Common Mistakes Report.',
                        child: RefreshIndicator(
                          onRefresh: _loadData,
                          child: SecureContentWrapper(
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: _C.primary,
                        child: SecureContentWrapper(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            children: [
                              const Text(
                                'Global Difficulty Insights',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _C.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'See what students are getting wrong the most across the entire platform. Learn from common pitfalls.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _C.textMuted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSubjectFilterChips(),
                              const SizedBox(height: 24),
                              _buildPaywallCard(),
                              const SizedBox(height: 24),
                              ..._buildMistakeCards(
                                mistakes: _filteredMistakes,
                                locked: !_hasPurchased,
                              ),
                              if (_filteredMistakes.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: _C.cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _C.border),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No global mistakes found for this subject yet.',
                                      style: TextStyle(fontSize: 15, color: _C.textMuted),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildSubjectFilterChips() {
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sorted.map((subject) {
          final isSelected = _selectedSubject == subject;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(subject),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedSubject = subject;
                });
              },
              backgroundColor: _C.bg,
              selectedColor: _C.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? _C.primary : _C.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _C.primary : _C.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaywallCard() {
    return Container(
      decoration: BoxDecoration(
        color: _hasPurchased ? _C.primaryLight : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasPurchased ? _C.primary : const Color(0xFFF97316),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  color: _hasPurchased ? _C.primary : const Color(0xFFF97316),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hasPurchased ? 'Full Global Report Unlocked' : 'Purchase Full Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _hasPurchased ? _C.primary : const Color(0xFFC2410C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _hasPurchased
                  ? 'You can now view every high-failure question and use AI Tutor for each one.'
                  : 'Free users can only see a locked Top 5 preview. Unlock all insights for the full national difficulty report.',
              style: TextStyle(
                fontSize: 14,
                color: _hasPurchased ? _C.textPrimary : const Color(0xFF9A3412),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (!_hasPurchased)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPurchasing ? null : _purchaseReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isPurchasing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.lock_open, size: 20),
                  label: Text(
                    _isPurchasing ? 'Processing...' : 'Unlock Full Report',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMistakeCards({
    required List<GlobalMistake> mistakes,
    required bool locked,
  }) {
    final visible = locked
        ? mistakes.take(5).toList(growable: false)
        : mistakes.toList(growable: false);

    return visible.map((mistake) {
      final aiExplanation = _aiByQuestionId[mistake.questionId];
      final isLoadingAi = _loadingAiQuestionId == mistake.questionId;

      final card = Container(
        margin: const EdgeInsets.only(bottom: 20),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mistake.subject,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _C.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${mistake.failureRate.toStringAsFixed(1)}% fail',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                mistake.questionText,
                style: const TextStyle(
                  fontSize: 16,
                  color: _C.textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Column(
                  children: [
                    _buildAnswerRow(
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF10B981),
                      label: 'Correct answer',
                      value: mistake.correctAnswer.isEmpty ? '--' : mistake.correctAnswer,
                    ),
                    const Divider(height: 24, color: _C.border),
                    _buildAnswerRow(
                      icon: Icons.cancel,
                      iconColor: const Color(0xFFEF4444),
                      label: 'Common wrong answer',
                      value: mistake.popularWrongAnswer.isEmpty ? '--' : mistake.popularWrongAnswer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (mistake.staticExplanation.isNotEmpty) ...[
                const Text(
                  'Explanation:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _C.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  mistake.staticExplanation,
                  style: const TextStyle(fontSize: 14, color: _C.textMuted, height: 1.5),
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: !mistake.hasAiInputs || isLoadingAi ? null : () => _explainWithAi(mistake),
                  icon: isLoadingAi
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary),
                        )
                      : const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    isLoadingAi ? 'Generating...' : 'Explain with AI',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.primary,
                    side: const BorderSide(color: _C.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (aiExplanation != null && aiExplanation.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _C.primaryLight.withValues(alpha: 0.5),
                    border: Border.all(color: _C.primaryLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: _C.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AI Tutor Explanation',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _C.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        aiExplanation,
                        style: const TextStyle(fontSize: 14, color: _C.textPrimary, height: 1.6),
                      ),
                    ],
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
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: _C.surface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _C.dark,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Locked Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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

  Widget _buildAnswerRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: _C.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _C.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
