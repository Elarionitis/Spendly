import 'enums.dart';

class PersonalExpense {
  final String id;
  final String userId;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String? notes;
  /// Local file path for an optionally attached receipt / payment screenshot.
  /// Not yet synced to cloud — stored on-device only.
  final String? receiptImagePath;

  const PersonalExpense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.paymentMethod,
    required this.date,
    this.notes,
    this.receiptImagePath,
  });

  PersonalExpense copyWith({
    String? id,
    String? userId,
    double? amount,
    ExpenseCategory? category,
    String? description,
    PaymentMethod? paymentMethod,
    DateTime? date,
    String? notes,
    // Pass `null` explicitly via `clearReceiptImage: true` pattern
    String? receiptImagePath,
    bool clearReceiptImage = false,
  }) {
    return PersonalExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptImagePath:
          clearReceiptImage ? null : (receiptImagePath ?? this.receiptImagePath),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PersonalExpense && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
