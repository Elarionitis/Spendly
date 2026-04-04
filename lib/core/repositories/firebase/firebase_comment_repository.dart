import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comment.dart';
import '../comment_repository.dart';

/// Firestore-backed comment repository.
class FirebaseCommentRepository implements CommentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('comments');

  @override
  Stream<List<Comment>> watchComments(String targetId) {
    return _col
        .where('targetId', isEqualTo: targetId)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Comment.fromJson(doc.data(), id: doc.id))
            .toList());
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
