import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalModel {
  const GoalModel({
    required this.id,
    required this.type,
    required this.targetQuestions,
    required this.reminderTime,
    required this.isActive,
  });

  final String id;
  final String type; // 'Daily', 'Weekly', 'Monthly'
  final int targetQuestions;
  final String reminderTime; // 'HH:mm'
  final bool isActive;

  factory GoalModel.fromMap(String id, Map<String, dynamic> data) {
    return GoalModel(
      id: id,
      type: data['type'] as String? ?? 'Daily',
      targetQuestions: data['target_questions'] as int? ?? 10,
      reminderTime: data['reminder_time'] as String? ?? '08:00',
      isActive: data['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'target_questions': targetQuestions,
      'reminder_time': reminderTime,
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

class GoalService {
  GoalService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _goalsRef {
    final uid = _uid;
    if (uid == null) throw Exception('User not signed in');
    return _firestore.collection('users').doc(uid).collection('goals');
  }

  Future<void> saveGoal(GoalModel goal) async {
    // Overwrite the existing document or create a new one.
    // For simplicity, we could just use a static ID like 'current_goal' 
    // so the user has one active goal. Or use goal.id.
    final docId = goal.id.isEmpty ? 'current_goal' : goal.id;
    await _goalsRef.doc(docId).set(goal.toMap());
  }

  Stream<GoalModel?> watchCurrentGoal() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('goals')
        .doc('current_goal')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return GoalModel.fromMap(snapshot.id, snapshot.data()!);
    });
  }
}

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService();
});

final currentGoalProvider = StreamProvider<GoalModel?>((ref) {
  final service = ref.watch(goalServiceProvider);
  return service.watchCurrentGoal();
});
