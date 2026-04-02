import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/settlement.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import '../settlements/settlement_provider.dart';

const _uuid = Uuid();

/// The redesigned Settle Up screen.
/// - Select friend to settle with
/// - See the direction of debt
/// - Enter a (partial) amount
/// - Optionally attach a payment screenshot
/// - Optionally add a transaction ID
class SettleUpScreen extends ConsumerStatefulWidget {
  /// Pre-selected friend user ID (optional, passed from Friends tab).
  final String? preselectedUserId;

  const SettleUpScreen({super.key, this.preselectedUserId});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  String? _selectedFriendId;
  final _amountController = TextEditingController();
  final _txnController = TextEditingController();
  String? _proofImagePath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedFriendId = widget.preselectedUserId;
    _prefillAmount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _txnController.dispose();
    super.dispose();
  }

  double _getBalanceWith(String friendId) {
    final balances = ref.read(friendBalanceProvider);
    return balances[friendId] ?? 0.0;
  }

  void _prefillAmount() {
    if (_selectedFriendId == null) return;
    final balance = _getBalanceWith(_selectedFriendId!);
    // Pre-fill with the absolute debt/credit amount
    _amountController.text = balance.abs().toStringAsFixed(2);
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
    final user = ref.watch(authProvider);
    final balances = ref.watch(friendBalanceProvider);
    final users = ref.watch(usersDataProvider);
    final cs = Theme.of(context).colorScheme;

    // All known friends (from groups) except self
    final friends = users.where((u) => u.id != user?.id).toList();

    final balance =
        _selectedFriendId != null ? (balances[_selectedFriendId] ?? 0.0) : 0.0;
    final friendUser = _selectedFriendId != null
        ? users.cast<dynamic>().firstWhere(
              (u) => u.id == _selectedFriendId,
              orElse: () => null,
            )
        : null;
    final friendName =
        friendUser?.name?.toString().split(' ').first ?? 'Friend';

    // Determine direction
    // balance > 0  → friend owes us  → friend is the FROM (paying us) — but WE are initiating on their behalf
    // balance < 0  → we owe friend   → we are the FROM
    final weOwe = balance < 0;
    final theyOwe = balance > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Settle Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Friend Selector ────────────────────────────────────────────
            Text('Who are you settling with?',
                style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpendlyColors.neutral200),
              ),
              child: DropdownButton<String>(
                value: _selectedFriendId,
                hint: const Text('Select friend'),
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: friends
                    .map((u) => DropdownMenuItem<String>(
                          value: u.id,
                          child: Row(
                            children: [
                              UserAvatar(name: u.name, userId: u.id, size: 28),
                              const SizedBox(width: 10),
                              Text(u.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedFriendId = v;
                    _prefillAmount();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Balance Info Card ──────────────────────────────────────────
            if (_selectedFriendId != null && balance != 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: weOwe
                      ? SpendlyColors.danger.withAlpha(12)
                      : SpendlyColors.success.withAlpha(12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: weOwe
                        ? SpendlyColors.danger.withAlpha(40)
                        : SpendlyColors.success.withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      weOwe
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color:
                          weOwe ? SpendlyColors.danger : SpendlyColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        weOwe
                            ? 'You owe $friendName ₹${balance.abs().toStringAsFixed(2)}'
                            : '$friendName owes you ₹${balance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: weOwe
                              ? SpendlyColors.danger
                              : SpendlyColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                theyOwe
                    ? 'You can record payment you received or request it.'
                    : 'Enter the amount you are paying now (partial okay).',
                style: AppTextStyles.caption(color: SpendlyColors.neutral500),
              ),
              const SizedBox(height: 20),
            ] else if (_selectedFriendId != null && balance == 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SpendlyColors.success.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: SpendlyColors.success),
                    const SizedBox(width: 12),
                    Text(
                      'You are settled up with $friendName!',
                      style: const TextStyle(
                          color: SpendlyColors.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Amount ─────────────────────────────────────────────────────
            Text('Amount', style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: '0.00',
                labelText: 'Settlement amount',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // ── Transaction ID (optional) ──────────────────────────────────
            Text('Transaction ID (optional)',
                style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            TextField(
              controller: _txnController,
              decoration: const InputDecoration(
                labelText: 'UPI ref / bank txn number',
                prefixIcon: Icon(Icons.tag_rounded),
                hintText: 'e.g. UPI123456789',
              ),
            ),
            const SizedBox(height: 24),

            // ── Payment Proof ──────────────────────────────────────────────
            Row(
              children: [
                Text('Payment Screenshot', style: AppTextStyles.sectionLabel()),
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
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _proofImagePath = null),
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
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 36),

            // ── Submit ─────────────────────────────────────────────────────
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _selectedFriendId != null
                      ? SpendlyColors.primaryGradient
                      : null,
                  color: _selectedFriendId == null
                      ? SpendlyColors.neutral200
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _selectedFriendId != null
                      ? [
                          BoxShadow(
                            color: SpendlyColors.primary.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Submit Settlement',
                    style: AppTextStyles.button().copyWith(
                      color: _selectedFriendId != null
                          ? Colors.white
                          : SpendlyColors.neutral500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_selectedFriendId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a friend first')));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    final user = ref.read(authProvider)!;
    final balance = _getBalanceWith(_selectedFriendId!);

    // Determine payer direction
    final String fromUserId;
    final String toUserId;
    if (balance < 0) {
      // We owe them — we are paying
      fromUserId = user.id;
      toUserId = _selectedFriendId!;
    } else {
      // They owe us — they are paying / we are recording from our side
      fromUserId = _selectedFriendId!;
      toUserId = user.id;
    }

    final settlement = Settlement(
      id: _uuid.v4(),
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      status: SettlementStatus.pendingVerification,
      createdAt: DateTime.now(),
      transactionId:
          _txnController.text.isNotEmpty ? _txnController.text : null,
      proofImagePath: _proofImagePath,
    );

    ref.read(settlementProvider.notifier).initiateSettlement(settlement);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settlement submitted! ✓')),
    );
    context.pop();
  }
}
