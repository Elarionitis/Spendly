import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../expense/expense_provider.dart';
import '../settlement/settlement_provider.dart';
import '../../core/models/app_models.dart';

// This is the provider your screen is looking for
final balanceProvider = Provider((ref) {
  final user = ref.watch(authProvider);
  final expenses = ref.watch(expenseProvider);
  final settlements = ref.watch(settlementProvider);

  if (user == null) return {'owe': 0.0, 'owed': 0.0};

  double owe = 0.0;
  double owed = 0.0;

  for (var ex in expenses) {
    if (ex.paidById == user.id) {
      ex.splitDetails.forEach((uid, amt) {
        if (uid != user.id) owed += amt;
      });
    } else if (ex.splitDetails.containsKey(user.id)) {
      owe += ex.splitDetails[user.id]!;
    }
  }

  // Sprint 3: Only VERIFIED settlements reduce your balance
  for (var s in settlements.where((s) => s.status == SettlementStatus.verified)) {
    if (s.fromUserId == user.id) owe -= s.amount;
    if (s.toUserId == user.id) owed -= s.amount;
  }

  return {'owe': owe, 'owed': owed};
});