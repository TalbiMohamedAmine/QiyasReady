import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.rank,
    required this.name,
    required this.score,
    this.isCurrentUser = false,
  });

  final String uid;
  final int rank;
  final String name;
  final int score;
  final bool isCurrentUser;
}

class LeaderboardService {
  LeaderboardService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<List<LeaderboardEntry>> watchTop50() {
    return _firestore
        .collection('users')
        .orderBy('profile.global_stats.total_questions_answered',
            descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final entries = <LeaderboardEntry>[];
      int currentRank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final profile = data['profile'];

        int score = 0;
        String name = 'Anonymous Student';

        if (profile is Map<String, dynamic>) {
          name = (profile['full_name'] as String?)?.trim() ?? '';
          if (name.isEmpty) name = 'Anonymous Student';

          final globalStats = profile['global_stats'];
          if (globalStats is Map<String, dynamic>) {
            score = (globalStats['total_questions_answered'] as num?)?.toInt() ?? 0;
          }
        }

        entries.add(LeaderboardEntry(
          uid: doc.id,
          rank: currentRank++,
          name: name,
          score: score,
          isCurrentUser: doc.id == currentUid,
        ));
      }

      return entries;
    });
  }

  Stream<LeaderboardEntry?> watchCurrentUserRank() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);

    // Watch the current user's score
    return _firestore.collection('users').doc(uid).snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;

      final data = doc.data()!;
      final profile = data['profile'];

      int score = 0;
      String name = 'Anonymous Student';

      if (profile is Map<String, dynamic>) {
        name = (profile['full_name'] as String?)?.trim() ?? '';
        if (name.isEmpty) name = 'Anonymous Student';

        final globalStats = profile['global_stats'];
        if (globalStats is Map<String, dynamic>) {
          score = (globalStats['total_questions_answered'] as num?)?.toInt() ?? 0;
        }
      }

      // Find how many users have a strictly greater score
      final countQuery = await _firestore
          .collection('users')
          .where('profile.global_stats.total_questions_answered', isGreaterThan: score)
          .count()
          .get();

      // The rank is the number of users with a strictly higher score + 1
      final rank = (countQuery.count ?? 0) + 1;

      return LeaderboardEntry(
        uid: uid,
        rank: rank,
        name: name,
        score: score,
        isCurrentUser: true,
      );
    });
  }
}

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService();
});

final top50LeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardServiceProvider).watchTop50();
});

final currentUserRankProvider = StreamProvider<LeaderboardEntry?>((ref) {
  return ref.watch(leaderboardServiceProvider).watchCurrentUserRank();
});
