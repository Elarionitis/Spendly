import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/models/group_expense.dart';
import '../auth/auth_provider.dart';
import '../groups/group_provider.dart';
import '../comments/comment_sheet.dart';
import '../comments/comment_provider.dart';

/// Full-detail view for a single group expense.
/// Route: /groups/:id/expense/:expenseId
class TransactionDetailScreen extends ConsumerWidget {
  final String groupId;
  final String expenseId;

  const TransactionDetailScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(groupExpensesByGroupProvider(groupId));
    final expenseIdx = expenses.indexWhere((e) => e.id == expenseId);
    if (expenseIdx == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense')),
        body: const Center(child: Text('Expense not found')),
      );
    }
    final expense = expenses[expenseIdx];
    final groups = ref.watch(groupProvider);
    final group = groups.cast<dynamic>().firstWhere(
          (g) => g.id == groupId,
          orElse: () => null,
        );
    final users = ref.watch(usersDataProvider);
    final currentUser = ref.watch(authProvider);
    final comments = ref.watch(commentsForTargetProvider(expenseId));

    String userName(String uid) {
      final u = users.cast<dynamic>().firstWhere(
            (u) => u.id == uid,
            orElse: () => null,
          );
      if (u == null) return uid;
      if (uid == currentUser?.id) return 'You';
      return u.name.toString();
    }

    final paidByName = userName(expense.paidById);
    final isPaidByMe = expense.paidById == currentUser?.id;
    final myShare = expense.splitDetails[currentUser?.id] ?? 0.0;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(expense.description),
        actions: [
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit coming soon')),
              );
            },
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, color: SpendlyColors.danger),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref, expense),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                // ── Amount hero ────────────────────────────────────────────
                SpendlyCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        expense.category.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expense.description,
                        style: AppTextStyles.heading2(),
                        textAlign: TextAlign.center,
                      ),
                      if (group != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(group.emoji ?? '👥',
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                group.name.toString(),
                                style: AppTextStyles.caption(
                                    color: SpendlyColors.neutral500),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        AppFormatters.currency(expense.amount),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: SpendlyColors.primary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Added on ${AppFormatters.fullDate(expense.date)}',
                        style: AppTextStyles.caption(
                            color: SpendlyColors.neutral400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Paid by ────────────────────────────────────────────────
                SpendlyCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      UserAvatar(
                          name: users.cast<dynamic>().firstWhere(
                                (u) => u.id == expense.paidById,
                                orElse: () => null,
                              )?.name?.toString() ?? expense.paidById,
                          userId: expense.paidById,
                          size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$paidByName paid',
                              style: AppTextStyles.bodyPrimary()
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(AppFormatters.currency(expense.amount),
                                style: AppTextStyles.caption(
                                    color: SpendlyColors.neutral500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Split breakdown ────────────────────────────────────────
                SpendlyCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Split details',
                          style: AppTextStyles.sectionLabel()),
                      const SizedBox(height: 12),
                      ...expense.splitDetails.entries.map((entry) {
                        final memberId = entry.key;
                        final share = entry.value;
                        final name = userName(memberId);
                        final isPayer = memberId == expense.paidById;
                        final isMe = memberId == currentUser?.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              UserAvatar(
                                  name: users.cast<dynamic>().firstWhere(
                                            (u) => u.id == memberId,
                                            orElse: () => null,
                                          )?.name?.toString() ?? memberId,
                                  userId: memberId,
                                  size: 32),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: AppTextStyles.bodyPrimary()
                                            .copyWith(
                                                fontWeight: FontWeight.w600)),
                                    Text(
                                      isPayer
                                          ? 'Paid the bill'
                                          : '${isMe ? 'You owe' : '$name owes'} ${AppFormatters.currency(share)}',
                                      style: AppTextStyles.caption(
                                          color: isPayer
                                              ? SpendlyColors.success
                                              : SpendlyColors.danger),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppFormatters.currency(share),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isPayer
                                      ? SpendlyColors.neutral700
                                      : SpendlyColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Summary for current user
                      const Divider(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPaidByMe
                              ? SpendlyColors.success.withAlpha(15)
                              : SpendlyColors.danger.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPaidByMe
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isPaidByMe
                                  ? SpendlyColors.success
                                  : SpendlyColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isPaidByMe
                                    ? '$paidByName paid ${AppFormatters.currency(expense.amount)} · you get back ${AppFormatters.currency(expense.amount - myShare)}'
                                    : '$paidByName paid · you owe ${AppFormatters.currency(myShare)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isPaidByMe
                                      ? SpendlyColors.success
                                      : SpendlyColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Notes ──────────────────────────────────────────────────
                if (expense.notes != null && expense.notes!.isNotEmpty)
                  SpendlyCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes', style: AppTextStyles.sectionLabel()),
                        const SizedBox(height: 8),
                        Text(expense.notes!,
                            style: AppTextStyles.bodySecondary()),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Comments section header ────────────────────────────────
                Row(
                  children: [
                    Text('Comments', style: AppTextStyles.sectionLabel()),
                    const Spacer(),
                    Text('${comments.length}',
                        style: AppTextStyles.caption(
                            color: SpendlyColors.neutral500)),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Comment list (inline) ──────────────────────────────────
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No comments yet. Be first!',
                          style: AppTextStyles.caption(
                              color: SpendlyColors.neutral400)),
                    ),
                  )
                else
                  ...comments.map((c) {
                    final commenterUser = users.cast<dynamic>().firstWhere(
                          (u) => u.id == c.userId,
                          orElse: () => null,
                        );
                    final commenterName =
                        commenterUser?.name?.toString() ?? c.userId;
                    final isMe = c.userId == currentUser?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserAvatar(
                              name: commenterName, userId: c.userId, size: 32),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? SpendlyColors.primary.withAlpha(12)
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        commenterName.split(' ').first,
                                        style: AppTextStyles.caption(
                                                color: SpendlyColors.neutral700)
                                            .copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _timeAgo(c.timestamp),
                                        style: AppTextStyles.caption(
                                            color: SpendlyColors.neutral400),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(c.message,
                                      style: AppTextStyles.bodySecondary()),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 80), // space for FAB
              ],
            ),
          ),
        ],
      ),

      // ── Add comment FAB ──────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCommentsSheet(context, ref, expenseId, 'expense'),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Add Comment'),
        backgroundColor: SpendlyColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, GroupExpense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(
            'Delete "${expense.description}" (${AppFormatters.currency(expense.amount)})? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref
                  .read(groupExpenseProvider.notifier)
                  .removeExpense(expense.id);
              Navigator.pop(ctx);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: SpendlyColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}
