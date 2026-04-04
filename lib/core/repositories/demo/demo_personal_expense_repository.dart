import 'dart:async';
import '../../models/personal_expense.dart';
import '../personal_expense_repository.dart';

class DemoPersonalExpenseRepository implements PersonalExpenseRepository {
  final List<PersonalExpense> _expenses = [];
  final _controller = StreamController<List<PersonalExpense>>.broadcast();

  @override
  Stream<List<PersonalExpense>> watchPersonalExpenses(String userId) {
    _emit();
    return _controller.stream;
  }

  void _emit() {
    _controller.add(List.unmodifiable(_expenses));
  }

  @override
  Future<void> addPersonalExpense(String userId, PersonalExpense expense) async {
    _expenses.add(expense);
    _emit();
  }

  @override
  Future<void> updatePersonalExpense(String userId, PersonalExpense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      _emit();
    }
  }

  @override
  Future<void> deletePersonalExpense(String userId, String expenseId) async {
    _expenses.removeWhere((e) => e.id == expenseId);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
