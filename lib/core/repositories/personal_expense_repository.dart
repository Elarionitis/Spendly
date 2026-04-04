import '../models/personal_expense.dart';

abstract class PersonalExpenseRepository {
  /// Stream of personal expenses for a given user.
  Stream<List<PersonalExpense>> watchPersonalExpenses(String userId);

  /// Add a new personal expense.
  Future<void> addPersonalExpense(String userId, PersonalExpense expense);

  /// Update an existing personal expense.
  Future<void> updatePersonalExpense(String userId, PersonalExpense expense);

  /// Delete a personal expense.
  Future<void> deletePersonalExpense(String userId, String expenseId);
}
