import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/comment.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/repositories/comment_repository.dart';

const _uuid = Uuid();

// ─── Comment Notifier ─────────────────────────────────────────────────────────

final commentProvider =
    StateNotifierProvider<CommentNotifier, List<Comment>>((ref) {
  return CommentNotifier(ref.watch(commentRepositoryProvider));
});

class CommentNotifier extends StateNotifier<List<Comment>> {
  final CommentRepository _repo;
  final Map<String, void Function()> _listeners = {};

  CommentNotifier(this._repo) : super([]);

  /// Subscribe to real-time comments for a target (expense/settlement).
  void subscribeToTarget(String targetId) {
    if (_listeners.containsKey(targetId)) return;
    final sub = _repo.watchComments(targetId).listen((comments) {
      final others = state.where((c) => c.targetId != targetId).toList();
      state = [...others, ...comments];
    });
    _listeners[targetId] = sub.cancel;
  }

  Future<void> addComment({
    required String targetId,
    required String targetType,
    required String userId,
    required String message,
  }) {
    final comment = Comment(
      id: _uuid.v4(),
      userId: userId,
      targetId: targetId,
      targetType: targetType,
      message: message,
      timestamp: DateTime.now(),
    );
    return _repo.addComment(comment);
  }

  Future<void> deleteComment(String id) => _repo.deleteComment(id);

  @override
  void dispose() {
    for (final cancel in _listeners.values) {
      cancel();
    }
    super.dispose();
  }
}

// ─── Per-target provider ──────────────────────────────────────────────────────

final commentsForTargetProvider =
    Provider.family<List<Comment>, String>((ref, targetId) {
  ref.read(commentProvider.notifier).subscribeToTarget(targetId);

  final all = ref.watch(commentProvider);
  return all.where((c) => c.targetId == targetId).toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
});
