import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../services/goal_service.dart';

// --- Colors & Aesthetics from WelcomeScreen ---
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _C.primary,
              onPrimary: Colors.white,
              onSurface: _C.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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

      final hasPermission =
          await NotificationService.instance.requestPermission();

      if (hasPermission) {
        await NotificationService.instance.scheduleReminder(
          id: 1,
          title: 'Study Time!',
          body:
              'Time to complete your $_selectedType goal of ${_targetQuestions.toInt()} questions.',
          time: _reminderTime,
          frequency: _selectedType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Goal saved and reminder scheduled successfully!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF10B981), // Success green from Welcome screen features
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save goal: $e',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFEF4444), // Error red
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text(
          'Study Goals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _C.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: _C.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _C.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: _C.border,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set Your Targets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _C.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Consistency is key. Schedule your study sessions below.',
              style: TextStyle(
                fontSize: 14,
                color: _C.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Goal Type Section
            const Text(
              'Goal Frequency',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Daily',
                  label: Text('Daily', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ButtonSegment(
                  value: 'Weekly',
                  label: Text('Weekly', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ButtonSegment(
                  value: 'Monthly',
                  label: Text('Monthly', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return _C.primaryLight;
                  }
                  return Colors.white;
                }),
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return _C.primary;
                  }
                  return _C.textPrimary;
                }),
                side: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const BorderSide(color: _C.primary, width: 1.5);
                  }
                  return const BorderSide(color: _C.border, width: 1);
                }),
              ),
            ),
            const SizedBox(height: 48),

            // Target Questions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Target Questions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _C.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_targetQuestions.toInt()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _C.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _C.primary,
                inactiveTrackColor: _C.border,
                thumbColor: _C.primary,
                overlayColor: _C.primaryLight,
                valueIndicatorTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              child: Slider(
                value: _targetQuestions,
                min: 5,
                max: 100,
                divisions: 19,
                label: _targetQuestions.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _targetQuestions = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 48),

            // Reminder Time Section
            const Text(
              'Reminder Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20.0,
                ),
                decoration: BoxDecoration(
                  color: _C.cardBg,
                  border: Border.all(color: _C.border),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 16)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: _C.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _reminderTime.format(context),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _C.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      color: _C.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 64),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
