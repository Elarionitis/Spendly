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
  final String? imageUrl;

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
    this.imageUrl,
  });

  /// People who owe money (not the payer)
  List<String> get debtors =>
      splitDetails.keys.where((uid) => uid != paidById).toList();

  factory GroupExpense.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawSplit = json['splitDetails'] as Map<String, dynamic>? ?? {};
    return GroupExpense(
      id: id ?? json['id'] as String,
      groupId: json['groupId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paidById: json['paidById'] as String? ?? '',
      splitDetails: rawSplit.map((k, v) => MapEntry(k, (v as num).toDouble())),
      splitType: SplitType.values.firstWhere(
        (e) => e.name == (json['splitType'] as String?),
        orElse: () => SplitType.equal,
      ),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == (json['category'] as String?),
        orElse: () => ExpenseCategory.other,
      ),
      date: json['date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['date'] as int)
          : (json['date'] as dynamic)?.toDate() ?? DateTime.now(),
      notes: json['notes'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'paidById': paidById,
      'splitDetails': splitDetails,
      'splitType': splitType.name,
      'category': category.name,
      'date': date.millisecondsSinceEpoch,
      if (notes != null) 'notes': notes,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

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
    String? imageUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GroupExpense && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
