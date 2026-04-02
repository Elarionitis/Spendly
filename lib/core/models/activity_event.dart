enum ActivityType {
  expenseAdded,
  settled,
  commentAdded,
  memberJoined,
  groupCreated,
}

extension ActivityTypeX on ActivityType {
  String get icon {
    switch (this) {
      case ActivityType.expenseAdded:
        return '🧾';
      case ActivityType.settled:
        return '✅';
      case ActivityType.commentAdded:
        return '💬';
      case ActivityType.memberJoined:
        return '👋';
      case ActivityType.groupCreated:
        return '🎉';
    }
  }
}

class ActivityEvent {
  final String id;
  final String userId;
  final ActivityType type;
  final String description;
  final DateTime timestamp;

  /// Optional metadata: e.g., { 'amount': 1200, 'groupName': 'Goa Trip' }
  final Map<String, dynamic>? metadata;

  const ActivityEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ActivityEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
