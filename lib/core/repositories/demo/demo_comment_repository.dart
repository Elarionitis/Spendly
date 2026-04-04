import 'dart:async';
import '../../models/comment.dart';
import '../comment_repository.dart';

/// In-memory comment repository seeded with demo comments.
class DemoCommentRepository implements CommentRepository {
  final List<Comment> _comments = [];
  final _controller = StreamController<List<Comment>>.broadcast();

  DemoCommentRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    _comments.addAll([
      Comment(
        id: 'c1', userId: 'u2', targetId: 'ge1', targetType: 'expense',
        message: 'Great find on the hotel! Well within budget 🙌',
        timestamp: now.subtract(const Duration(days: 27, hours: 2)),
      ),
      Comment(
        id: 'c2', userId: 'u1', targetId: 'ge1', targetType: 'expense',
        message: 'Thanks! Booked early so got a good deal.',
        timestamp: now.subtract(const Duration(days: 27, hours: 1)),
      ),
      Comment(
        id: 'c3', userId: 'u3', targetId: 'ge3', targetType: 'expense',
        message: 'The food was amazing 🍤',
        timestamp: now.subtract(const Duration(days: 24, hours: 5)),
      ),
      Comment(
        id: 'c4', userId: 'u2', targetId: 's1', targetType: 'settlement',
        message: 'Sent via GPay — ref in txn ID',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  void _emitForTarget(String targetId) {
    _controller.add(
      _comments.where((c) => c.targetId == targetId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
    );
  }

  @override
  Stream<List<Comment>> watchComments(String targetId) {
    final initial = _comments.where((c) => c.targetId == targetId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return Stream.value(initial).mergeWith([
      _controller.stream
          .where((list) => list.any((c) => c.targetId == targetId))
          .map((list) => list.where((c) => c.targetId == targetId).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp))),
    ]);
  }

  @override
  Future<void> addComment(Comment comment) async {
    _comments.insert(0, comment);
    _emitForTarget(comment.targetId);
  }

  @override
  Future<void> deleteComment(String id) async {
    final comment = _comments.firstWhere((c) => c.id == id, orElse: () => throw Exception('Not found'));
    _comments.removeWhere((c) => c.id == id);
    _emitForTarget(comment.targetId);
  }
}

extension _StreamMerge<T> on Stream<T> {
  Stream<T> mergeWith(List<Stream<T>> others) {
    final controller = StreamController<T>.broadcast();
    listen(controller.add, onError: controller.addError);
    for (final s in others) {
      s.listen(controller.add, onError: controller.addError);
    }
    return controller.stream;
  }
}
