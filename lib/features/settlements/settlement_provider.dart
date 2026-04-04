import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/settlement.dart';
import '../../core/models/enums.dart';
import '../../core/utils/debt_simplifier.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/repositories/settlement_repository.dart';
import '../auth/auth_provider.dart';
import '../groups/group_provider.dart';

// ─── Settlement Notifier ──────────────────────────────────────────────────────

final settlementProvider =
    StateNotifierProvider<SettlementNotifier, List<Settlement>>((ref) {
  return SettlementNotifier(ref.watch(settlementRepositoryProvider), ref);
});

class SettlementNotifier extends StateNotifier<List<Settlement>> {
  final SettlementRepository _repo;
  final Ref _ref;

  SettlementNotifier(this._repo, this._ref) : super([]) {
    final userId = _ref.read(authProvider)?.id;
    if (userId != null) {
      _repo.watchSettlements(userId).listen((settlements) => state = settlements);
    }
  }

  Future<void> initiateSettlement(Settlement settlement) =>
      _repo.addSettlement(settlement);

  Future<void> verify(String id) =>
      _repo.updateStatus(id, SettlementStatus.verified);

  Future<void> reject(String id, {String? reason}) =>
      _repo.updateStatus(id, SettlementStatus.rejected, rejectionReason: reason);

  Future<void> updateTransactionId(String id, String transactionId) =>
      _repo.updateTransactionId(id, transactionId);
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

  for (final s in settlements.where((s) => s.isVerified)) {
    if (s.fromUserId == user.id) owe -= s.amount;
    if (s.toUserId == user.id) owed -= s.amount;
  }

  owe = owe < 0 ? 0 : owe;
  owed = owed < 0 ? 0 : owed;

  return {'owe': owe, 'owed': owed, 'net': owed - owe};
});

// ─── Derived: per-friend net balance ─────────────────────────────────────────

final friendBalanceProvider = Provider<Map<String, double>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return {};

  final expenses = ref.watch(groupExpenseProvider);
  final settlements = ref.watch(settlementProvider);

  final Map<String, double> balance = {};

  void addBalance(String friendId, double amount) {
    balance[friendId] = (balance[friendId] ?? 0) + amount;
  }

  for (final ex in expenses) {
    if (ex.paidById == user.id) {
      for (final entry in ex.splitDetails.entries) {
        if (entry.key != user.id) addBalance(entry.key, entry.value);
      }
    } else if (ex.splitDetails.containsKey(user.id)) {
      addBalance(ex.paidById, -ex.splitDetails[user.id]!);
    }
  }

  for (final s in settlements.where((s) => s.isVerified)) {
    if (s.fromUserId == user.id) {
      addBalance(s.toUserId, s.amount);
    } else if (s.toUserId == user.id) {
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

// ─── Derived: debt simplification ────────────────────────────────────────────

final debtSuggestionsProvider =
    Provider.family<List<DebtSuggestion>, String>((ref, groupId) {
  final expenses = ref.watch(groupExpensesByGroupProvider(groupId));
  final groups = ref.watch(groupProvider);
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => throw Exception('Group not found'),
  );
  if (!group.smartSplitEnabled) return [];
  return DebtSimplifier.simplify(expenses, group.memberIds);
});

// ─── User's settlements ───────────────────────────────────────────────────────

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
