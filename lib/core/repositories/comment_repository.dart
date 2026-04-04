import '../models/comment.dart';

abstract class CommentRepository {
  /// Real-time stream of comments for a given target (expense or settlement).
  Stream<List<Comment>> watchComments(String targetId);

  /// Add a new comment.
  Future<void> addComment(Comment comment);

  /// Delete a comment by ID.
  Future<void> deleteComment(String id);
}
