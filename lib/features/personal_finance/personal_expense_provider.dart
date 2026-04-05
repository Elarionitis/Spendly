import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/expense.dart';
import '../../core/models/enums.dart';
import '../expenses/expense_provider.dart';

// Redirect personalExpenseProvider to the unified expenseProvider
final personalExpenseProvider = Provider<List<Expense>>((ref) {
  return ref.watch(expenseProvider)
      .where((e) => e.type == ExpenseType.personal)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

// ─── Filter State ─────────────────────────────────────────────────────────────

class PersonalExpenseFilter {
  final ExpenseCategory? category;
  final int? month;
  final int? year;

  const PersonalExpenseFilter({this.category, this.month, this.year});

  PersonalExpenseFilter copyWith({
    Object? category = _sentinel,
    Object? month = _sentinel,
    Object? year = _sentinel,
  }) {
    return PersonalExpenseFilter(
      category: category == _sentinel ? this.category : category as ExpenseCategory?,
      month: month == _sentinel ? this.month : month as int?,
      year: year == _sentinel ? this.year : year as int?,
    );
  }

  static const _sentinel = Object();
}

final personalExpenseFilterProvider =
    StateProvider<PersonalExpenseFilter>((ref) => const PersonalExpenseFilter());

final filteredPersonalExpensesProvider =
    Provider<List<Expense>>((ref) {
  final expenses = ref.watch(personalExpenseProvider);
  final filter = ref.watch(personalExpenseFilterProvider);

  return expenses.where((e) {
    if (filter.category != null && e.category != filter.category) return false;
    if (filter.month != null && e.date.month != filter.month) return false;
    if (filter.year != null && e.date.year != filter.year) return false;
    return true;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final personalMonthlyTotalProvider = Provider<double>((ref) {
  final filter = ref.watch(personalExpenseFilterProvider);
  final now = DateTime.now();
  final month = filter.month ?? now.month;
  final year = filter.year ?? now.year;
  final expenses = ref.watch(personalExpenseProvider);

  return expenses
      .where((e) => e.date.month == month && e.date.year == year)
      .fold(0.0, (sum, e) => sum + e.amount);
});
