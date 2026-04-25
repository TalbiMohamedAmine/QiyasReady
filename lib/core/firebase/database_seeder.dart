import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseSeeder {
  DatabaseSeeder._();

  static bool _hasSeeded = false;

  static Future<void> seedDummyData() async {
    if (_hasSeeded) {
      debugPrint('DatabaseSeeder: seeding already completed for this app run.');
      return;
    }

    debugPrint('DatabaseSeeder: starting Firestore seeding...');

    final firestore = FirebaseFirestore.instance;

    try {
      final batch = firestore.batch();

      final questionRef = firestore.collection('questions').doc('seed_question_001');
      batch.set(
        questionRef,
        {
          'examId': 'exam_seed_001',
          'chapterId': 'chapter_seed_001',
          'lessonId': 'lesson_seed_001',
          'difficulty': 'medium',
          'stem': 'What is the value of 12 + 8?',
          'options': [
            {'id': 'a', 'text': '18'},
            {'id': 'b', 'text': '20'},
            {'id': 'c', 'text': '22'},
            {'id': 'd', 'text': '24'},
          ],
          'correctOptionId': 'b',
          'static_explanation':
              'Add ones and tens normally: 12 + 8 = 20.',
          'ai_explanation_prompt':
              'Explain step-by-step how to solve 12 + 8 for a beginner.',
          'avgSolveSec': 60,
        },
        SetOptions(merge: true),
      );

      final planRef =
          firestore.collection('subscription_plans').doc('seed_plan_beginner');
      batch.set(
        planRef,
        {
          'name': 'Beginner',
          'features': {
            'maxMockPerMonth': 2,
            'maxPracticeQuestionsPerDay': 30,
            'offlineDownloadsAllowed': false,
            'advancedAnalytics': false,
          },
          'limits': {
            'dailyPracticeLimit': 30,
            'customTestLimit': 1,
          },
          'price': {
            'currency': 'USD',
            'amount': 4.99,
            'interval': 'month',
          },
        },
        SetOptions(merge: true),
      );

      final wellbeingRef =
          firestore.collection('wellbeing_content').doc('seed_wellbeing_001');
      batch.set(
        wellbeingRef,
        {
          'type': 'tip',
          'title': 'Pre-Exam Breathing Reset',
          'body':
              'Take 3 slow breaths. Inhale for 4 seconds, hold for 4, exhale for 6.',
          'durationSec': 120,
          'mediaPath': '',
          'tags': ['stress', 'focus'],
          'active': true,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      _hasSeeded = true;
      debugPrint('DatabaseSeeder: dummy data seeding completed successfully.');
    } on FirebaseException catch (e, st) {
      debugPrint(
        'DatabaseSeeder: FirebaseException during seeding '
        '(${e.code}) ${e.message}',
      );
      debugPrint('$st');
    } catch (e, st) {
      debugPrint('DatabaseSeeder: unexpected error during seeding: $e');
      debugPrint('$st');
    }
  }
}
