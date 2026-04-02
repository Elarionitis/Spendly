import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/comment.dart';

const _uuid = Uuid();

final commentProvider =
    StateNotifierProvider<CommentNotifier, List<Comment>>((ref) {
  return CommentNotifier();
});

class CommentNotifier extends StateNotifier<List<Comment>> {
  CommentNotifier() : super([]) {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    state = [
      Comment(
        id: 'c1',
        userId: 'u2',
        targetId: 'ge1',
        targetType: 'expense',
        message: 'Great find on the hotel! Well within budget 🙌',
        timestamp: now.subtract(const Duration(days: 27, hours: 2)),
      ),
      Comment(
        id: 'c2',
        userId: 'u1',
        targetId: 'ge1',
        targetType: 'expense',
        message: 'Thanks! Booked early so got a good deal.',
        timestamp: now.subtract(const Duration(days: 27, hours: 1)),
      ),
      Comment(
        id: 'c3',
        userId: 'u3',
        targetId: 'ge3',
        targetType: 'expense',
        message: 'The food was amazing 🍤',
        timestamp: now.subtract(const Duration(days: 24, hours: 5)),
      ),
      Comment(
        id: 'c4',
        userId: 'u2',
        targetId: 's1',
        targetType: 'settlement',
        message: 'Sent via GPay — ref in txn ID',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  void addComment({
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
    state = [comment, ...state];
  }

  void deleteComment(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

// ─── Per-target provider ──────────────────────────────────────────────────────

final commentsForTargetProvider =
    Provider.family<List<Comment>, String>((ref, targetId) {
  final all = ref.watch(commentProvider);
  final filtered = all.where((c) => c.targetId == targetId).toList();
  // Oldest first in thread
  filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return filtered;
});
