import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/settlement.dart';
import '../../core/models/enums.dart';
import '../../core/utils/debt_simplifier.dart';
import '../auth/auth_provider.dart';
import '../groups/group_provider.dart';

final settlementProvider =
    StateNotifierProvider<SettlementNotifier, List<Settlement>>((ref) {
  return SettlementNotifier(ref);
});

class SettlementNotifier extends StateNotifier<List<Settlement>> {
  final Ref _ref;

  SettlementNotifier(this._ref) : super([]) {
    _seedData();
  }

  void _seedData() {
    final userId = _ref.read(authProvider)?.id ?? 'u1';
    final now = DateTime.now();
    state = [
      Settlement(
        id: 's1',
        fromUserId: 'u2',
        toUserId: userId,
        amount: 6000,
        status: SettlementStatus.pendingVerification,
        createdAt: now.subtract(const Duration(days: 2)),
        transactionId: 'TXN12345678',
        groupId: 'g1',
      ),
      Settlement(
        id: 's2',
        fromUserId: userId,
        toUserId: 'u3',
        amount: 2875,
        status: SettlementStatus.verified,
        createdAt: now.subtract(const Duration(days: 10)),
        transactionId: 'TXN87654321',
        groupId: 'g1',
      ),
      Settlement(
        id: 's3',
        fromUserId: 'u4',
        toUserId: userId,
        amount: 1500,
        status: SettlementStatus.verified,
        createdAt: now.subtract(const Duration(days: 20)),
        groupId: 'g3',
      ),
    ];
  }

  void initiateSettlement(Settlement settlement) {
    state = [settlement, ...state];
  }

  void verify(String id) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(status: SettlementStatus.verified) else s,
    ];
  }

  void reject(String id, {String? reason}) {
    state = [
      for (final s in state)
        if (s.id == id)
          s.copyWith(status: SettlementStatus.rejected, rejectionReason: reason)
        else
          s,
    ];
  }

  void updateTransactionId(String id, String transactionId) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(transactionId: transactionId) else s,
    ];
  }
}

// ─── Derived: net balance across all groups ───────────────────────────────────

final overallBalanceProvider = Provider<Map<String, double>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return {'owe': 0, 'owed': 0, 'net': 0};

  final expenses = ref.watch(groupExpenseProvider);
  final settlements = ref.watch(settlementProvider);

  double owe = 0.0;
  double owed = 0.0;

  for (final ex in expenses) {
    if (ex.paidById == user.id) {
      for (final entry in ex.splitDetails.entries) {
        if (entry.key != user.id) owed += entry.value;
      }
    } else if (ex.splitDetails.containsKey(user.id)) {
      owe += ex.splitDetails[user.id]!;
    }
  }

  // Reduce balances by verified settlements
  for (final s in settlements.where((s) => s.isVerified)) {
    if (s.fromUserId == user.id) owe -= s.amount;
    if (s.toUserId == user.id) owed -= s.amount;
  }

  owe = owe < 0 ? 0 : owe;
  owed = owed < 0 ? 0 : owed;

  return {
    'owe': owe,
    'owed': owed,
    'net': owed - owe,
  };
});

// ─── Derived: per-friend net balance ─────────────────────────────────────────
/// Returns a map of userId → net amount.
/// Positive = that person owes current user.
/// Negative = current user owes that person.
final friendBalanceProvider = Provider<Map<String, double>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return {};

  final expenses = ref.watch(groupExpenseProvider);
  final settlements = ref.watch(settlementProvider);

  final Map<String, double> balance = {};

  void addBalance(String friendId, double amount) {
    balance[friendId] = (balance[friendId] ?? 0) + amount;
  }

  // From group expenses
  for (final ex in expenses) {
    if (ex.paidById == user.id) {
      // Current user paid, others owe them
      for (final entry in ex.splitDetails.entries) {
        if (entry.key != user.id) {
          addBalance(entry.key, entry.value); // friend owes us
        }
      }
    } else if (ex.splitDetails.containsKey(user.id)) {
      // Current user owes the payer
      addBalance(ex.paidById, -ex.splitDetails[user.id]!); // we owe payer
    }
  }

  // Adjust by verified settlements
  for (final s in settlements.where((s) => s.isVerified)) {
    if (s.fromUserId == user.id) {
      // We paid some friend
      addBalance(s.toUserId, s.amount); // reduces what they owed us, or reduces what we owe
    } else if (s.toUserId == user.id) {
      // A friend paid us
      addBalance(s.fromUserId, -s.amount);
    }
  }

  return balance;
});

// ─── Derived: per-friend settlements ─────────────────────────────────────────

final settlementsWithFriendProvider =
    Provider.family<List<Settlement>, String>((ref, friendId) {
  final user = ref.watch(authProvider);
  if (user == null) return [];
  final all = ref.watch(settlementProvider);
  return all
      .where((s) =>
          (s.fromUserId == user.id && s.toUserId == friendId) ||
          (s.toUserId == user.id && s.fromUserId == friendId))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

// ─── Derived: debt simplification suggestions ─────────────────────────────────

final debtSuggestionsProvider =
    Provider.family<List<DebtSuggestion>, String>((ref, groupId) {
  final expenses = ref.watch(groupExpensesByGroupProvider(groupId));
  final group = ref.watch(groupProvider).firstWhere(
        (g) => g.id == groupId,
        orElse: () => throw Exception('Group not found'),
      );

  // Respect the group's smart split setting
  if (!group.smartSplitEnabled) return [];

  return DebtSimplifier.simplify(expenses, group.memberIds);
});

// ─── User's pending settlements ───────────────────────────────────────────────

final userSettlementsProvider = Provider<List<Settlement>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return [];
  final all = ref.watch(settlementProvider);
  return all
      .where((s) => s.fromUserId == user.id || s.toUserId == user.id)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final pendingSettlementsProvider = Provider<List<Settlement>>((ref) {
  final all = ref.watch(userSettlementsProvider);
  return all.where((s) => s.isPending).toList();
});
