/// Comment on an expense or settlement.
class Comment {
  final String id;
  final String userId;

  /// The ID of the expense or settlement this comment belongs to.
  final String targetId;

  /// Either 'expense' or 'settlement'.
  final String targetType;

  final String message;
  final DateTime timestamp;

  const Comment({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
    required this.message,
    required this.timestamp,
  });

  Comment copyWith({
    String? id,
    String? userId,
    String? targetId,
    String? targetType,
    String? message,
    DateTime? timestamp,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Comment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
