import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

final sessionHistoryFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final sessionHistoryProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestore = ref.watch(sessionHistoryFirestoreProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream<List<Map<String, dynamic>>>.value(const []);
      }

      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    },
    loading: () => const Stream<List<Map<String, dynamic>>>.empty(),
    error: (_, __) => const Stream<List<Map<String, dynamic>>>.empty(),
  );
});

final mockExamCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestore = ref.watch(sessionHistoryFirestoreProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream<int>.value(0);
      }

      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .where('mode', isEqualTo: 'mock')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    },
    loading: () => const Stream<int>.empty(),
    error: (_, __) => const Stream<int>.empty(),
  );
});

final subjectQuestionsCountProvider = StreamProvider.family<int, String>((ref, subject) {
  final authState = ref.watch(authStateChangesProvider);
  final firestore = ref.watch(sessionHistoryFirestoreProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream<int>.value(0);
      }

      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .where('subject', isEqualTo: subject)
          .snapshots()
          .map((snapshot) {
            int total = 0;
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final scoreMap = data['score'];
              if (scoreMap is Map) {
                total += (scoreMap['total'] as num?)?.toInt() ?? 0;
              } else {
                total += (data['total_questions'] as num?)?.toInt() ?? 0;
              }
            }
            return total;
          });
    },
    loading: () => const Stream<int>.empty(),
    error: (_, __) => const Stream<int>.empty(),
  );
});
