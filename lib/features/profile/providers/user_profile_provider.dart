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

        Map<String, dynamic> rootGlobalStats = <String, dynamic>{};
        final rawRootGlobalStats = data['global_stats'];
        if (rawRootGlobalStats is Map<String, dynamic>) {
          rootGlobalStats = Map<String, dynamic>.from(rawRootGlobalStats);
        } else if (rawRootGlobalStats is Map) {
          rootGlobalStats = Map<String, dynamic>.fromEntries(
            rawRootGlobalStats.entries
                .where((entry) => entry.key is String)
                .map((entry) => MapEntry(entry.key as String, entry.value)),
          );
        }

        final profile = data['profile'];
        if (profile is Map<String, dynamic>) {
          final merged = Map<String, dynamic>.from(profile);
          final rawProfileGlobalStats = merged['global_stats'];
          Map<String, dynamic> profileGlobalStats = <String, dynamic>{};
          if (rawProfileGlobalStats is Map<String, dynamic>) {
            profileGlobalStats =
                Map<String, dynamic>.from(rawProfileGlobalStats);
          } else if (rawProfileGlobalStats is Map) {
            profileGlobalStats = Map<String, dynamic>.fromEntries(
              rawProfileGlobalStats.entries
                  .where((entry) => entry.key is String)
                  .map((entry) => MapEntry(entry.key as String, entry.value)),
            );
          }

          final combinedGlobalStats = <String, dynamic>{
            ...profileGlobalStats,
            ...rootGlobalStats,
          };

          if (combinedGlobalStats.isNotEmpty) {
            merged['global_stats'] = combinedGlobalStats;
          }
          return merged;
        }
        if (profile is Map) {
          final merged = Map<String, dynamic>.fromEntries(
            profile.entries.where((entry) => entry.key is String).map(
                  (entry) => MapEntry(entry.key as String, entry.value),
                ),
          );
          final rawProfileGlobalStats = merged['global_stats'];
          Map<String, dynamic> profileGlobalStats = <String, dynamic>{};
          if (rawProfileGlobalStats is Map<String, dynamic>) {
            profileGlobalStats =
                Map<String, dynamic>.from(rawProfileGlobalStats);
          } else if (rawProfileGlobalStats is Map) {
            profileGlobalStats = Map<String, dynamic>.fromEntries(
              rawProfileGlobalStats.entries
                  .where((entry) => entry.key is String)
                  .map((entry) => MapEntry(entry.key as String, entry.value)),
            );
          }

          final combinedGlobalStats = <String, dynamic>{
            ...profileGlobalStats,
            ...rootGlobalStats,
          };

          if (combinedGlobalStats.isNotEmpty) {
            merged['global_stats'] = combinedGlobalStats;
          }
          return merged;
        }

        return rootGlobalStats.isNotEmpty
            ? <String, dynamic>{'global_stats': rootGlobalStats}
            : <String, dynamic>{};
      });
    },
    loading: () => const Stream<Map<String, dynamic>>.empty(),
    error: (_, __) => const Stream<Map<String, dynamic>>.empty(),
  );
});
