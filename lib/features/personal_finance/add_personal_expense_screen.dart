import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/personal_expense.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import 'personal_expense_provider.dart';

const _uuid = Uuid();

class AddPersonalExpenseScreen extends ConsumerStatefulWidget {
  final String? expenseId;
  const AddPersonalExpenseScreen({super.key, this.expenseId});

  @override
  ConsumerState<AddPersonalExpenseScreen> createState() =>
      _AddPersonalExpenseScreenState();
}

class _AddPersonalExpenseScreenState
    extends ConsumerState<AddPersonalExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  PaymentMethod _paymentMethod = PaymentMethod.upi;
  DateTime _date = DateTime.now();
  bool _isEdit = false;
  String? _receiptImagePath;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _isEdit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final expenses = ref.read(personalExpenseProvider);
        final expense = expenses.cast<PersonalExpense?>().firstWhere(
              (e) => e?.id == widget.expenseId,
              orElse: () => null,
            );
        if (expense != null) {
          setState(() {
            _amountController.text = expense.amount.toStringAsFixed(2);
            _descController.text = expense.description;
            _category = expense.category;
            _paymentMethod = expense.paymentMethod;
            _date = expense.date;
            _receiptImagePath = expense.receiptImagePath;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ─── Image picker helpers ────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() => _receiptImagePath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${source == ImageSource.camera ? "camera" : "gallery"}: $e')),
        );
      }
    }
  }

  void _removeReceipt() => setState(() => _receiptImagePath = null);

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Expense' : 'Add Expense'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: SpendlyColors.danger),
              onPressed: _deleteExpense,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Big Amount Input ─────────────────────────────────────────────
            Center(
              child: TextField(
                controller: _amountController,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -2,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0',
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
            const SizedBox(height: 24),

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

            // ── Payment Method ────────────────────────────────────────────────
            Text('Payment Method', style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            SpendlyCategoryChipGrid<PaymentMethod>(
              items: PaymentMethod.values,
              selected: _paymentMethod,
              label: (pm) => pm.label,
              onSelect: (pm) => setState(() => _paymentMethod = pm),
            ),
            const SizedBox(height: 24),

            // ── Date Picker ───────────────────────────────────────────────────
            Text('Date', style: AppTextStyles.sectionLabel()),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SpendlyColors.neutral200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: SpendlyColors.neutral600),
                    const SizedBox(width: 12),
                    Text(
                      '${_date.day} ${_monthName(_date.month)} ${_date.year}',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: SpendlyColors.neutral500),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Attach Screenshot (Optional) ─────────────────────────────────
            _buildReceiptSection(context, cs, tt),
            const SizedBox(height: 36),

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
                    _isEdit ? 'Update Expense' : 'Save Expense',
                    style: AppTextStyles.button().copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Receipt screenshot section ───────────────────────────────────────────

  Widget _buildReceiptSection(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Attach Screenshot', style: AppTextStyles.sectionLabel()),
            const SizedBox(width: 6),
            Text('(optional)',
                style: AppTextStyles.caption(color: SpendlyColors.neutral400)),
          ],
        ),
        const SizedBox(height: 10),

        // ── Preview when image is selected ───────────────────────────────────
        if (_receiptImagePath != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_receiptImagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeReceipt,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Allow changing the image after selecting
          Row(
            children: [
              Expanded(child: _buildPickerButton(Icons.camera_alt_outlined, 'Camera', ImageSource.camera)),
              const SizedBox(width: 10),
              Expanded(child: _buildPickerButton(Icons.photo_library_outlined, 'Gallery', ImageSource.gallery)),
            ],
          ),
        ] else ...[
          // ── Picker buttons when no image ────────────────────────────────────
          Row(
            children: [
              Expanded(child: _buildPickerButton(Icons.camera_alt_outlined, 'Camera', ImageSource.camera)),
              const SizedBox(width: 10),
              Expanded(child: _buildPickerButton(Icons.photo_library_outlined, 'Gallery', ImageSource.gallery)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Attach a UPI, bank, or digital receipt screenshot',
            style: AppTextStyles.caption(color: SpendlyColors.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildPickerButton(IconData icon, String label, ImageSource source) {
    return OutlinedButton.icon(
      onPressed: () => _pickImage(source),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: SpendlyColors.primary,
        side: const BorderSide(color: SpendlyColors.primary),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: AppTextStyles.bodySecondary().copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
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

    final user = ref.read(authProvider);
    final expense = PersonalExpense(
      id: _isEdit ? widget.expenseId! : _uuid.v4(),
      userId: user?.id ?? 'u1',
      amount: amount,
      category: _category,
      description: _descController.text.trim(),
      paymentMethod: _paymentMethod,
      date: _date,
      receiptImagePath: _receiptImagePath,
    );

    if (_isEdit) {
      ref.read(personalExpenseProvider.notifier).updateExpense(expense);
    } else {
      ref.read(personalExpenseProvider.notifier).addExpense(expense);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Updated! ✓' : 'Expense saved! ✓')),
    );
    context.pop();
  }

  void _deleteExpense() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref
                  .read(personalExpenseProvider.notifier)
                  .deleteExpense(widget.expenseId!);
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: SpendlyColors.danger)),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}
