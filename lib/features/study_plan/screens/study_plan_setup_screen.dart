import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/study_plan_provider.dart';
import '../services/study_plan_service.dart';

class StudyPlanSetupScreen extends ConsumerStatefulWidget {
  const StudyPlanSetupScreen({super.key});

  @override
  ConsumerState<StudyPlanSetupScreen> createState() =>
      _StudyPlanSetupScreenState();
}

class _StudyPlanSetupScreenState extends ConsumerState<StudyPlanSetupScreen> {
  final _targetController = TextEditingController(text: '80');

  DateTime _examDate = DateTime.now().add(const Duration(days: 90));
  double _targetScore = 80;
  bool _isSaving = false;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickExamDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (selected != null) {
      setState(() {
        _examDate = selected;
      });
    }
  }

  Future<void> _savePlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Sign in to generate your study plan.');
      return;
    }

    final targetScore = int.tryParse(_targetController.text.trim()) ??
        _targetScore.round();

    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(studyPlanServiceProvider);
      await service.updateUserGoal(user.uid, _examDate, targetScore);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on StudyPlanFailure catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Unable to generate your study plan right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(_examDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Plan'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Build a roadmap for your exam prep.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick your exam date and target score so we can calculate a daily goal.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Exam Date',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _pickExamDate,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(dateLabel),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Target Score',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _targetScore,
                                min: 50,
                                max: 100,
                                divisions: 50,
                                label: '${_targetScore.round()}%',
                                onChanged: _isSaving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _targetScore = value;
                                          _targetController.text =
                                              value.round().toString();
                                        });
                                      },
                              ),
                            ),
                            SizedBox(
                              width: 84,
                              child: TextField(
                                controller: _targetController,
                                enabled: !_isSaving,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  suffixText: '%',
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value.trim());
                                  if (parsed == null) {
                                    return;
                                  }

                                  final clamped = parsed.clamp(50, 100);
                                  final normalizedText = clamped.toString();
                                  if (_targetController.text != normalizedText) {
                                    _targetController.value = TextEditingValue(
                                      text: normalizedText,
                                      selection: TextSelection.collapsed(
                                        offset: normalizedText.length,
                                      ),
                                    );
                                  }

                                  setState(() {
                                    _targetScore = clamped.toDouble();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We will save your roadmap and calculate a daily goal based on your current performance.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isSaving ? null : _savePlan,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Generate My Plan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}