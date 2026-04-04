import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          // ── Profile header ───────────────────────────────────────────
          Container(
            color: Theme.of(context).cardTheme.color,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    UserAvatar(
                        name: user.name,
                        userId: user.id,
                        size: 64,
                        avatarUrl: user.avatarUrl,
                        isVerified: user.isVerified),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: SpendlyColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.name,
                              style: AppTextStyles.heading2()),
                          if (user.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                color: SpendlyColors.primary, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(user.email,
                          style: AppTextStyles.bodySecondary()),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(user.bio!,
                            style: AppTextStyles.caption()),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/account/edit'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Navigation ────────────────────────────────────────────────
          _SectionLabel('Navigate'),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Personal Expenses',
            onTap: () => context.push('/personal'),
          ),
          _SettingsTile(
            icon: Icons.handshake_outlined,
            label: 'Settlements',
            onTap: () => context.push('/settlements'),
          ),
          _SettingsTile(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            onTap: () => context.push('/analytics'),
          ),

          const SizedBox(height: 12),

          _SectionLabel('Preferences'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings coming soon')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.security_outlined,
            label: 'Security',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon')),
              );
            },
          ),

          const SizedBox(height: 12),

          _SectionLabel('App'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'App Version',
            trailing: Text('1.0.0',
                style: AppTextStyles.caption(
                    color: SpendlyColors.neutral400)),
            onTap: null,
          ),

          const SizedBox(height: 24),

          // ── Logout ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded,
                  color: SpendlyColors.danger),
              label: const Text('Sign Out',
                  style: TextStyle(color: SpendlyColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: SpendlyColors.danger),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(text, style: AppTextStyles.sectionLabel()),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: SpendlyColors.neutral600),
      title: Text(label, style: AppTextStyles.bodyPrimary()),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: SpendlyColors.neutral400)
              : null),
      onTap: onTap,
    );
  }
}
