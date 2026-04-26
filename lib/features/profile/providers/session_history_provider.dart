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
