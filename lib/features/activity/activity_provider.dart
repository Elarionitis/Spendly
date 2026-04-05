import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/activity_event.dart';
import '../../core/models/app_user.dart';
import '../groups/group_provider.dart';
import '../settlements/settlement_provider.dart';
import '../auth/auth_provider.dart';
import '../expenses/expense_provider.dart';

/// Derived activity feed: every group expense + settlement, sorted by timestamp descending.
final activityProvider = Provider<List<ActivityEvent>>((ref) {
  final user = ref.watch(authProvider);
  final currentUserId = user?.id ?? 'u1';
  final usersAsync = ref.watch(allUsersProvider);
  final users = usersAsync.value ?? <AppUser>[];

  String userName(String uid) {
    final u = users.cast<dynamic>().firstWhere(
          (u) => u.id == uid,
          orElse: () => null,
        );
    if (u == null) return uid;
    if (uid == currentUserId) return 'You';
    return u.name.toString().split(' ').first;
  }

  final events = <ActivityEvent>[];

  // ── Expenses (All: Group + Personal) ───────────────────────────────────────
  final expenses = ref.watch(expenseProvider);
  final groups = ref.watch(groupProvider);

  String groupName(String groupId) {
    final g = groups.cast<dynamic>().firstWhere(
          (g) => g.id == groupId,
          orElse: () => null,
        );
    return g?.name?.toString() ?? '';
  }

  for (final e in expenses) {
    final payer = userName(e.paidById);
    final grpName = groupName(e.groupId ?? '');
    final isCurrentUserPayer = e.paidById == currentUserId;

    // How much does the current user owe or get back from this expense?
    final myShare = e.splitDetails[currentUserId] ?? 0.0;
    final othersOwe = e.splitDetails.entries
        .where((entry) => entry.key != e.paidById)
        .fold(0.0, (sum, entry) => sum + entry.value);

    String amountNote;
    if (isCurrentUserPayer) {
      amountNote = othersOwe > 0 ? 'you get back ₹${othersOwe.toStringAsFixed(0)}' : '';
    } else if (myShare > 0) {
      amountNote = 'you owe ₹${myShare.toStringAsFixed(0)}';
    } else {
      amountNote = '';
    }

    events.add(ActivityEvent(
      id: 'ae_ex_${e.id}',
      userId: e.paidById,
      type: ActivityType.expenseAdded,
      description:
          '$payer added "${e.description}"${grpName.isNotEmpty ? ' in "$grpName"' : ''}.'
          '${amountNote.isNotEmpty ? '\n$amountNote' : ''}',
      timestamp: e.date,
      metadata: {
        'amount': e.amount,
        'expenseId': e.id,
        'groupId': e.groupId,
        'isCurrentUserPayer': isCurrentUserPayer,
        'myShare': myShare,
      },
    ));
  }

  // ── Settlements ────────────────────────────────────────────────────────────
  final settlements = ref.watch(settlementProvider);

  for (final s in settlements) {
    final from = userName(s.fromUserId);
    final to = userName(s.toUserId);
    final isIncoming = s.toUserId == currentUserId;
    final isOutgoing = s.fromUserId == currentUserId;

    String desc;
    if (isOutgoing) {
      desc = 'You paid $to ₹${s.amount.toStringAsFixed(0)}.';
    } else if (isIncoming) {
      desc = '$from paid you ₹${s.amount.toStringAsFixed(0)}.';
    } else {
      desc = '$from paid $to ₹${s.amount.toStringAsFixed(0)}.';
    }
    if (!s.isVerified) desc += ' (${s.isPending ? "pending" : "rejected"})';

    events.add(ActivityEvent(
      id: 'ae_st_${s.id}',
      userId: s.fromUserId,
      type: ActivityType.settled,
      description: desc,
      timestamp: s.createdAt,
      metadata: {
        'amount': s.amount,
        'isIncoming': isIncoming,
        'isVerified': s.isVerified,
      },
    ));
  }

  // Sort newest first
  events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return events;
});
