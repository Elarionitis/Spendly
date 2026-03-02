import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/app_models.dart';
import '../features/auth/auth_provider.dart';
import '../features/group/group_provider.dart';
import '../features/expense/expense_provider.dart';
import '../widgets/expense_card.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String? groupId;
  
  const GroupDetailScreen({super.key, this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupProvider);
    final expenses = ref.watch(expenseProvider);
    final user = ref.watch(authProvider);
    
    final group = groupId != null 
        ? groups.cast<Group?>().firstWhere((g) => g?.id == groupId, orElse: () => null)
        : (groups.isNotEmpty ? groups.first : null);
    
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Group Details")),
        body: const Center(child: Text("No group selected")),
      );
    }
    
    final groupExpenses = expenses.where((e) => e.groupId == group.id).toList();
    final balances = _calculateBalances(user, groupExpenses);

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Group info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            if (group.description.isNotEmpty)
                              Text(group.description, style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Balances
          const Text("Balances", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (balances.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("No expenses yet", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: balances.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key == user?.id ? 'You' : e.key),
                        Text(
                          "\$${e.value.abs().toStringAsFixed(2)}",
                          style: TextStyle(
                            color: e.value >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Recent Expenses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Expenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("${groupExpenses.length} total", style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          
          if (groupExpenses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No expenses yet"),
                    Text("Add an expense to get started", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...groupExpenses.map((e) => ExpenseCard(
              title: e.description,
              subtitle: '${e.date.day}/${e.date.month}/${e.date.year}',
              amount: '\$${e.amount.toStringAsFixed(2)}',
              payer: e.paidById == user?.id ? 'You' : e.paidById,
            )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-expense'),
        label: const Text("Add Expense"),
        icon: const Icon(Icons.add),
      ),
    );
  }
  
  Map<String, double> _calculateBalances(AppUser? user, List<Expense> expenses) {
    Map<String, double> balances = {};
    
    for (var ex in expenses) {
      if (ex.paidById == user?.id) {
        ex.splitDetails.forEach((uid, amt) {
          if (uid != user?.id) {
            balances[uid] = (balances[uid] ?? 0) + amt;
          }
        });
      } else if (ex.splitDetails.containsKey(user?.id)) {
        balances[ex.paidById] = (balances[ex.paidById] ?? 0) - ex.splitDetails[user!.id]!;
      }
    }
    
    return balances;
  }
}