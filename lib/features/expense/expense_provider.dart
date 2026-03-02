// lib/features/expense/expense_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';

// Manages the list of all expenses
class ExpenseNotifier extends StateNotifier<List<Expense>> {
  ExpenseNotifier() : super([]);
  void addExpense(Expense expense) => state = [...state, expense];
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) => ExpenseNotifier());

// Manages settlements and the Sprint 3 "Verification" workflow
class SettlementNotifier extends StateNotifier<List<Settlement>> {
  SettlementNotifier() : super([]);

  void initiateSettlement(Settlement s) => state = [...state, s];

  void handleVerification(String id, bool isApproved) {
    state = [
      for (final s in state)
        if (s.id == id && s.retryCount < 3)
          Settlement(
            id: s.id,
            fromUserId: s.fromUserId,
            toUserId: s.toUserId,
            amount: s.amount,
            status: isApproved ? SettlementStatus.verified : SettlementStatus.rejected,
            retryCount: isApproved ? s.retryCount : s.retryCount + 1,
          )
        else s,
    ];
  }
}

final settlementProvider = StateNotifierProvider<SettlementNotifier, List<Settlement>>((ref) => SettlementNotifier());