import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/group_expense.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import 'group_provider.dart';

const _uuid = Uuid();

class AddGroupExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  const AddGroupExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddGroupExpenseScreen> createState() =>
      _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState
    extends ConsumerState<AddGroupExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _amountFocusNode = FocusNode();
  SplitType _splitType = SplitType.equal;
  ExpenseCategory _category = ExpenseCategory.other;
  Set<String> _selectedMembers = {};
  final Map<String, TextEditingController> _splitControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groups = ref.read(groupProvider);
      final group = groups.firstWhere(
          (g) => g.id == widget.groupId,
          orElse: () => throw Exception('not found'));
      setState(() => _selectedMembers = Set.from(group.memberIds));
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _amountFocusNode.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupProvider);
    final groupIdx = groups.indexWhere((g) => g.id == widget.groupId);
    if (groupIdx == -1) return const SizedBox.shrink();
    final group = groups[groupIdx];
    final user = ref.watch(authProvider);
    final amount = double.tryParse(_amountController.text) ?? 0;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Group Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Big Amount Input ─────────────────────────────────────────────
            Center(
              child: TextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -2,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: '₹ ',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: cs.outline,
                    letterSpacing: -2,
                  ),
                  prefixStyle: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurfaceVariant,
                    letterSpacing: -2,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Divider(height: 32),

            // ── Description ──────────────────────────────────────────────────
            TextField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // ── Category ─────────────────────────────────────────────────────
            Text('Category', style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            SpendlyCategoryChipGrid<ExpenseCategory>(
              items: ExpenseCategory.values,
              selected: _category,
              label: (cat) => '${cat.emoji} ${cat.label}',
              onSelect: (cat) => setState(() => _category = cat),
            ),
            const SizedBox(height: 24),

            // ── Split Type ────────────────────────────────────────────────────
            Text('Split Type', style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            SegmentedButton<SplitType>(
              segments: const [
                ButtonSegment(value: SplitType.equal, label: Text('Equal')),
                ButtonSegment(value: SplitType.exact, label: Text('Exact ₹')),
                ButtonSegment(value: SplitType.percentage, label: Text('% Share')),
              ],
              selected: {_splitType},
              onSelectionChanged: (s) =>
                  setState(() => _splitType = s.first),
            ),
            const SizedBox(height: 24),

            // ── Member Selection ──────────────────────────────────────────────
            Text('Split With', style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.memberIds.map((memberId) {
                final isCurrentUser = memberId == user?.id;
                final memberUser = ref.read(userByIdProvider(memberId));
                final memberName = isCurrentUser
                    ? 'You'
                    : (memberUser?.name.split(' ').first ?? memberId);
                final isSelected = _selectedMembers.contains(memberId);

                return FilterChip(
                  avatar: UserAvatar(
                      name: memberUser?.name ?? memberId,
                      userId: memberId,
                      size: 22),
                  label: Text(
                    memberName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected ? Colors.white : SpendlyColors.neutral700,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: SpendlyColors.primary,
                  backgroundColor: SpendlyColors.neutral200,
                  checkmarkColor: Colors.white,
                  showCheckmark: isSelected,
                  side: BorderSide.none,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedMembers.add(memberId);
                        _splitControllers[memberId] =
                            TextEditingController();
                      } else if (memberId != user?.id) {
                        _selectedMembers.remove(memberId);
                        _splitControllers.remove(memberId)?.dispose();
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Split Preview ─────────────────────────────────────────────────
            if (_selectedMembers.isNotEmpty && amount > 0)
              _buildSplitPreview(amount, user?.id ?? ''),
            const SizedBox(height: 32),

            // ── Save Button ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _saveExpense,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: SpendlyColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: SpendlyColors.primary.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Save Expense',
                    style: AppTextStyles.button().copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitPreview(double amount, String currentUserId) {
    return SpendlyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: SpendlyColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Split Preview',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ..._selectedMembers.map((memberId) {
            final memberUser = ref.read(userByIdProvider(memberId));
            final isMe = memberId == currentUserId;
            final name =
                isMe ? 'You' : (memberUser?.name.split(' ').first ?? memberId);

            double share;
            if (_splitType == SplitType.equal) {
              share = amount / _selectedMembers.length;
            } else {
              share = double.tryParse(
                      _splitControllers[memberId]?.text ?? '') ??
                  0;
              if (_splitType == SplitType.percentage) {
                share = (amount * share) / 100;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _splitType == SplitType.equal
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name,
                            style: AppTextStyles.bodyPrimary()
                                .copyWith(fontWeight: FontWeight.w500)),
                        Text(
                          '₹ ${share.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyPrimary().copyWith(
                              fontWeight: FontWeight.w700,
                              color: SpendlyColors.primary),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(
                            width: 64,
                            child: Text(name,
                                style: AppTextStyles.bodySecondary())),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller:
                                _splitControllers[memberId] ??=
                                    TextEditingController(),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              suffixText: _splitType == SplitType.percentage
                                  ? '%'
                                  : null,
                              prefixText:
                                  _splitType == SplitType.exact ? '₹ ' : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
            );
          }),
        ],
      ),
    );
  }

  void _saveExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a description')));
      return;
    }
    if (_selectedMembers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least 2 people')));
      return;
    }

    // Validate split values for exact and percentage modes
    if (_splitType == SplitType.exact) {
      double totalSplit = 0;
      bool allZero = true;
      for (final m in _selectedMembers) {
        final v = double.tryParse(_splitControllers[m]?.text ?? '') ?? 0;
        totalSplit += v;
        if (v != 0) allZero = false;
      }
      if (allZero) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Split amounts cannot all be zero')));
        return;
      }
      if ((totalSplit - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Split total (₹${totalSplit.toStringAsFixed(2)}) must equal the expense amount (₹${amount.toStringAsFixed(2)})')));
        return;
      }
    } else if (_splitType == SplitType.percentage) {
      double totalPct = 0;
      bool allZero = true;
      for (final m in _selectedMembers) {
        final v = double.tryParse(_splitControllers[m]?.text ?? '') ?? 0;
        totalPct += v;
        if (v != 0) allZero = false;
      }
      if (allZero) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Split percentages cannot all be zero')));
        return;
      }
      if ((totalPct - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Percentages total ${totalPct.toStringAsFixed(1)}% — must equal 100%')));
        return;
      }
    }

    final user = ref.read(authProvider);
    final members = _selectedMembers.toList();
    Map<String, double> splitDetails = {};

    if (_splitType == SplitType.equal) {
      final share = amount / members.length;
      for (final m in members) {
        splitDetails[m] = share;
      }
    } else if (_splitType == SplitType.exact) {
      for (final m in members) {
        splitDetails[m] =
            double.tryParse(_splitControllers[m]?.text ?? '') ?? 0;
      }
    } else {
      for (final m in members) {
        final pct = double.tryParse(_splitControllers[m]?.text ?? '') ?? 0;
        splitDetails[m] = (amount * pct) / 100;
      }
    }

    final expense = GroupExpense(
      id: _uuid.v4(),
      groupId: widget.groupId,
      description: _descController.text.trim(),
      amount: amount,
      paidById: user?.id ?? 'u1',
      splitDetails: splitDetails,
      splitType: _splitType,
      category: _category,
      date: DateTime.now(),
    );

    ref.read(groupExpenseProvider.notifier).addExpense(expense);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense added! ✓')),
    );
    context.pop();
  }
}
