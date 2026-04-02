import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationType {
  expenseAdded,
  settlementRequested,
  settlementVerified,
  settlementRejected,
  memberJoined,
  commentAdded,
}

extension NotificationTypeX on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.expenseAdded:
        return 'Expense Added';
      case NotificationType.settlementRequested:
        return 'Settlement Requested';
      case NotificationType.settlementVerified:
        return 'Settlement Verified';
      case NotificationType.settlementRejected:
        return 'Settlement Rejected';
      case NotificationType.memberJoined:
        return 'Member Joined';
      case NotificationType.commentAdded:
        return 'Comment Added';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.expenseAdded:
        return '🧾';
      case NotificationType.settlementRequested:
        return '💸';
      case NotificationType.settlementVerified:
        return '✅';
      case NotificationType.settlementRejected:
        return '❌';
      case NotificationType.memberJoined:
        return '👋';
      case NotificationType.commentAdded:
        return '💬';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}

// ─── Notification Provider ───────────────────────────────────────────────────

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier();
});

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier() : super([]);

  void addNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final notification = AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      data: data,
    );
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void clearAll() {
    state = [];
  }
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});
