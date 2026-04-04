import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/activity_event.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import 'activity_provider.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(activityProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final users = usersAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/groups'),
            tooltip: 'Add expense',
          ),
        ],
      ),
      body: events.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: 'No activity yet',
              subtitle: 'Add expenses or settle up to see activity here',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              itemCount: events.length,
              itemBuilder: (context, i) {
                final event = events[i];
                return _ActivityTile(
                  event: event,
                  users: users,
                  onTap: () => _handleTap(context, event),
                ).animate().fadeIn(delay: (i * 40).ms);
              },
            ),
    );
  }

  void _handleTap(BuildContext context, ActivityEvent event) {
    if (event.type == ActivityType.expenseAdded) {
      final groupId = event.metadata?['groupId'] as String?;
      final expenseId = event.metadata?['expenseId'] as String?;
      if (groupId != null && expenseId != null) {
        context.push('/groups/$groupId/expense/$expenseId');
      }
    } else if (event.type == ActivityType.settled) {
      // Navigate to settlements screen
      context.go('/settlements');
    }
    // commentAdded — no dedicated screen yet, ignore
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityEvent event;
  final List<dynamic> users;
  final VoidCallback? onTap;

  const _ActivityTile({required this.event, required this.users, this.onTap});

  Color get _accentColor {
    switch (event.type) {
      case ActivityType.expenseAdded:
        final isCurrentUserPayer =
            event.metadata?['isCurrentUserPayer'] as bool? ?? false;
        final myShare = event.metadata?['myShare'] as double? ?? 0;
        if (isCurrentUserPayer) return SpendlyColors.success;
        if (myShare > 0) return SpendlyColors.danger;
        return SpendlyColors.neutral400;
      case ActivityType.settled:
        final isIncoming = event.metadata?['isIncoming'] as bool? ?? false;
        return isIncoming ? SpendlyColors.success : SpendlyColors.primary;
      case ActivityType.commentAdded:
        return SpendlyColors.neutral400;
      default:
        return SpendlyColors.primary;
    }
  }

  IconData get _icon {
    switch (event.type) {
      case ActivityType.expenseAdded:
        return Icons.receipt_long_rounded;
      case ActivityType.settled:
        return Icons.handshake_rounded;
      case ActivityType.commentAdded:
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  bool get _isTappable =>
      event.type == ActivityType.expenseAdded ||
      event.type == ActivityType.settled;

  @override
  Widget build(BuildContext context) {
    // Parse the description for the amount note (after \n)
    final parts = event.description.split('\n');
    final mainText = parts[0];
    final subText = parts.length > 1 ? parts[1] : null;

    final accentColor = _accentColor;
    final isOwed = subText?.startsWith('you get back') == true;
    final isOwe = subText?.startsWith('you owe') == true;
    final subColor = isOwed
        ? SpendlyColors.success
        : isOwe
            ? SpendlyColors.danger
            : SpendlyColors.neutral500;

    return InkWell(
      onTap: _isTappable ? onTap : null,
      splashColor: accentColor.withAlpha(20),
      highlightColor: accentColor.withAlpha(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent line
            Column(
              children: [
                Container(
                  width: 3,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Icon bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainText,
                      style: AppTextStyles.bodyPrimary()
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (subText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subText,
                          style: AppTextStyles.caption(color: subColor)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(event.timestamp),
                      style: AppTextStyles.caption(
                          color: SpendlyColors.neutral400),
                    ),
                  ],
                ),
              ),
            ),

            // Chevron for tappable items
            if (_isTappable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: SpendlyColors.neutral400,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
