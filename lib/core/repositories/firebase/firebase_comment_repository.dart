import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/comment.dart';
import '../comment_repository.dart';

/// Firestore-backed comment repository.
class FirebaseCommentRepository implements CommentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('comments');

  bool _isIndexError(FirebaseException e) {
    final message = e.message ?? '';
    return e.code == 'failed-precondition' && message.toLowerCase().contains('index');
  }

  List<Comment> _mapAndSort(QuerySnapshot<Map<String, dynamic>> snap) {
    final comments = snap.docs
        .map((doc) => Comment.fromJson(doc.data(), id: doc.id))
        .toList();
    comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return comments;
  }

  @override
  Stream<List<Comment>> watchComments(String targetId) {
    final primary = _col
        .where('targetId', isEqualTo: targetId)
        .orderBy('timestamp');
    final fallback = _col.where('targetId', isEqualTo: targetId);

    return (() async* {
      try {
        await primary.limit(1).get();
        yield* primary.snapshots().map(_mapAndSort);
      } on FirebaseException catch (e) {
        if (!_isIndexError(e)) rethrow;
        debugPrint('Missing Firestore index for comments stream. Falling back to client sorting.');
        yield* fallback.snapshots().map(_mapAndSort);
      }
    })();
  }

  @override
  Future<void> addComment(Comment comment) async {
    final data = comment.toJson()
      ..remove('id')
      ..['timestamp'] = FieldValue.serverTimestamp();
    await _col.add(data);
  }

  @override
  Future<void> deleteComment(String id) async {
    await _col.doc(id).delete();
  }
}
