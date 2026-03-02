import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/app_models.dart';
import '../features/auth/auth_provider.dart';
import '../features/group/group_provider.dart';
import '../features/expense/expense_provider.dart';
import '../widgets/primary_button.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedGroupId;
  String? selectedCategory;
  String selectedSplitType = 'equal';
  Set<String> selectedMembers = {};
  Map<String, TextEditingController> splitControllers = {};

  final List<String> categories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Accommodation', 'Other'];

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    for (var c in splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input
            Center(
              child: SizedBox(
                width: 200,
                child: TextField(
                  controller: amountController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: "0.00",
                    border: InputBorder.none,
                    prefixText: "\$ ",
                    prefixStyle: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Group selection
            if (groups.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Create a group first to add expenses"),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedGroupId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.group),
                  labelText: 'Select Group',
                ),
                items: groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedGroupId = val;
                    selectedMembers.clear();
                    splitControllers.clear();
                  });
                },
              ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: "What's this expense for?",
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
              hint: const Text("Category"),
              items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
            ),
            const SizedBox(height: 24),

            // Members selection
            const Text("Split with", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (selectedGroupId != null) _buildMemberChips(groups) 
            else const Text("Select a group first", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // Split type
            const Text("Split Type", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'equal', label: Text('Equal')),
                ButtonSegment(value: 'exact', label: Text('Exact')),
                ButtonSegment(value: 'percentage', label: Text('Percent')),
              ],
              selected: {selectedSplitType},
              onSelectionChanged: (vals) => setState(() => selectedSplitType = vals.first),
            ),
            const SizedBox(height: 16),

            // Split inputs based on type
            if (selectedMembers.length > 1) _buildSplitInputs(),

            const SizedBox(height: 32),
            PrimaryButton(
              label: "Save Expense",
              onPressed: () => _saveExpense(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberChips(List<Group> groups) {
    final group = groups.firstWhere((g) => g.id == selectedGroupId);
    final user = ref.read(authProvider);
    
    // Ensure current user is always included
    final allMembers = [...group.memberIds];
    if (user != null && !allMembers.contains(user.id)) {
      allMembers.add(user.id);
    }

    if (allMembers.isEmpty) {
      return const Text("No members in this group", style: TextStyle(color: Colors.grey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allMembers.map((memberId) {
        final isSelected = selectedMembers.contains(memberId);
        final isCurrentUser = user?.id == memberId;
        final displayName = isCurrentUser ? 'You' : memberId;
        
        return FilterChip(
          label: Text(displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedMembers.add(memberId);
                splitControllers[memberId] = TextEditingController();
              } else if (memberId != user?.id) {
                selectedMembers.remove(memberId);
                splitControllers.remove(memberId)?.dispose();
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSplitInputs() {
    final amount = double.tryParse(amountController.text) ?? 0;

    if (selectedSplitType == 'equal') {
      final splitAmount = selectedMembers.isNotEmpty ? amount / selectedMembers.length : 0;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Equal split breakdown:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...selectedMembers.map((mid) {
                final user = ref.read(authProvider);
                final name = mid == user?.id ? 'You' : mid;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name),
                      Text("\$${splitAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // Exact or percentage inputs
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedSplitType == 'exact' ? 'Enter exact amounts:' : 'Enter percentages (must sum to 100):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...selectedMembers.map((mid) {
              final user = ref.read(authProvider);
              final name = mid == user?.id ? 'You' : mid;
              splitControllers[mid] ??= TextEditingController();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(name)),
                    Expanded(
                      child: TextField(
                        controller: splitControllers[mid],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: selectedSplitType == 'percentage' ? null : '\$ ',
                          suffixText: selectedSplitType == 'percentage' ? '%' : null,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              );
            }),
            _buildSplitValidation(amount),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitValidation(double totalAmount) {
    if (selectedSplitType == 'equal') return const SizedBox.shrink();

    double total = 0;
    for (var entry in splitControllers.entries) {
      if (selectedSplitType == 'exact') {
        total += double.tryParse(entry.value.text) ?? 0;
      } else {
        total += double.tryParse(entry.value.text) ?? 0;
      }
    }

    final isValid = selectedSplitType == 'exact' 
        ? (total - totalAmount).abs() < 0.01
        : (total - 100).abs() < 0.1;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            selectedSplitType == 'exact' 
                ? 'Total: \$${total.toStringAsFixed(2)}' 
                : 'Total: ${total.toStringAsFixed(1)}%',
            style: TextStyle(color: isValid ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
          ),
          if (!isValid)
            Text(
              selectedSplitType == 'exact' 
                  ? 'Should be: \$${totalAmount.toStringAsFixed(2)}' 
                  : 'Should be: 100%',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    );
  }

  void _saveExpense(BuildContext context) {
    if (selectedGroupId == null || amountController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) return;

    // Ensure payer is in selected members
    final members = {...selectedMembers};
    if (!members.contains(user.id)) {
      members.add(user.id);
    }

    if (members.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one other person to split with")),
      );
      return;
    }

    // Calculate splits based on type
    Map<String, double> splitDetails = {};
    
    if (selectedSplitType == 'equal') {
      final splitAmount = amount / members.length;
      for (var m in members) {
        splitDetails[m] = splitAmount;
      }
    } else if (selectedSplitType == 'exact') {
      for (var m in members) {
        final val = double.tryParse(splitControllers[m]?.text ?? '0') ?? 0;
        splitDetails[m] = val;
      }
    } else if (selectedSplitType == 'percentage') {
      for (var m in members) {
        final val = double.tryParse(splitControllers[m]?.text ?? '0') ?? 0;
        splitDetails[m] = (amount * val) / 100;
      }
    }

    final expense = Expense(
      id: 'e${DateTime.now().millisecondsSinceEpoch}',
      groupId: selectedGroupId!,
      description: descriptionController.text.trim(),
      amount: amount,
      paidById: user.id,
      splitDetails: splitDetails,
      date: DateTime.now(),
    );

    ref.read(expenseProvider.notifier).addExpense(expense);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Expense added successfully!")),
    );
    
    Navigator.pop(context);
  }
}