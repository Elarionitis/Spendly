import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/expense.dart';
import '../../core/models/enums.dart';
import '../../core/models/group.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import '../groups/group_provider.dart';
import '../expenses/expense_provider.dart';
import '../../core/services/cloudinary_service.dart';

const _uuid = Uuid();

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? groupId;
  final String? expenseId;

  const AddExpenseScreen({
    super.key,
    this.groupId,
    this.expenseId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _descFocusNode = FocusNode();
  String? _paidById;
  
  ExpenseType _expenseType = ExpenseType.personal;
  String? _selectedGroupId;
  Set<String> _selectedFriendIds = {};
  
  SplitType _splitType = SplitType.equal;
  ExpenseCategory _category = ExpenseCategory.other;
  final Map<String, TextEditingController> _splitControllers = {};
  String? _receiptUrl;
  bool _isUploading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expenseId != null;
    _selectedGroupId = widget.groupId;
    if (_selectedGroupId != null) {
      _expenseType = ExpenseType.group;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEdit) {
        final expense = ref.read(expenseProvider).firstWhere(
          (e) => e.id == widget.expenseId,
          orElse: () => throw Exception('Expense not found'),
        );

        setState(() {
          _expenseType = expense.type;
          _selectedGroupId = expense.groupId;
          _amountController.text = expense.amount.toStringAsFixed(2);
          _descController.text = expense.description;
          _category = expense.category;
          _splitType = expense.splitType;
          _receiptUrl = expense.imageUrl;
          _paidById = expense.paidById;
          
          if (_expenseType == ExpenseType.personal) {
            final currentUser = ref.read(authProvider);
            _selectedFriendIds = expense.participants.where((id) => id != currentUser?.id).toSet();
          }

          if (_splitType != SplitType.equal) {
            for (final entry in expense.splitDetails.entries) {
              final val = _splitType == SplitType.percentage
                  ? (entry.value / expense.amount * 100)
                  : entry.value;
              _splitControllers[entry.key] = TextEditingController(
                text: val.toStringAsFixed(val % 1 == 0 ? 0 : 2),
              );
            }
          }
        });
      } else {
        _descFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _descFocusNode.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _currentParticipants {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return [];
    
    if (_expenseType == ExpenseType.group && _selectedGroupId != null) {
      final groups = ref.read(groupProvider);
      final group = groups.isEmpty ? null : groups.where((g) => g.id == _selectedGroupId).firstOrNull;
      final ids = group?.memberIds ?? [currentUser.id];
      _syncControllers(ids);
      return ids;
    } else {
      final ids = [currentUser.id, ..._selectedFriendIds];
      _syncControllers(ids);
      return ids;
    }
  }

  void _syncControllers(List<String> ids) {
    // Preserve existing controllers/text, add new ones if missing
    for (final id in ids) {
      _splitControllers.putIfAbsent(id, () => TextEditingController());
    }
    // Optional: remove controllers for IDs no longer in list (to save memory)
    // _splitControllers.removeWhere((key, value) => !ids.contains(key));
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 60);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await ref.read(cloudinaryServiceProvider).uploadImage(File(image.path));
      if (url != null) setState(() => _receiptUrl = url);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupProvider);
    final friends = ref.watch(friendsProvider);
    final currentUser = ref.watch(authProvider);
    final amount = double.tryParse(_amountController.text) ?? 0;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Expense' : 'Add Expense'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mode Selector ────────────────────────────────────────────────
            if (!_isEdit) ...[
              Text('Where to add?', style: AppTextStyles.sectionLabel()),
              const SizedBox(height: 10),
              SegmentedButton<ExpenseType>(
                segments: const [
                  ButtonSegment(value: ExpenseType.personal, label: Text('With Friends'), icon: Icon(Icons.people_outline)),
                  ButtonSegment(value: ExpenseType.group, label: Text('In a Group'), icon: Icon(Icons.groups_outlined)),
                ],
                selected: {_expenseType},
                onSelectionChanged: (s) => setState(() {
                  _expenseType = s.first;
                  // _selectedFriendIds.clear(); // Keep them too if we want, or clear them. 
                  // But clearing controllers is what causes data loss.
                }),
              ),
              const SizedBox(height: 20),
            ],

            // ── Context Selection ────────────────────────────────────────────
            if (_expenseType == ExpenseType.group) ...[
               Text('Select Group', style: AppTextStyles.sectionLabel()),
               const SizedBox(height: 10),
               DropdownButtonFormField<String>(
                 value: _selectedGroupId,
                 items: groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                 onChanged: (val) => setState(() {
                   _selectedGroupId = val;
                 }),
                 decoration: const InputDecoration(prefixIcon: Icon(Icons.group_work_outlined)),
               ),
            ] else ...[
                Text('Select Friends', style: AppTextStyles.sectionLabel()),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final f = friends[i];
                      final isSelected = _selectedFriendIds.contains(f.id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) _selectedFriendIds.remove(f.id);
                          else _selectedFriendIds.add(f.id);
                        }),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                UserAvatar(name: f.name, userId: f.id, size: 56),
                                if (isSelected)
                                  Positioned(
                                    right: 0, bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: SpendlyColors.primary, shape: BoxShape.circle),
                                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(f.name.split(' ').first, style: AppTextStyles.caption(color: isSelected ? SpendlyColors.primary : null).copyWith(fontWeight: isSelected ? FontWeight.w700 : null)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
             ],
            const Divider(height: 40),

            // ── 1. Description (first) ──────────────────────────────────────
            TextField(
              controller: _descController,
              focusNode: _descFocusNode,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
            ),
            const SizedBox(height: 20),

            // ── 2. Paid by ──────────────────────────────────────────────────
            if (_currentParticipants.length > 1) ...[
              Text('Paid by', style: AppTextStyles.sectionLabel()),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _paidById ?? currentUser?.id,
                items: _currentParticipants.map((id) {
                  final u = ref.read(userByIdProvider(id));
                  final name = id == currentUser?.id ? 'You' : (u?.name.split(' ').first ?? id);
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (v) => setState(() => _paidById = v),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 20),
            ],

            // ── 3. Amount ────────────────────────────────────────────────────
            Center(
              child: TextField(
                controller: _amountController,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: cs.onSurface, letterSpacing: -2),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0', prefixText: '₹ ', border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: cs.outline),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Divider(height: 32),

            Text('Category', style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            SpendlyCategoryChipGrid<ExpenseCategory>(
              items: ExpenseCategory.values,
              selected: _category,
              label: (cat) => '${cat.emoji} ${cat.label}',
              onSelect: (cat) => setState(() => _category = cat),
            ),
            const SizedBox(height: 24),

            Text('Split Type', style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            SegmentedButton<SplitType>(
              segments: const [
                ButtonSegment(value: SplitType.equal, label: Text('Equal')),
                ButtonSegment(value: SplitType.exact, label: Text('Exact ₹')),
                ButtonSegment(value: SplitType.percentage, label: Text('% Share')),
              ],
              selected: {_splitType},
              onSelectionChanged: (s) => setState(() => _splitType = s.first),
            ),
            const SizedBox(height: 24),

            if (_currentParticipants.isNotEmpty && amount > 0)
              _buildSplitPreview(amount, currentUser?.id ?? ''),

            const SizedBox(height: 20),
            _buildReceiptPicker(),
            const SizedBox(height: 32),

            GestureDetector(
              onTap: _isUploading ? null : _saveExpense,
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  gradient: _isUploading ? null : SpendlyColors.primaryGradient,
                  color: _isUploading ? SpendlyColors.neutral300 : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(_isUploading ? 'Uploading...' : 'Save Expense',
                      style: AppTextStyles.button().copyWith(color: Colors.white)),
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
          Text('Split Preview', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._currentParticipants.map((memberId) {
            final memberUser = ref.read(userByIdProvider(memberId));
            final name = memberId == currentUserId ? 'You' : (memberUser?.name.split(' ').first ?? memberId);

            double share;
            if (_splitType == SplitType.equal) {
              share = amount / _currentParticipants.length;
            } else {
              share = double.tryParse(_splitControllers[memberId]?.text ?? '') ?? 0;
              if (_splitType == SplitType.percentage) share = (amount * share) / 100;
            }

            return Padding(
              key: ValueKey('split_$memberId'),
              padding: const EdgeInsets.only(bottom: 8),
              child: _splitType == SplitType.equal
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: AppTextStyles.bodyPrimary()),
                        Text('₹ ${share.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyPrimary().copyWith(fontWeight: FontWeight.w700, color: SpendlyColors.primary)),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(width: 80, child: Text(name, style: AppTextStyles.bodySecondary())),
                        Expanded(
                          child: TextField(
                            key: ValueKey('input_$memberId'),
                            controller: _splitControllers[memberId],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              isDense: true, contentPadding: const EdgeInsets.all(8),
                              suffixText: _splitType == SplitType.percentage ? '%' : null,
                              prefixText: _splitType == SplitType.exact ? '₹ ' : null,
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

  Widget _buildReceiptPicker() {
    if (_receiptUrl != null) {
      return Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_receiptUrl!, height: 120, width: 120, fit: BoxFit.cover)),
          Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _receiptUrl = null),
              child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 16)))),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => _pickReceipt(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Camera'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: () => _pickReceipt(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
      ],
    );
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description')));
      return;
    }
    
    final participants = _currentParticipants;
    // Allow solo expenses (1 participant)
    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Participants list is empty')));
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to save expenses')));
      return;
    }

    setState(() => _isUploading = true); // Reuse _isUploading as a general loading state

    try {
      Map<String, double> splitDetails = {};

      if (_splitType == SplitType.equal) {
        final share = amount / participants.length;
        for (final p in participants) splitDetails[p] = share;
      } else {
        double totalSplit = 0;
        for (final p in participants) {
          final val = double.tryParse(_splitControllers[p]?.text ?? '') ?? 0;
          final share = (_splitType == SplitType.percentage) ? (amount * val / 100) : val;
          splitDetails[p] = share;
          totalSplit += share;
        }
        
        // Exact split validation
        if ((totalSplit - amount).abs() > 0.1) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Split amounts (₹$totalSplit) must equal total (₹$amount)')));
          setState(() => _isUploading = false);
          return;
        }
      }

      final expense = Expense(
        id: _isEdit ? widget.expenseId! : _uuid.v4(),
        type: _expenseType,
        groupId: _expenseType == ExpenseType.group ? _selectedGroupId : null,
        participants: participants,
        paidById: _paidById ?? user.id,
        amount: amount,
        splitDetails: splitDetails,
        splitType: _splitType,
        category: _category,
        date: DateTime.now(),
        description: _descController.text.trim(),
        imageUrl: _receiptUrl,
      );

      if (_isEdit) {
        await ref.read(expenseActionProvider).updateExpense(expense);
      } else {
        await ref.read(expenseActionProvider).addExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense saved successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving expense: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
