import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import 'group_provider.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/groups/add'),
          ),
        ],
      ),
      body: groups.isEmpty
          ? EmptyState(
              icon: Icons.group_outlined,
              title: 'No groups yet',
              subtitle: 'Create a group to start splitting expenses with friends',
              actionLabel: 'Create Group',
              onAction: () => context.go('/groups/add'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final netBalances = ref.watch(groupNetBalanceProvider(group.id));
                final userBalance = netBalances[user?.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SpendlyCard(
                    onTap: () => context.go('/groups/${group.id}'),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: SpendlyColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              group.emoji ?? group.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 22),
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
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 12, color: SpendlyColors.neutral500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${group.memberIds.length} members',
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              userBalance == 0
                                  ? 'Settled'
                                  : AppFormatters.currency(userBalance.abs()),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: userBalance > 0
                                        ? SpendlyColors.success
                                        : userBalance < 0
                                            ? SpendlyColors.danger
                                            : SpendlyColors.neutral500,
                                  ),
                            ),
                            if (userBalance != 0)
                              Text(
                                userBalance > 0 ? 'you get' : 'you owe',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: SpendlyColors.neutral500),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded,
                            color: SpendlyColors.neutral400),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 80).ms),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/groups/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Group'),
      ),
    );
  }
}
