import '../models/group_expense.dart';
import '../models/settlement.dart';

/// Implements the Minimize Cash Flow algorithm to reduce the number
/// of transactions needed to settle all debts.
///
/// Given a list of group expenses, it computes net balances for each user
/// and returns the minimum set of payments required.
class DebtSimplifier {
  /// Computes simplified debt suggestions for a group.
  ///
  /// [expenses] — All expenses for the group.
  /// Returns a list of [DebtSuggestion] with minimum payments.
  static List<DebtSuggestion> simplify(
    List<GroupExpense> expenses,
    List<String> memberIds,
  ) {
    // Step 1: Compute net balance for each member
    // Positive = they are owed money; Negative = they owe money
    final Map<String, double> netBalance = {for (var id in memberIds) id: 0.0};

    for (final expense in expenses) {
      // Payer receives credit for what others owe
      for (final entry in expense.splitDetails.entries) {
        final userId = entry.key;
        final amount = entry.value;
        if (userId == expense.paidById) continue;
        // payer is owed this amount
        netBalance[expense.paidById] =
            (netBalance[expense.paidById] ?? 0) + amount;
        // debtor owes this amount
        netBalance[userId] = (netBalance[userId] ?? 0) - amount;
      }
    }

    // Step 2: Minimize Cash Flow using greedy algorithm
    return _minCashFlow(netBalance);
  }

  /// Greedy algorithm: always settle the largest creditor with the largest debtor
  static List<DebtSuggestion> _minCashFlow(Map<String, double> netBalance) {
    final suggestions = <DebtSuggestion>[];
    final amounts = Map<String, double>.from(netBalance);

    while (true) {
      // Find max creditor (most positive) and max debtor (most negative)
      String? maxCreditor;
      String? maxDebtor;
      double maxCredit = 0.01; // threshold to ignore tiny amounts
      double maxDebt = 0.01;

      for (final entry in amounts.entries) {
        if (entry.value > maxCredit) {
          maxCredit = entry.value;
          maxCreditor = entry.key;
        }
        if (entry.value < -maxDebt) {
          maxDebt = -entry.value;
          maxDebtor = entry.key;
        }
      }

      // No significant debts remain
      if (maxCreditor == null || maxDebtor == null) break;

      final settleAmount = maxCredit < maxDebt ? maxCredit : maxDebt;

      suggestions.add(DebtSuggestion(
        fromUserId: maxDebtor,
        toUserId: maxCreditor,
        amount: double.parse(settleAmount.toStringAsFixed(2)),
      ));

      amounts[maxCreditor] = amounts[maxCreditor]! - settleAmount;
      amounts[maxDebtor] = amounts[maxDebtor]! + settleAmount;
    }

    return suggestions;
  }

  /// Computes raw (non-simplified) pairwise balances.
  /// Returns a map of pairId -> (fromUserId, toUserId, amount).
  static Map<String, double> computeNetBalances(
    List<GroupExpense> expenses,
    List<String> memberIds,
  ) {
    final Map<String, double> netBalance = {for (var id in memberIds) id: 0.0};

    for (final expense in expenses) {
      for (final entry in expense.splitDetails.entries) {
        final userId = entry.key;
        final amount = entry.value;
        if (userId == expense.paidById) continue;
        netBalance[expense.paidById] =
            (netBalance[expense.paidById] ?? 0) + amount;
        netBalance[userId] = (netBalance[userId] ?? 0) - amount;
      }
    }

    return netBalance;
  }
}
