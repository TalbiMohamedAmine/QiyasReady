import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

enum UserLifecycleStatus {
  newUser,
  returning,
}

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userGradeProvider = StreamProvider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return const Stream<String?>.value(null);
      }

      return firestore.collection('users').doc(user.uid).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) {
          return null;
        }

        final profile = data['profile'];
        final nestedGrade = profile is Map<String, dynamic>
            ? profile['grade'] as String?
            : null;
        final topLevelGrade = data['grade'] as String?;
        final grade = (nestedGrade ?? topLevelGrade)?.trim();

        if (grade == null || grade.isEmpty) {
          return null;
        }

        return grade;
      });
    },
    loading: () => const Stream<String?>.empty(),
    error: (_, __) => const Stream<String?>.empty(),
  );
});

final userLifecycleStatusProvider = Provider<AsyncValue<UserLifecycleStatus>>((
  ref,
) {
  final gradeAsync = ref.watch(userGradeProvider);

  return gradeAsync.whenData((grade) {
    if (grade == null || grade.trim().isEmpty) {
      return UserLifecycleStatus.newUser;
    }

    return UserLifecycleStatus.returning;
  });
});

class GradeSelectionController extends StateNotifier<AsyncValue<void>> {
  GradeSelectionController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> saveGrade(String grade) async {
    final trimmedGrade = grade.trim();
    if (trimmedGrade.isEmpty) {
      return false;
    }

    final user = _ref.read(authStateChangesProvider).value;
    if (user == null) {
      state = AsyncError(
        Exception('No authenticated user found.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();

    try {
      await _ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(user.uid)
          .set({
        'grade': trimmedGrade,
        'profile': {'grade': trimmedGrade},
      }, SetOptions(merge: true));

      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final gradeSelectionControllerProvider =
    StateNotifierProvider<GradeSelectionController, AsyncValue<void>>((ref) {
  return GradeSelectionController(ref);
});
