import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../services/goal_service.dart';

class GoalSettingScreen extends ConsumerStatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  ConsumerState<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends ConsumerState<GoalSettingScreen> {
  String _selectedType = 'Daily';
  double _targetQuestions = 20;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load existing goal if available (optional enhancement)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentGoal = ref.read(currentGoalProvider).value;
      if (currentGoal != null) {
        setState(() {
          _selectedType = currentGoal.type;
          _targetQuestions = currentGoal.targetQuestions.toDouble();
          final parts = currentGoal.reminderTime.split(':');
          if (parts.length == 2) {
            _reminderTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 8,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        });
      }
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  Future<void> _saveGoal() async {
    setState(() => _isLoading = true);
    try {
      final formattedTime =
          '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

      final newGoal = GoalModel(
        id: 'current_goal',
        type: _selectedType,
        targetQuestions: _targetQuestions.toInt(),
        reminderTime: formattedTime,
        isActive: true,
      );

      await ref.read(goalServiceProvider).saveGoal(newGoal);

      // Request notification permissions
      final hasPermission =
          await NotificationService.instance.requestPermission();

      if (hasPermission) {
        await NotificationService.instance.scheduleReminder(
          id: 1, // Static ID for the single study reminder
          title: 'Study Time!',
          body:
              'Time to complete your $_selectedType goal of ${_targetQuestions.toInt()} questions.',
          time: _reminderTime,
          frequency: _selectedType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal saved and reminder scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Goals'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set Your Targets',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Goal Type Section
            Text(
              'Goal Frequency',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Daily', label: Text('Daily')),
                ButtonSegment(value: 'Weekly', label: Text('Weekly')),
                ButtonSegment(value: 'Monthly', label: Text('Monthly')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 32),

            // Target Questions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target Questions',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${_targetQuestions.toInt()}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _targetQuestions,
              min: 5,
              max: 100,
              divisions: 19, // (100-5)/5 = 19
              label: _targetQuestions.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _targetQuestions = value;
                });
              },
            ),
            const SizedBox(height: 32),

            // Reminder Time Section
            Text(
              'Reminder Time',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _reminderTime.format(context),
                      style: theme.textTheme.titleLarge,
                    ),
                    Icon(
                      Icons.access_time,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveGoal,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Goal & Enable Reminder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
