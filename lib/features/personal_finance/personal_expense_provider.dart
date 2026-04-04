import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/personal_expense.dart';
import '../../core/models/enums.dart';
import '../../core/repositories/repository_providers.dart';
import '../auth/auth_provider.dart';

final personalExpenseProvider =
    StateNotifierProvider<PersonalExpenseNotifier, List<PersonalExpense>>(
        (ref) {
  return PersonalExpenseNotifier(ref);
});

class PersonalExpenseNotifier extends StateNotifier<List<PersonalExpense>> {
  final Ref _ref;
  StreamSubscription? _subscription;

  PersonalExpenseNotifier(this._ref) : super([]) {
    _listenToExpenses();
  }

  void _listenToExpenses() {
    final user = _ref.watch(authProvider);
    if (user == null) {
      state = [];
      return;
    }

    _subscription?.cancel();
    _subscription = _ref
        .watch(personalExpenseRepositoryProvider)
        .watchPersonalExpenses(user.id)
        .listen((expenses) => state = expenses);
  }

  Future<void> addExpense(PersonalExpense expense) async {
    final user = _ref.read(authProvider);
    if (user == null) return;
    await _ref.read(personalExpenseRepositoryProvider).addPersonalExpense(user.id, expense);
  }

  Future<void> updateExpense(PersonalExpense updated) async {
    final user = _ref.read(authProvider);
    if (user == null) return;
    await _ref.read(personalExpenseRepositoryProvider).updatePersonalExpense(user.id, updated);
  }

  Future<void> deleteExpense(String id) async {
    final user = _ref.read(authProvider);
    if (user == null) return;
    await _ref.read(personalExpenseRepositoryProvider).deletePersonalExpense(user.id, id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

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
    Provider<List<PersonalExpense>>((ref) {
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
