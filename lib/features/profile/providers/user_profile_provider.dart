import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

final userProfileFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userProfileStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestore = ref.watch(userProfileFirestoreProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream<Map<String, dynamic>>.value(const <String, dynamic>{});
      }

      return firestore.collection('users').doc(user.uid).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) {
          return <String, dynamic>{};
        }

        final profile = data['profile'];
        if (profile is Map<String, dynamic>) {
          return Map<String, dynamic>.from(profile);
        }
        if (profile is Map) {
          return Map<String, dynamic>.fromEntries(
            profile.entries.where((entry) => entry.key is String).map(
                  (entry) => MapEntry(entry.key as String, entry.value),
                ),
          );
        }

        return <String, dynamic>{};
      });
    },
    loading: () => const Stream<Map<String, dynamic>>.empty(),
    error: (_, __) => const Stream<Map<String, dynamic>>.empty(),
  );
});
