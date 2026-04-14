import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import 'settlement_provider.dart';

/// Multi-step settlement selection screen.
/// Shows group-wise balance breakdown with "Settle all" or per-group options.
class BalanceSelectionScreen extends ConsumerWidget {
  final String friendUserId;
  const BalanceSelectionScreen({super.key, required this.friendUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendUser = ref.watch(userByIdProvider(friendUserId));
    final totalBalance = ref.watch(globalBalancesProvider)[friendUserId] ?? 0.0;
    final groupBreakdown = ref.watch(groupBalancesWithFriendProvider(friendUserId));
    final friendName = friendUser?.name ?? 'Friend';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a balance to settle'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Friend Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: SpendlyColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                UserAvatar(name: friendName, userId: friendUserId, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        totalBalance > 0
                            ? 'owes you ₹${totalBalance.abs().toStringAsFixed(2)}'
                            : totalBalance < 0
                                ? 'you owe ₹${totalBalance.abs().toStringAsFixed(2)}'
                                : 'all settled up ✓',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Settle All ──────────────────────────────────────────────────
          if (totalBalance.abs() >= 0.01) ...[
            _SettleOption(
              emoji: '⚡',
              title: 'Settle all balances',
              subtitle: totalBalance > 0
                  ? '${friendName.split(' ').first} owes you ₹${totalBalance.abs().toStringAsFixed(2)}'
                  : 'You owe ₹${totalBalance.abs().toStringAsFixed(2)}',
              amount: totalBalance,
              isHighlighted: true,
              onTap: () => context.push(
                '/settle?userId=$friendUserId',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR settle by group',
                      style: AppTextStyles.caption(color: SpendlyColors.neutral500),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
          ],

          // ── Per-group breakdown ─────────────────────────────────────────
          if (groupBreakdown.isEmpty && totalBalance.abs() < 0.01)
            Padding(
              padding: const EdgeInsets.all(32),
              child: EmptyState(
                icon: Icons.check_circle_outline,
                title: 'All settled!',
                subtitle: 'You have no outstanding balances with $friendName',
              ),
            )
          else
            ...groupBreakdown.map((item) {
              final balance = item['balance'] as double;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SettleOption(
                  emoji: item['emoji'] as String,
                  title: item['groupName'] as String,
                  subtitle: balance > 0
                      ? '${friendName.split(' ').first} owes you ₹${balance.abs().toStringAsFixed(2)}'
                      : 'you owe ₹${balance.abs().toStringAsFixed(2)}',
                  amount: balance,
                  isHighlighted: false,
                  onTap: () {
                    final groupId = item['groupId'] as String;
                    context.push(
                      '/settle?userId=$friendUserId&groupId=${groupId == '__personal__' ? '' : groupId}',
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SettleOption extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final double amount;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SettleOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOwed = amount > 0;
    final color = isOwed ? SpendlyColors.success : SpendlyColors.danger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted
              ? SpendlyColors.primary.withAlpha(10)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted
                ? SpendlyColors.primary.withAlpha(50)
                : SpendlyColors.neutral200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? SpendlyColors.primary.withAlpha(20)
                    : color.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyPrimary().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(color: color),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SpendlyColors.neutral400,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
