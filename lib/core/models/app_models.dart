enum SplitType { equal, exact, percentage }
enum SettlementStatus { pending, verified, rejected }

class AppUser {
  final String id;
  final String name;
  final String email;
  const AppUser({required this.id, required this.name, required this.email});
}

class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidById;
  final Map<String, double> splitDetails; // userId: amount
  final DateTime date;

  Expense({
    required this.id, required this.groupId, required this.description,
    required this.amount, required this.paidById, required this.splitDetails,
    required this.date,
  });
}

class Settlement {
  final String id;
  final String fromUserId;
  final String toUserId;
  final double amount;
  SettlementStatus status;
  int retryCount;

  Settlement({
    required this.id, required this.fromUserId, required this.toUserId,
    required this.amount, this.status = SettlementStatus.pending,
    this.retryCount = 0,
  });
}

class Group {
  final String id;
  final String name;
  final String description;
  final String createdById;
  final List<String> memberIds;
  final DateTime createdAt;

  Group({
    required this.id, required this.name, required this.description,
    required this.createdById, required this.memberIds, required this.createdAt,
  });
}