import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adaptive_practice/adaptive_practice_service.dart';
import '../../practice/services/ai_tutor_service.dart';

class MockExamReviewScreen extends ConsumerStatefulWidget {
  const MockExamReviewScreen({
    super.key,
    required this.userId,
    required this.sessionId,
  });

  final String userId;
  final String sessionId;

  @override
  ConsumerState<MockExamReviewScreen> createState() =>
      _MockExamReviewScreenState();
}

class _MockExamReviewScreenState extends ConsumerState<MockExamReviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _grade = 'Grade 10';
  int _currentIndex = 0;
  String? _loadingAiForQuestionId;
  final Map<String, String> _aiExplanations = <String, String>{};
  List<_MockReviewItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final sessionRef = firestore
          .collection('users')
          .doc(widget.userId)
          .collection('sessions')
          .doc(widget.sessionId);

      final sessionSnapshot = await sessionRef.get();
      final sessionData = sessionSnapshot.data() ?? <String, dynamic>{};
      final rawGrade = (sessionData['grade'] as String?)?.trim();
      _grade = (rawGrade == null || rawGrade.isEmpty) ? 'Grade 10' : rawGrade;

      final answersSnapshot = await sessionRef.collection('answers').get();
      if (answersSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _items = const [];
          _errorMessage = 'No answers found for this session.';
        });
        return;
      }

      final questionIds = answersSnapshot.docs
          .map((doc) {
            final data = doc.data();
            final explicitId = (data['questionId'] as String?)?.trim();
            if (explicitId != null && explicitId.isNotEmpty) {
              return explicitId;
            }
            return doc.id;
          })
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final questionSnapshots = await Future.wait(
        questionIds
            .map((id) => firestore.collection('questions').doc(id).get())
            .toList(growable: false),
      );

      final questionById = <String, PracticeQuestion>{};
      for (final snapshot in questionSnapshots) {
        if (!snapshot.exists) {
          continue;
        }
        final data = snapshot.data();
        if (data == null) {
          continue;
        }
        final parsed = _parseQuestion(snapshot.id, data);
        if (parsed != null) {
          questionById[snapshot.id] = parsed;
        }
      }

      final items = <_MockReviewItem>[];
      for (final answerDoc in answersSnapshot.docs) {
        final answerData = answerDoc.data();
        final questionId =
            ((answerData['questionId'] as String?)?.trim().isNotEmpty ?? false)
                ? (answerData['questionId'] as String).trim()
                : answerDoc.id;

        final question = questionById[questionId];
        if (question == null) {
          continue;
        }

        items.add(
          _MockReviewItem(
            question: question,
            selectedOptionId: (answerData['selectedOption'] as String?) ?? '',
            isCorrect: answerData['isCorrect'] == true,
            durationSec: _toInt(answerData['durationSec']),
          ),
        );
      }

      setState(() {
        _isLoading = false;
        _items = items;
        _currentIndex = 0;
        _errorMessage = items.isEmpty
            ? 'No reviewable answers were found for this session.'
            : null;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load review right now.';
      });
      debugPrint('MockExamReviewScreen._loadReview error: $error');
    }
  }

  Future<void> _askAiTutor(_MockReviewItem item) async {
    final question = item.question;
    final correctOption = question.options
        .where((option) => option.id == question.correctOptionId)
        .firstOrNull;
    final userOption = question.options
        .where((option) => option.id == item.selectedOptionId)
        .firstOrNull;

    if (correctOption == null || userOption == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to build AI explanation for this question.'),
          ),
        );
      return;
    }

    setState(() {
      _loadingAiForQuestionId = question.id;
      _aiExplanations.remove(question.id);
    });

    try {
      final explanation = await ref.read(aiTutorProvider).generateExplanation(
            questionText: question.stem,
            correctAnswer: correctOption.text,
            userAnswer: userOption.text,
            grade: _grade,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _aiExplanations[question.id] = explanation;
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
          const SnackBar(
            content: Text('AI Tutor is temporarily unavailable. Please retry.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loadingAiForQuestionId = null;
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
        title: const Text('Review Answers'),
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
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                : _buildReviewBody(context, colorScheme),
      ),
    );
  }

  Widget _buildReviewBody(BuildContext context, ColorScheme colorScheme) {
    final item = _items[_currentIndex];
    final question = item.question;
    final aiExplanation = _aiExplanations[question.id];
    final isLoadingAi = _loadingAiForQuestionId == question.id;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Question ${_currentIndex + 1} of ${_items.length}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        item.isCorrect ? 'Correct' : 'Incorrect',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: item.isCorrect
                              ? const Color(0xFF1B7F5B)
                              : colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.durationSec}s',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    question.stem,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...question.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewOptionTile(
                    option: option,
                    selectedOptionId: item.selectedOptionId,
                    correctOptionId: question.correctOptionId,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explanation',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        question.staticExplanation.isEmpty
                            ? 'No explanation available.'
                            : question.staticExplanation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: isLoadingAi ? null : () => _askAiTutor(item),
                        icon: isLoadingAi
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          isLoadingAi ? 'Generating...' : 'Explain with AI',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (aiExplanation != null && aiExplanation.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.4),
                        colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                      ],
                    ),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Tutor',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        aiExplanation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentIndex > 0
                          ? () {
                              setState(() {
                                _currentIndex -= 1;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _currentIndex < _items.length - 1
                          ? () {
                              setState(() {
                                _currentIndex += 1;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PracticeQuestion? _parseQuestion(String id, Map<String, dynamic> data) {
    final stem = (data['stem'] as String?)?.trim();
    final options = _parseOptions(data['options']);
    final correctOptionId = _normalizeCorrectOptionId(
      data['correctOptionId'],
      options,
    );

    if (stem == null ||
        stem.isEmpty ||
        options.isEmpty ||
        correctOptionId == null) {
      return null;
    }

    return PracticeQuestion(
      id: id,
      stem: stem,
      options: options,
      correctOptionId: correctOptionId,
      chapterId: (data['chapterId'] as String?)?.trim() ?? '',
      lessonId: (data['lessonId'] as String?)?.trim() ?? '',
      avgSolveSec:
          _toInt(data['avgSolveSec']) <= 0 ? 60 : _toInt(data['avgSolveSec']),
      staticExplanation: (data['static_explanation'] as String?)?.trim() ?? '',
      explanationSteps: const [],
    );
  }

  List<PracticeOption> _parseOptions(dynamic rawOptions) {
    if (rawOptions is! List) {
      return const [];
    }

    final options = <PracticeOption>[];
    for (var index = 0; index < rawOptions.length; index++) {
      final item = rawOptions[index];
      if (item is Map<String, dynamic>) {
        final id = (item['id'] as String?)?.trim();
        final text = (item['text'] as String?)?.trim();
        if (id != null && id.isNotEmpty && text != null && text.isNotEmpty) {
          options.add(PracticeOption(id: id, text: text));
        }
      } else if (item is String) {
        final text = item.trim();
        if (text.isNotEmpty) {
          options.add(PracticeOption(id: 'option_${index + 1}', text: text));
        }
      }
    }

    return options;
  }

  String? _normalizeCorrectOptionId(
      dynamic value, List<PracticeOption> options) {
    if (value is String) {
      final trimmed = value.trim();
      if (options.any((option) => option.id == trimmed)) {
        return trimmed;
      }

      final parsedIndex = int.tryParse(trimmed);
      if (parsedIndex != null &&
          parsedIndex >= 0 &&
          parsedIndex < options.length) {
        return options[parsedIndex].id;
      }
    } else if (value is int && value >= 0 && value < options.length) {
      return options[value].id;
    }

    return null;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return 0;
  }
}

class _MockReviewItem {
  const _MockReviewItem({
    required this.question,
    required this.selectedOptionId,
    required this.isCorrect,
    required this.durationSec,
  });

  final PracticeQuestion question;
  final String selectedOptionId;
  final bool isCorrect;
  final int durationSec;
}

class _ReviewOptionTile extends StatelessWidget {
  const _ReviewOptionTile({
    required this.option,
    required this.selectedOptionId,
    required this.correctOptionId,
  });

  final PracticeOption option;
  final String selectedOptionId;
  final String? correctOptionId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = option.id == selectedOptionId;
    final isCorrect = correctOptionId != null && option.id == correctOptionId;

    Color borderColor = colorScheme.outlineVariant;
    Color backgroundColor = colorScheme.surface;
    IconData indicator = Icons.circle_outlined;

    if (isCorrect) {
      borderColor = const Color(0xFF1B7F5B);
      backgroundColor = const Color(0xFFE7F7F0);
      indicator = Icons.check_circle_outline;
    } else if (isSelected) {
      borderColor = colorScheme.error;
      backgroundColor = colorScheme.errorContainer.withValues(alpha: 0.4);
      indicator = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(indicator, color: borderColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              option.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (isCorrect)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Correct',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B7F5B),
                ),
              ),
            )
          else if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Your choice',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
