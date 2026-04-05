import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/expense.dart';
import '../../core/models/enums.dart';
import '../../core/repositories/repository_providers.dart';
import '../auth/auth_provider.dart';

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(expenseRepositoryProvider).watchUserExpenses(user.id);
});

final expenseActionProvider = Provider<ExpenseActionNotifier>((ref) {
  return ExpenseActionNotifier(ref);
});

class ExpenseActionNotifier {
  final Ref _ref;

  ExpenseActionNotifier(this._ref);

  Future<void> addExpense(Expense expense, {dynamic imageFile}) async {
    await _ref.read(expenseRepositoryProvider).addExpense(expense, imageFile: imageFile);
  }

  Future<void> updateExpense(Expense expense) async {
    await _ref.read(expenseRepositoryProvider).updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _ref.read(expenseRepositoryProvider).deleteExpense(id);
  }

  Future<void> approveExpense(String id, String userId) async {
    final expenses = _ref.read(expensesStreamProvider).value ?? [];
    final e = expenses.firstWhere((e) => e.id == id);
    if (e.approvals.contains(userId)) return;
    final newApprovals = [...e.approvals, userId];
    final newRejections = e.rejections.where((r) => r != userId).toList();
    await _ref.read(expenseRepositoryProvider).updateApprovalStatus(id, approvals: newApprovals, rejections: newRejections);
  }

  Future<void> rejectExpense(String id, String userId) async {
    final expenses = _ref.read(expensesStreamProvider).value ?? [];
    final e = expenses.firstWhere((e) => e.id == id);
    if (e.rejections.contains(userId)) return;
    final newRejections = [...e.rejections, userId];
    final newApprovals = e.approvals.where((a) => a != userId).toList();
    await _ref.read(expenseRepositoryProvider).updateApprovalStatus(id, approvals: newApprovals, rejections: newRejections);
  }
}

// Keep the old provider name but alias it to common value for easier migration
// but actually most UI expects List<Expense>, so we should provide that.
final expenseProvider = Provider<List<Expense>>((ref) {
  return ref.watch(expensesStreamProvider).value ?? [];
});

// ─── Derived Providers ───────────────────────────────────────────────────────

final userExpensesProvider = Provider<List<Expense>>((ref) {
  return ref.watch(expenseProvider);
});

final groupExpensesProvider = Provider.family<List<Expense>, String>((ref, groupId) {
  return ref.watch(expenseProvider)
      .where((e) => e.groupId == groupId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final personalExpensesOnlyProvider = Provider<List<Expense>>((ref) {
  return ref.watch(expenseProvider)
      .where((e) => e.type == ExpenseType.personal)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});
