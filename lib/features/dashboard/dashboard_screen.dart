import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import '../settlements/settlement_provider.dart';
import '../groups/group_provider.dart';
import '../expenses/expense_provider.dart';
import '../../core/models/enums.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final settlementsAsync = ref.watch(settlementsStreamProvider);
    final groupsAsync = ref.watch(groupsStreamProvider);
    final groups = groupsAsync.value ?? [];

    // Inline balance calculation for real-time reactivity if needed, 
    // or just rely on the existing globalBalancesProvider which watches these.
    final balance = ref.watch(overallBalanceProvider);
    final owe = balance['owe'] ?? 0.0;
    final owed = balance['owed'] ?? 0.0;
    final net = balance['net'] ?? 0.0;

    final settlements = settlementsAsync.value ?? [];
    final pendingSettlements = settlements.where((s) => s.isPending && s.toUserId == user?.id).toList();
    final recentPersonal = (expensesAsync.value ?? []).where((e) => e.type == ExpenseType.personal).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              user?.name.split(' ').first ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showProfileMenu(context, ref),
                        child: UserAvatar(
                          name: user?.name ?? 'User',
                          userId: user?.id ?? 'u1',
                          size: 44,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 28),
                  // Net balance card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Net Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.currency(net.abs()),
                          style: TextStyle(
                            color: net >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          net >= 0 ? 'You are owed money' : 'You owe money',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  // Owe / Owed split
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniBalanceCard(
                          'You Owe',
                          owe,
                          const Color(0xFFF87171),
                          Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniBalanceCard(
                          'Owed to You',
                          owed,
                          const Color(0xFF34D399),
                          Icons.arrow_downward_rounded,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),

          // ─── Quick Actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildActionTile(
                        context,
                        icon: Icons.add_rounded,
                        label: 'Add\nExpense',
                        color: SpendlyColors.primary,
                        onTap: () => context.go('/groups'),
                      ),
                      const SizedBox(width: 12),
                      _buildActionTile(
                        context,
                        icon: Icons.group_add_rounded,
                        label: 'New\nGroup',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => context.go('/groups/add'),
                      ),
                      const SizedBox(width: 12),
                      _buildActionTile(
                        context,
                        icon: Icons.handshake_rounded,
                        label: 'Settle\nUp',
                        color: const Color(0xFF10B981),
                        onTap: () => context.go('/settle'),
                      ),
                      const SizedBox(width: 12),
                      _buildActionTile(
                        context,
                        icon: Icons.bar_chart_rounded,
                        label: 'Analytics',
                        color: const Color(0xFFF59E0B),
                        onTap: () => context.go('/analytics'),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ),

          // ─── Pending Settlements ──────────────────────────────────────────
          if (pendingSettlements.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Pending Settlements',
                      actionLabel: 'View All',
                      onAction: () => context.go('/settlements'),
                    ),
                    const SizedBox(height: 12),
                    ...pendingSettlements.take(2).map(
                          (s) => _buildSettlementAlert(context, ref, s),
                        ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),

          // ─── Your Groups ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: SectionHeader(
                title: 'Your Groups',
                actionLabel: 'See All',
                onAction: () => context.go('/groups'),
              ),
            ).animate().fadeIn(delay: 550.ms),
          ),
          if (groups.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SpendlyCard(
                  child: EmptyState(
                    icon: Icons.group_outlined,
                    title: 'No groups yet',
                    subtitle: 'Create a group to start splitting expenses',
                    actionLabel: 'Create Group',
                    onAction: () => context.go('/groups/add'),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final group = groups[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildGroupCard(context, ref, group),
                    ).animate().fadeIn(delay: (600 + index * 80).ms);
                  },
                  childCount: groups.take(3).length,
                ),
              ),
            ),

          // ─── Recent Personal Expenses ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: SectionHeader(
                title: 'Recent Spending',
                actionLabel: 'See All',
                onAction: () => context.go('/personal'),
              ),
            ).animate().fadeIn(delay: 700.ms),
          ),
          if (recentPersonal.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SpendlyCard(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No personal expenses',
                    subtitle: 'Track your personal spending separately',
                    actionLabel: 'Add Expense',
                    onAction: () => context.go('/personal/add'),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final e = recentPersonal[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SpendlyCard(
                        onTap: () => context.go('/personal/add', extra: {'expenseId': e.id}),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: SpendlyColors.chartColors[
                                        e.category.index %
                                            SpendlyColors.chartColors.length]
                                    .withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  e.category.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    e.category.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: SpendlyColors.neutral500),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppFormatters.currency(e.amount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: SpendlyColors.danger),
                                ),
                                Text(
                                  AppFormatters.relativeDate(e.date),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: SpendlyColors.neutral500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (750 + index * 60).ms);
                  },
                  childCount: recentPersonal.take(5).length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMiniBalanceCard(
      String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.currency(amount),
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: SpendlyCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, WidgetRef ref, group) {
    return SpendlyCard(
      onTap: () => context.go('/groups/${group.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: SpendlyColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                group.emoji ?? group.name[0],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${group.memberIds.length} members',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: SpendlyColors.neutral500),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: SpendlyColors.neutral400),
        ],
      ),
    );
  }

  Widget _buildSettlementAlert(BuildContext context, WidgetRef ref, settlement) {
    final user = ref.read(authProvider);
    final isReceiving = settlement.toUserId == user?.id;
    final hasApproved = settlement.approvals.contains(user?.id);
    final hasRejected = settlement.rejections.contains(user?.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SpendlyCard(
        backgroundColor: isReceiving
            ? SpendlyColors.success.withAlpha(10)
            : SpendlyColors.warning.withAlpha(10),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isReceiving
                      ? Icons.arrow_circle_down_rounded
                      : Icons.arrow_circle_up_rounded,
                  color: isReceiving ? SpendlyColors.success : SpendlyColors.warning,
                  size: 36,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceiving
                            ? 'Incoming payment of ${AppFormatters.currency(settlement.amount)}'
                            : 'You owe ${AppFormatters.currency(settlement.amount)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                StatusBadge.pending(),
              ],
            ),
            if (isReceiving && !hasApproved && !hasRejected) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DashboardSettlementAction(
                      label: 'Reject',
                      isPrimary: false,
                      onPressed: () => ref.read(settlementActionProvider).rejectSettlement(settlement.id, user!.id),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DashboardSettlementAction(
                      label: 'Verify',
                      isPrimary: true,
                      onPressed: () => ref.read(settlementActionProvider).approveSettlement(settlement.id, user!.id),
                    ),
                  ),
                ],
              ),
            ] else if (isReceiving && hasApproved) ...[
              const SizedBox(height: 8),
              const Text('✓ You have verified this payment', style: TextStyle(color: SpendlyColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: SpendlyColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              subtitle: Text(ref.read(authProvider)?.email ?? ''),
              onTap: () {
                Navigator.pop(context);
                context.go('/account');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: SpendlyColors.danger),
              title: const Text('Logout',
                  style: TextStyle(color: SpendlyColors.danger)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
class _DashboardSettlementAction extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final Future<void> Function() onPressed;

  const _DashboardSettlementAction({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_DashboardSettlementAction> createState() => _DashboardSettlementActionState();
}

class _DashboardSettlementActionState extends State<_DashboardSettlementAction> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isPrimary) {
      return ElevatedButton(
        onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          try {
            await widget.onPressed();
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: SpendlyColors.success,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _loading 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(widget.label),
      );
    } else {
      return OutlinedButton(
        onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          try {
            await widget.onPressed();
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: SpendlyColors.danger,
          side: const BorderSide(color: SpendlyColors.danger),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _loading 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SpendlyColors.danger))
          : Text(widget.label),
      );
    }
  }
}
