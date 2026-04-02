import 'enums.dart';

class GroupExpense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidById;
  final Map<String, double> splitDetails; // userId -> amount they owe
  final SplitType splitType;
  final ExpenseCategory category;
  final DateTime date;
  final String? notes;

  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.splitDetails,
    required this.splitType,
    required this.category,
    required this.date,
    this.notes,
  });

  /// People who owe money (not the payer)
  List<String> get debtors =>
      splitDetails.keys.where((uid) => uid != paidById).toList();

  GroupExpense copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? paidById,
    Map<String, double>? splitDetails,
    SplitType? splitType,
    ExpenseCategory? category,
    DateTime? date,
    String? notes,
  }) {
    return GroupExpense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paidById: paidById ?? this.paidById,
      splitDetails: splitDetails ?? this.splitDetails,
      splitType: splitType ?? this.splitType,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GroupExpense && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
