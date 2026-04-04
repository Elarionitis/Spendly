import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/group.dart';
import '../../core/models/group_expense.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/repositories/group_repository.dart';
import '../../core/repositories/expense_repository.dart';
import '../../core/models/enums.dart';
import '../auth/auth_provider.dart';

// ─── Groups ───────────────────────────────────────────────────────────────────

final groupProvider =
    StateNotifierProvider<GroupNotifier, List<Group>>((ref) {
  return GroupNotifier(ref.watch(groupRepositoryProvider), ref);
});

class GroupNotifier extends StateNotifier<List<Group>> {
  final GroupRepository _repo;
  final Ref _ref;

  GroupNotifier(this._repo, this._ref) : super([]) {
    final userId = _ref.read(authProvider)?.id;
    if (userId != null) {
      _repo.watchGroups(userId).listen((groups) => state = groups);
    }
  }

  Future<void> addGroup(Group group) => _repo.createGroup(group);
  Future<void> updateGroup(Group group) => _repo.updateGroup(group);
  Future<void> removeGroup(String id) => _repo.deleteGroup(id);

  Future<void> addMember(String groupId, String userId) {
    final group = state.firstWhere((g) => g.id == groupId);
    if (!group.memberIds.contains(userId)) {
      return _repo.updateGroup(
          group.copyWith(memberIds: [...group.memberIds, userId]));
    }
    return Future.value();
  }

  Future<void> removeMember(String groupId, String userId) {
    final group = state.firstWhere((g) => g.id == groupId);
    return _repo.updateGroup(group.copyWith(
      memberIds: group.memberIds.where((id) => id != userId).toList(),
    ));
  }

  Future<void> updateSmartSplit(String groupId, bool enabled) {
    final group = state.firstWhere((g) => g.id == groupId);
    return _repo.updateGroup(group.copyWith(smartSplitEnabled: enabled));
  }

  Future<void> updateDefaultSplitType(String groupId, SplitType splitType) {
    final group = state.firstWhere((g) => g.id == groupId);
    return _repo.updateGroup(group.copyWith(defaultSplitType: splitType));
  }
}

// ─── Group Expenses ───────────────────────────────────────────────────────────

final groupExpenseProvider =
    StateNotifierProvider<GroupExpenseNotifier, List<GroupExpense>>((ref) {
  return GroupExpenseNotifier(ref.watch(expenseRepositoryProvider));
});

class GroupExpenseNotifier extends StateNotifier<List<GroupExpense>> {
  final ExpenseRepository _repo;
  final Map<String, void Function()> _listeners = {};

  GroupExpenseNotifier(this._repo) : super([]);

  /// Subscribe to real-time expenses for this group.
  void subscribeToGroup(String groupId) {
    if (_listeners.containsKey(groupId)) return; // already subscribed
    final sub = _repo.watchExpenses(groupId).listen((expenses) {
      final others = state.where((e) => e.groupId != groupId).toList();
      state = [...others, ...expenses];
    });
    _listeners[groupId] = sub.cancel;
  }

  /// Subscribe to all relevant groups for global analytics.
  void subscribeToAll(List<String> groupIds) {
    for (final id in groupIds) {
      subscribeToGroup(id);
    }
  }

  Future<void> addExpense(GroupExpense expense, {dynamic imageFile}) =>
      _repo.addExpense(expense, imageFile: imageFile);

  Future<void> updateExpense(GroupExpense expense) =>
      _repo.updateExpense(expense);

  Future<void> removeExpense(String id) {
    final expense = state.firstWhere((e) => e.id == id);
    return _repo.deleteExpense(expense.groupId, id);
  }

  @override
  void dispose() {
    for (final cancel in _listeners.values) {
      cancel();
    }
    super.dispose();
  }
}

// ─── Derived: expenses per group ─────────────────────────────────────────────

final groupExpensesByGroupProvider =
    Provider.family<List<GroupExpense>, String>((ref, groupId) {
  // Ensure subscription is active for this group
  ref.read(groupExpenseProvider.notifier).subscribeToGroup(groupId);

  final expenses = ref.watch(groupExpenseProvider);
  return expenses.where((e) => e.groupId == groupId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

// ─── Derived: net balance per group per user ──────────────────────────────────

final groupNetBalanceProvider =
    Provider.family<Map<String, double>, String>((ref, groupId) {
  final expenses = ref.watch(groupExpensesByGroupProvider(groupId));
  final groups = ref.watch(groupProvider);

  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => Group(
      id: '', name: '', description: '',
      createdById: '', memberIds: [], createdAt: DateTime.now(),
    ),
  );

  final Map<String, double> net = {for (var id in group.memberIds) id: 0.0};

  for (final expense in expenses) {
    for (final entry in expense.splitDetails.entries) {
      final uid = entry.key;
      final amt = entry.value;
      if (uid == expense.paidById) continue;
      net[expense.paidById] = (net[expense.paidById] ?? 0) + amt;
      net[uid] = (net[uid] ?? 0) - amt;
    }
  }
// ─── Friends (Shared Group Visibility) ────────────────────────────────────────

/// Provides only the users who share at least one group with the current user.
final friendsProvider = Provider<List<AppUser>>((ref) {
  final allUsers = ref.watch(allUsersProvider).value ?? [];
  final groups = ref.watch(groupProvider);
  final currentUser = ref.watch(authProvider);

  if (currentUser == null) return [];

  final sharedUserIds = <String>{};
  for (final group in groups) {
    if (group.memberIds.contains(currentUser.id)) {
      sharedUserIds.addAll(group.memberIds);
    }
  }
  
  sharedUserIds.remove(currentUser.id); // remove self

  return allUsers.where((u) => sharedUserIds.contains(u.id)).toList();
});

  return net;
});
