import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/settlement.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import '../groups/group_provider.dart';
import 'settlement_provider.dart';

const _uuid = Uuid();

class SettlementsScreen extends ConsumerStatefulWidget {
  const SettlementsScreen({super.key});

  @override
  ConsumerState<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends ConsumerState<SettlementsScreen> {
  final _txnController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedGroupId;
  double? _settleAmount;
  String? _proofImagePath;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _txnController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) setState(() => _proofImagePath = picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open picker: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(overallBalanceProvider);
    final settlements = ref.watch(userSettlementsProvider);
    final groups = ref.watch(groupProvider);
    final user = ref.watch(authProvider);

    final owe = balance['owe'] ?? 0.0;
    final owed = balance['owed'] ?? 0.0;
    final net = balance['net'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Settle Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Balance Summary
            SpendlyCard(
              gradient: net >= 0
                  ? SpendlyColors.greenGradient
                  : SpendlyColors.primaryGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Net Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.currency(net.abs()),
                    style: TextStyle(
                      color: net >= 0
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    net >= 0
                        ? 'You are owed this amount'
                        : 'You owe this amount',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SpendlyCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.arrow_upward_rounded,
                              color: SpendlyColors.danger, size: 14),
                          const SizedBox(width: 4),
                          Text('You Owe',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: SpendlyColors.neutral500)),
                        ]),
                        const SizedBox(height: 6),
                        Text(AppFormatters.currency(owe),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: SpendlyColors.danger)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpendlyCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.arrow_downward_rounded,
                              color: SpendlyColors.success, size: 14),
                          const SizedBox(width: 4),
                          Text('Owed to You',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: SpendlyColors.neutral500)),
                        ]),
                        const SizedBox(height: 6),
                        Text(AppFormatters.currency(owed),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: SpendlyColors.success)),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),

            // Initiate Settlement
            const SectionHeader(title: 'Initiate Settlement'),
            const SizedBox(height: 12),
            SpendlyCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SpendlyColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group_outlined, color: SpendlyColors.neutral500, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedGroupId,
                            hint: const Text('Select Group'),
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            items: groups
                                .map((g) => DropdownMenuItem(
                                    value: g.id,
                                    child: Text('${g.emoji ?? ''} ${g.name}')))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedGroupId = v;
                                _computeSuggestedAmount(v, user?.id ?? '');
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Amount Input ──────────────────────────────────────────
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Settlement Amount',
                      prefixText: '₹ ',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                      hintText: _settleAmount != null && _settleAmount! > 0
                          ? 'Suggested: ${_settleAmount!.toStringAsFixed(2)}'
                          : 'Enter amount',
                    ),
                  ),
                  if (_settleAmount != null && _settleAmount! > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SpendlyColors.warning.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SpendlyColors.warning.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: SpendlyColors.warning, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Suggested: ${AppFormatters.currency(_settleAmount!)}',
                              style: const TextStyle(
                                  color: SpendlyColors.warning,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // ── Transaction ID (optional) ─────────────────────────────
                  TextField(
                    controller: _txnController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID (optional)',
                      prefixIcon: Icon(Icons.tag_rounded),
                      hintText: 'e.g., UPI123456789',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Payment Screenshot (optional) ─────────────────────────
                  Row(
                    children: [
                      Text('Payment Screenshot',
                          style: AppTextStyles.sectionLabel()),
                      const SizedBox(width: 6),
                      Text('(optional)',
                          style: AppTextStyles.caption(
                              color: SpendlyColors.neutral400)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_proofImagePath != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_proofImagePath!),
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _proofImagePath = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _selectedGroupId == null ? null : _initiateSettlement,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _selectedGroupId == null
                            ? null
                            : SpendlyColors.primaryGradient,
                        color: _selectedGroupId == null ? SpendlyColors.neutral200 : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Submit Settlement Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),

            // Settlements History
            SectionHeader(
              title: 'Settlement History',
              actionLabel: settlements.isEmpty ? null : '${settlements.length}',
            ),
            const SizedBox(height: 12),
            if (settlements.isEmpty)
              const EmptyState(
                icon: Icons.handshake_outlined,
                title: 'No settlements',
                subtitle: 'Your settlement history will appear here',
              )
            else
              ...settlements.asMap().entries.map((e) {
                final s = e.value;
                return _buildSettlementCard(context, ref, s, user?.id ?? '')
                    .animate()
                    .fadeIn(delay: (300 + e.key * 60).ms);
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard(BuildContext context, WidgetRef ref,
      Settlement s, String currentUserId) {
    final isReceiving = s.toUserId == currentUserId;
    final isPending = s.isPending;
    final otherUserId = isReceiving ? s.fromUserId : s.toUserId;
    final otherUser = ref.read(userByIdProvider(otherUserId));

    StatusBadge badge;
    if (s.isVerified) {
      badge = StatusBadge.verified();
    } else if (s.isRejected) {
      badge = StatusBadge.rejected();
    } else {
      badge = StatusBadge.pending();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SpendlyCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: otherUser?.name ?? otherUserId,
                  userId: otherUserId,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceiving
                            ? '${otherUser?.name.split(' ').first ?? 'Someone'} owes you'
                            : 'You owe ${otherUser?.name.split(' ').first ?? 'Someone'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (s.transactionId != null)
                        Text(
                          'Txn: ${s.transactionId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: SpendlyColors.neutral500,
                              ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.currency(s.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isReceiving
                            ? SpendlyColors.success
                            : SpendlyColors.danger,
                      ),
                    ),
                    Text(
                      AppFormatters.shortDate(s.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: SpendlyColors.neutral500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                badge,
                const Spacer(),
                if (isPending && isReceiving) ...[
                  TextButton(
                    onPressed: () =>
                        ref.read(settlementProvider.notifier).verify(s.id),
                    style: TextButton.styleFrom(
                        foregroundColor: SpendlyColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12)),
                    child: const Text('Approve'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(settlementProvider.notifier).reject(s.id),
                    style: TextButton.styleFrom(
                        foregroundColor: SpendlyColors.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Reject'),
                  ),
                ] else if (isPending && !isReceiving)
                  Text(
                    'Awaiting approval',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SpendlyColors.neutral500,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _computeSuggestedAmount(String? groupId, String currentUserId) {
    if (groupId == null) return;
    final netBalances = ref.read(groupNetBalanceProvider(groupId));
    final userBalance = netBalances[currentUserId] ?? 0;
    final suggested = userBalance < 0 ? -userBalance : null;
    setState(() {
      _settleAmount = suggested;
      if (suggested != null && suggested > 0) {
        _amountController.text = suggested.toStringAsFixed(2);
      } else {
        _amountController.clear();
      }
    });
  }

  void _initiateSettlement() {
    if (_selectedGroupId == null) return;
    final user = ref.read(authProvider);
    if (user == null) return;

    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid settlement amount')),
      );
      return;
    }

    final suggestions =
        ref.read(debtSuggestionsProvider(_selectedGroupId!));
    final relevantSuggestion = suggestions.cast<DebtSuggestion?>().firstWhere(
          (s) => s?.fromUserId == user.id,
          orElse: () => null,
        );

    // Determine who to pay
    String toUserId;
    if (relevantSuggestion != null) {
      toUserId = relevantSuggestion.toUserId;
    } else {
      // Fallback: find user with highest positive balance in the group
      final netBalances = ref.read(groupNetBalanceProvider(_selectedGroupId!));
      final creditor = netBalances.entries
          .where((e) => e.key != user.id && e.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (creditor.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No outstanding balance to settle in this group')),
        );
        return;
      }
      toUserId = creditor.first.key;
    }

    final s = Settlement(
      id: _uuid.v4(),
      fromUserId: user.id,
      toUserId: toUserId,
      amount: enteredAmount,
      status: SettlementStatus.pendingVerification,
      createdAt: DateTime.now(),
      transactionId: _txnController.text.isNotEmpty ? _txnController.text : null,
      proofImagePath: _proofImagePath,
      groupId: _selectedGroupId,
    );

    ref.read(settlementProvider.notifier).initiateSettlement(s);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settlement request submitted ✓')),
    );
    setState(() {
      _selectedGroupId = null;
      _settleAmount = null;
      _proofImagePath = null;
    });
    _amountController.clear();
    _txnController.clear();
  }
}
