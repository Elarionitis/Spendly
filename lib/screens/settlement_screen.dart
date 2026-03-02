import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/app_models.dart';
import '../features/auth/auth_provider.dart';
import '../features/expense/expense_provider.dart';
import '../features/group/group_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';

class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  final amountController = TextEditingController();
  final transactionIdController = TextEditingController();
  String? selectedGroupId;

  @override
  void dispose() {
    amountController.dispose();
    transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final groups = ref.watch(groupProvider);
    final settlements = ref.watch(settlementProvider);
    final expenses = ref.watch(expenseProvider);

    // Calculate balances for current user
    final balances = _calculateBalances(user, expenses, groups);
    final totalOwe = balances['owe'] ?? 0.0;
    final totalOwed = balances['owed'] ?? 0.0;
    final netBalance = totalOwed - totalOwe;

    // Get pending settlements for current user
    final pendingSettlements = settlements.where((s) => 
      (s.toUserId == user?.id || s.fromUserId == user?.id) && 
      s.status == SettlementStatus.pending
    ).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Settle Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Net Balance", style: TextStyle(color: Colors.white.withOpacity(0.8))),
                    Text(
                      "\$${netBalance.abs().toStringAsFixed(2)}",
                      style: TextStyle(
                        color: netBalance >= 0 ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildBalanceCard("You Owe", totalOwe, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildBalanceCard("Owed to You", totalOwed, Colors.green)),
              ],
            ),
            const SizedBox(height: 32),
            const Text("Initiate Settlement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (groups.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Create a group first to settle expenses"),
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: selectedGroupId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.group),
                  labelText: 'Select Group',
                ),
                items: groups.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(g.name),
                )).toList(),
                onChanged: (val) => setState(() => selectedGroupId = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  hintText: "Amount", 
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  if (amountController.text.isNotEmpty && selectedGroupId != null) {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      _initiateSettlement(context, amount, selectedGroupId!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid amount")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text("Initiate Settlement Request"),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
            const SizedBox(height: 32),
            const Text("Pending Settlements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (pendingSettlements.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No pending settlements", style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...pendingSettlements.map((s) => _buildSettlementCard(context, s, user)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              "\$${amount.toStringAsFixed(2)}",
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard(BuildContext context, Settlement s, AppUser? currentUser) {
    final isPayer = s.fromUserId == currentUser?.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPayer ? "You owe" : "Owes you",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("\$${s.amount.toStringAsFixed(2)}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const StatusBadge(status: BadgeStatus.pending),
                const Spacer(),
                if (!isPayer) ...[
                  TextButton(
                    onPressed: () => _handleVerification(context, s.id, true),
                    child: const Text("Approve", style: TextStyle(color: Colors.green)),
                  ),
                  TextButton(
                    onPressed: () => _handleVerification(context, s.id, false),
                    child: const Text("Reject", style: TextStyle(color: Colors.red)),
                  ),
                ] else
                  Text("Waiting for approval...", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateBalances(AppUser? user, List<Expense> expenses, List<Group> groups) {
    if (user == null) return {'owe': 0.0, 'owed': 0.0};
    
    double owe = 0.0;
    double owed = 0.0;

    for (var ex in expenses) {
      if (ex.paidById == user.id) {
        ex.splitDetails.forEach((uid, amt) {
          if (uid != user.id) owed += amt;
        });
      } else if (ex.splitDetails.containsKey(user.id)) {
        owe += ex.splitDetails[user.id]!;
      }
    }

    return {'owe': owe, 'owed': owed};
  }

  void _initiateSettlement(BuildContext context, double amount, String groupId) {
    final user = ref.read(authProvider);
    if (user == null) return;

    final expenses = ref.read(expenseProvider);
    final groupExpenses = expenses.where((e) => e.groupId == groupId).toList();

    // Find who owes the current user money
    Map<String, double> balances = {};
    for (var ex in groupExpenses) {
      if (ex.paidById == user.id) {
        ex.splitDetails.forEach((uid, amt) {
          if (uid != user.id) {
            balances[uid] = (balances[uid] ?? 0) + amt;
          }
        });
      } else if (ex.splitDetails.containsKey(user.id)) {
        balances[ex.paidById] = (balances[ex.paidById] ?? 0) - ex.splitDetails[user.id]!;
      }
    }

    // Find the person who owes the most to initiate settlement with
    String? payeeId;
    double maxOwed = 0;
    balances.forEach((uid, balance) {
      if (balance > maxOwed) {
        maxOwed = balance;
        payeeId = uid;
      }
    });

    if (payeeId != null && maxOwed > 0) {
      final settlement = Settlement(
        id: 's${DateTime.now().millisecondsSinceEpoch}',
        fromUserId: payeeId!,
        toUserId: user.id,
        amount: amount > maxOwed ? maxOwed : amount,
      );
      ref.read(settlementProvider.notifier).initiateSettlement(settlement);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settlement request initiated")),
      );
      
      amountController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No outstanding balances to settle")),
      );
    }
  }

  void _handleVerification(BuildContext context, String id, bool isApproved) {
    ref.read(settlementProvider.notifier).handleVerification(id, isApproved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isApproved ? "Settlement approved" : "Settlement rejected")),
    );
  }
}