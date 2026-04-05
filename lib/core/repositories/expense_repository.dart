import '../models/expense.dart';

abstract class ExpenseRepository {
  /// Real-time stream of all expenses involving a specific user.
  Stream<List<Expense>> watchUserExpenses(String userId);

  /// Real-time stream of expenses for a given group.
  Stream<List<Expense>> watchGroupExpenses(String groupId);

  /// Add a new expense.
  /// If [imageFile] is provided, the implementation must:
  ///   1. Upload to Cloudinary
  ///   2. Store the returned URL in [expense.imageUrl]
  Future<void> addExpense(Expense expense, {dynamic imageFile});

  /// Update an existing expense.
  Future<void> updateExpense(Expense expense);

  /// Update expense approval status.
  Future<void> updateApprovalStatus(
    String id, {
    List<String>? approvals,
    List<String>? rejections,
  });

  /// Delete an expense by ID.
  Future<void> deleteExpense(String id);
}
