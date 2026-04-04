import '../models/group_expense.dart';

abstract class ExpenseRepository {
  /// Real-time stream of expenses for a given group.
  Stream<List<GroupExpense>> watchExpenses(String groupId);

  /// Add a new expense.
  /// If [imageFile] is provided, the implementation must:
  ///   1. Upload to Cloudinary
  ///   2. Store the returned URL in [expense.imageUrl]
  Future<void> addExpense(GroupExpense expense, {dynamic imageFile});

  /// Update an existing expense.
  Future<void> updateExpense(GroupExpense expense);

  /// Delete an expense by ID.
  Future<void> deleteExpense(String groupId, String id);
}
