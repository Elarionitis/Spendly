import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/personal_expense.dart';
import '../../core/models/enums.dart';
import '../auth/auth_provider.dart';

final personalExpenseProvider =
    StateNotifierProvider<PersonalExpenseNotifier, List<PersonalExpense>>(
        (ref) {
  return PersonalExpenseNotifier(ref);
});

class PersonalExpenseNotifier extends StateNotifier<List<PersonalExpense>> {
  final Ref _ref;

  PersonalExpenseNotifier(this._ref) : super([]) {
    _seedData();
  }

  void _seedData() {
    final userId = _ref.read(authProvider)?.id ?? 'u1';
    final now = DateTime.now();

    state = [
      PersonalExpense(
        id: 'pe1',
        userId: userId,
        amount: 350,
        category: ExpenseCategory.food,
        description: 'Lunch at Cafe',
        paymentMethod: PaymentMethod.upi,
        date: now.subtract(const Duration(days: 1)),
      ),
      PersonalExpense(
        id: 'pe2',
        userId: userId,
        amount: 1200,
        category: ExpenseCategory.shopping,
        description: 'New Shoes',
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 2)),
      ),
      PersonalExpense(
        id: 'pe3',
        userId: userId,
        amount: 500,
        category: ExpenseCategory.transport,
        description: 'Cab to Airport',
        paymentMethod: PaymentMethod.upi,
        date: now.subtract(const Duration(days: 3)),
      ),
      PersonalExpense(
        id: 'pe4',
        userId: userId,
        amount: 2500,
        category: ExpenseCategory.entertainment,
        description: 'Movie + Dinner',
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 5)),
      ),
      PersonalExpense(
        id: 'pe5',
        userId: userId,
        amount: 800,
        category: ExpenseCategory.health,
        description: 'Pharmacy',
        paymentMethod: PaymentMethod.cash,
        date: now.subtract(const Duration(days: 7)),
      ),
      PersonalExpense(
        id: 'pe6',
        userId: userId,
        amount: 4500,
        category: ExpenseCategory.utilities,
        description: 'Internet Bill',
        paymentMethod: PaymentMethod.netBanking,
        date: now.subtract(const Duration(days: 10)),
      ),
      PersonalExpense(
        id: 'pe7',
        userId: userId,
        amount: 650,
        category: ExpenseCategory.food,
        description: 'Grocery Shopping',
        paymentMethod: PaymentMethod.upi,
        date: now.subtract(const Duration(days: 12)),
      ),
      PersonalExpense(
        id: 'pe8',
        userId: userId,
        amount: 3200,
        category: ExpenseCategory.shopping,
        description: 'Amazon Order',
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 15)),
      ),
      PersonalExpense(
        id: 'pe9',
        userId: userId,
        amount: 250,
        category: ExpenseCategory.transport,
        description: 'Metro Recharge',
        paymentMethod: PaymentMethod.wallet,
        date: now.subtract(const Duration(days: 18)),
      ),
      PersonalExpense(
        id: 'pe10',
        userId: userId,
        amount: 1800,
        category: ExpenseCategory.education,
        description: 'Online Course',
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 20)),
      ),
      PersonalExpense(
        id: 'pe11',
        userId: userId,
        amount: 420,
        category: ExpenseCategory.food,
        description: 'Coffee Shop',
        paymentMethod: PaymentMethod.upi,
        date: now.subtract(const Duration(days: 22)),
      ),
      PersonalExpense(
        id: 'pe12',
        userId: userId,
        amount: 900,
        category: ExpenseCategory.entertainment,
        description: 'Spotify + Netflix',
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 25)),
      ),
    ];
  }

  void addExpense(PersonalExpense expense) {
    state = [expense, ...state];
  }

  void updateExpense(PersonalExpense updated) {
    state = [
      for (final e in state)
        if (e.id == updated.id) updated else e,
    ];
  }

  void deleteExpense(String id) {
    state = state.where((e) => e.id != id).toList();
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
