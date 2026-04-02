import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/enums.dart';
import '../auth/auth_provider.dart';
import '../groups/group_provider.dart';
import '../personal_finance/personal_expense_provider.dart';

class CategorySpend {
  final ExpenseCategory category;
  final double total;
  const CategorySpend({required this.category, required this.total});
}

class MonthlySpend {
  final int month;
  final int year;
  final double total;
  const MonthlySpend({required this.month, required this.year, required this.total});

  String get label {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}

class DailySpend {
  final DateTime date;
  final double total;
  const DailySpend({required this.date, required this.total});
}

// ─── Personal Analytics ───────────────────────────────────────────────────────

final personalCategorySpendProvider =
    Provider<List<CategorySpend>>((ref) {
  final expenses = ref.watch(personalExpenseProvider);
  final now = DateTime.now();
  final thisMonthExpenses = expenses.where(
    (e) => e.date.month == now.month && e.date.year == now.year,
  );

  final Map<ExpenseCategory, double> totals = {};
  for (final e in thisMonthExpenses) {
    totals[e.category] = (totals[e.category] ?? 0) + e.amount;
  }

  return totals.entries
      .map((e) => CategorySpend(category: e.key, total: e.value))
      .where((c) => c.total > 0)
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
});

final personalMonthlySpendProvider =
    Provider<List<MonthlySpend>>((ref) {
  final expenses = ref.watch(personalExpenseProvider);
  final now = DateTime.now();

  final Map<String, double> totals = {};
  for (final e in expenses) {
    final key = '${e.date.year}-${e.date.month}';
    totals[key] = (totals[key] ?? 0) + e.amount;
  }

  final result = <MonthlySpend>[];
  for (var i = 5; i >= 0; i--) {
    final date = DateTime(now.year, now.month - i);
    final key = '${date.year}-${date.month}';
    result.add(MonthlySpend(
      month: date.month,
      year: date.year,
      total: totals[key] ?? 0,
    ));
  }
  return result;
});

final personalDailyTrendProvider =
    Provider<List<DailySpend>>((ref) {
  final expenses = ref.watch(personalExpenseProvider);
  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 29));

  final Map<String, double> dailyTotals = {};
  for (final e in expenses) {
    if (e.date.isAfter(cutoff)) {
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      dailyTotals[key] = (dailyTotals[key] ?? 0) + e.amount;
    }
  }

  final result = <DailySpend>[];
  for (var i = 29; i >= 0; i--) {
    final date = DateTime(now.year, now.month, now.day - i);
    final key = '${date.year}-${date.month}-${date.day}';
    result.add(DailySpend(date: date, total: dailyTotals[key] ?? 0));
  }
  return result;
});

final personalTotalThisMonthProvider = Provider<double>((ref) {
  final expenses = ref.watch(personalExpenseProvider);
  final now = DateTime.now();
  return expenses
      .where((e) => e.date.month == now.month && e.date.year == now.year)
      .fold(0.0, (sum, e) => sum + e.amount);
});

// ─── Group Analytics ──────────────────────────────────────────────────────────

final groupCategorySpendProvider =
    Provider<List<CategorySpend>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return [];

  final expenses = ref.watch(groupExpenseProvider);
  final now = DateTime.now();

  final Map<ExpenseCategory, double> totals = {};
  for (final e in expenses) {
    if (e.splitDetails.containsKey(user.id) || e.paidById == user.id) {
      if (e.date.month == now.month && e.date.year == now.year) {
        final userShare = e.splitDetails[user.id] ?? 0;
        totals[e.category] = (totals[e.category] ?? 0) + userShare;
      }
    }
  }

  return totals.entries
      .map((e) => CategorySpend(category: e.key, total: e.value))
      .where((c) => c.total > 0)
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
});

final groupMonthlySpendProvider =
    Provider<List<MonthlySpend>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return [];

  final expenses = ref.watch(groupExpenseProvider);
  final now = DateTime.now();

  final Map<String, double> totals = {};
  for (final e in expenses) {
    if (e.splitDetails.containsKey(user.id)) {
      final key = '${e.date.year}-${e.date.month}';
      totals[key] = (totals[key] ?? 0) + (e.splitDetails[user.id] ?? 0);
    }
  }

  final result = <MonthlySpend>[];
  for (var i = 5; i >= 0; i--) {
    final date = DateTime(now.year, now.month - i);
    final key = '${date.year}-${date.month}';
    result.add(MonthlySpend(
      month: date.month,
      year: date.year,
      total: totals[key] ?? 0,
    ));
  }
  return result;
});
