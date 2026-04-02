import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/group.dart';
import '../../core/models/group_expense.dart';
import '../../core/models/enums.dart';
import '../auth/auth_provider.dart';

// ─── Group Provider ──────────────────────────────────────────────────────────

final groupProvider = StateNotifierProvider<GroupNotifier, List<Group>>((ref) {
  return GroupNotifier(ref);
});

class GroupNotifier extends StateNotifier<List<Group>> {
  final Ref _ref;

  GroupNotifier(this._ref) : super([]) {
    _seedData();
  }

  void _seedData() {
    final currentUserId = _ref.read(authProvider)?.id ?? 'u1';
    state = [
      Group(
        id: 'g1',
        name: 'Goa Trip 2025',
        description: 'Beach holiday with friends',
        createdById: currentUserId,
        memberIds: [currentUserId, 'u2', 'u3', 'u4'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        emoji: '🏖️',
      ),
      Group(
        id: 'g2',
        name: 'Apartment Rent',
        description: 'Monthly shared expenses',
        createdById: currentUserId,
        memberIds: [currentUserId, 'u2', 'u3'],
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        emoji: '🏠',
      ),
      Group(
        id: 'g3',
        name: 'Office Lunch',
        description: 'Daily office meals',
        createdById: 'u2',
        memberIds: [currentUserId, 'u2', 'u4'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        emoji: '🍱',
      ),
    ];
  }

  void addGroup(Group group) => state = [...state, group];

  void updateGroup(Group updatedGroup) {
    state = [
      for (final g in state)
        if (g.id == updatedGroup.id) updatedGroup else g,
    ];
  }

  void removeGroup(String id) =>
      state = state.where((g) => g.id != id).toList();

  void addMember(String groupId, String userId) {
    final group = state.firstWhere((g) => g.id == groupId);
    if (!group.memberIds.contains(userId)) {
      updateGroup(group.copyWith(memberIds: [...group.memberIds, userId]));
    }
  }

  void removeMember(String groupId, String userId) {
    final group = state.firstWhere((g) => g.id == groupId);
    updateGroup(group.copyWith(
      memberIds: group.memberIds.where((id) => id != userId).toList(),
    ));
  }

  void updateSmartSplit(String groupId, bool enabled) {
    final group = state.firstWhere((g) => g.id == groupId);
    updateGroup(group.copyWith(smartSplitEnabled: enabled));
  }

  void updateDefaultSplitType(String groupId, SplitType splitType) {
    final group = state.firstWhere((g) => g.id == groupId);
    updateGroup(group.copyWith(defaultSplitType: splitType));
  }
}

// ─── Group Expense Provider ───────────────────────────────────────────────────

final groupExpenseProvider =
    StateNotifierProvider<GroupExpenseNotifier, List<GroupExpense>>((ref) {
  return GroupExpenseNotifier(ref);
});

class GroupExpenseNotifier extends StateNotifier<List<GroupExpense>> {
  final Ref _ref;

  GroupExpenseNotifier(this._ref) : super([]) {
    _seedData();
  }

  void _seedData() {
    final currentUserId = _ref.read(authProvider)?.id ?? 'u1';
    final now = DateTime.now();

    state = [
      // Goa Trip expenses
      GroupExpense(
        id: 'ge1',
        groupId: 'g1',
        description: 'Hotel Booking',
        amount: 12000,
        paidById: currentUserId,
        splitDetails: {
          currentUserId: 3000,
          'u2': 3000,
          'u3': 3000,
          'u4': 3000,
        },
        splitType: SplitType.equal,
        category: ExpenseCategory.accommodation,
        date: now.subtract(const Duration(days: 28)),
      ),
      GroupExpense(
        id: 'ge2',
        groupId: 'g1',
        description: 'Flight Tickets',
        amount: 24000,
        paidById: 'u2',
        splitDetails: {
          currentUserId: 6000,
          'u2': 6000,
          'u3': 6000,
          'u4': 6000,
        },
        splitType: SplitType.equal,
        category: ExpenseCategory.travel,
        date: now.subtract(const Duration(days: 27)),
      ),
      GroupExpense(
        id: 'ge3',
        groupId: 'g1',
        description: 'Beach Restaurant',
        amount: 4500,
        paidById: 'u3',
        splitDetails: {
          currentUserId: 1125,
          'u2': 1125,
          'u3': 1125,
          'u4': 1125,
        },
        splitType: SplitType.equal,
        category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 25)),
      ),
      GroupExpense(
        id: 'ge4',
        groupId: 'g1',
        description: 'Water Sports',
        amount: 3000,
        paidById: currentUserId,
        splitDetails: {
          currentUserId: 750,
          'u2': 1500,
          'u4': 750,
        },
        splitType: SplitType.exact,
        category: ExpenseCategory.entertainment,
        date: now.subtract(const Duration(days: 24)),
      ),
      // Apartment expenses
      GroupExpense(
        id: 'ge5',
        groupId: 'g2',
        description: 'Monthly Rent',
        amount: 45000,
        paidById: currentUserId,
        splitDetails: {
          currentUserId: 15000,
          'u2': 15000,
          'u3': 15000,
        },
        splitType: SplitType.equal,
        category: ExpenseCategory.accommodation,
        date: now.subtract(const Duration(days: 5)),
      ),
      GroupExpense(
        id: 'ge6',
        groupId: 'g2',
        description: 'Electricity Bill',
        amount: 3600,
        paidById: 'u2',
        splitDetails: {
          currentUserId: 1200,
          'u2': 1200,
          'u3': 1200,
        },
        splitType: SplitType.equal,
        category: ExpenseCategory.utilities,
        date: now.subtract(const Duration(days: 3)),
      ),
      // Office lunch expenses
      GroupExpense(
        id: 'ge7',
        groupId: 'g3',
        description: 'Pizza Party',
        amount: 1800,
        paidById: 'u2',
        splitDetails: {
          currentUserId: 600,
          'u2': 600,
          'u4': 600,
        },
        splitType: SplitType.equal,
        category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 2)),
      ),
      GroupExpense(
        id: 'ge8',
        groupId: 'g3',
        description: 'Coffee & Snacks',
        amount: 450,
        paidById: currentUserId,
        splitDetails: {
          currentUserId: 150,
          'u2': 150,
          'u4': 150,
        },
        splitType: SplitType.equal,
        category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  void addExpense(GroupExpense expense) {
    state = [expense, ...state];
  }

  void updateExpense(GroupExpense updatedExpense) {
    state = [
      for (final e in state)
        if (e.id == updatedExpense.id) updatedExpense else e,
    ];
  }

  void removeExpense(String id) =>
      state = state.where((e) => e.id != id).toList();
}

// ─── Derived: expenses per group ─────────────────────────────────────────────

final groupExpensesByGroupProvider =
    Provider.family<List<GroupExpense>, String>((ref, groupId) {
  final expenses = ref.watch(groupExpenseProvider);
  return expenses.where((e) => e.groupId == groupId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

// ─── Derived: net balance per group per user ──────────────────────────────────

final groupNetBalanceProvider =
    Provider.family<Map<String, double>, String>((ref, groupId) {
  final expenses = ref.watch(groupExpensesByGroupProvider(groupId));
  final group = ref.watch(groupProvider).firstWhere(
        (g) => g.id == groupId,
        orElse: () => Group(
          id: '',
          name: '',
          description: '',
          createdById: '',
          memberIds: [],
          createdAt: DateTime.now(),
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

  return net;
});
