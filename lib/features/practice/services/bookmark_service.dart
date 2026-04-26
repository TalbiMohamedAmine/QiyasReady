import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adaptive_practice/adaptive_practice_service.dart';

class BookmarkFailure implements Exception {
  const BookmarkFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class BookmarkedQuestion {
  const BookmarkedQuestion({
    required this.questionId,
    required this.stem,
    required this.options,
    required this.correctOptionId,
    required this.subject,
    required this.staticExplanation,
    required this.createdAt,
  });

  final String questionId;
  final String stem;
  final List<PracticeOption> options;
  final String? correctOptionId;
  final String subject;
  final String staticExplanation;
  final DateTime createdAt;

  factory BookmarkedQuestion.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final rawOptions = data['options'];
    final options = <PracticeOption>[];
    if (rawOptions is List) {
      for (var i = 0; i < rawOptions.length; i++) {
        final item = rawOptions[i];
        if (item is Map<String, dynamic>) {
          final id = (item['id'] as String?)?.trim();
          final text = (item['text'] as String?)?.trim();
          if (id != null &&
              id.isNotEmpty &&
              text != null &&
              text.isNotEmpty) {
            options.add(PracticeOption(id: id, text: text));
          }
        }
      }
    }

    final ts = data['createdAt'];
    DateTime createdAt;
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return BookmarkedQuestion(
      questionId: docId,
      stem: (data['stem'] as String?)?.trim() ?? '',
      options: options,
      correctOptionId: (data['correctOptionId'] as String?)?.trim(),
      subject: (data['subject'] as String?)?.trim() ?? '',
      staticExplanation:
          (data['staticExplanation'] as String?)?.trim() ?? '',
      createdAt: createdAt,
    );
  }
}

class BookmarkService {
  BookmarkService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _bookmarksRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks');
  }

  /// Returns `true` if the question is now bookmarked, `false` if removed.
  Future<bool> toggleBookmark({
    required PracticeQuestion question,
    required String subject,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookmarkFailure(
        'Please sign in to save questions.',
      );
    }

    final docRef = _bookmarksRef(uid).doc(question.id);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.delete();
      return false;
    }

    final optionMaps = question.options
        .map((o) => {'id': o.id, 'text': o.text})
        .toList(growable: false);

    await docRef.set({
      'stem': question.stem,
      'options': optionMaps,
      'correctOptionId': question.correctOptionId,
      'subject': subject,
      'staticExplanation': question.staticExplanation,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<bool> isBookmarked(String questionId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return false;
    }

    final snapshot = await _bookmarksRef(uid).doc(questionId).get();
    return snapshot.exists;
  }

  Stream<List<BookmarkedQuestion>> watchBookmarks() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return Stream.value(const []);
    }

    return _bookmarksRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookmarkedQuestion.fromFirestore(doc.id, doc.data());
      }).toList(growable: false);
    });
  }

  Stream<bool> watchIsBookmarked(String questionId) {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return Stream.value(false);
    }

    return _bookmarksRef(uid)
        .doc(questionId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> removeBookmark(String questionId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    await _bookmarksRef(uid).doc(questionId).delete();
  }
}

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService();
});

final bookmarkedQuestionsProvider =
    StreamProvider<List<BookmarkedQuestion>>((ref) {
  final service = ref.watch(bookmarkServiceProvider);
  return service.watchBookmarks();
});

final isBookmarkedProvider =
    StreamProvider.family<bool, String>((ref, questionId) {
  final service = ref.watch(bookmarkServiceProvider);
  return service.watchIsBookmarked(questionId);
});
