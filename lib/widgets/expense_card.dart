import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String payer;

  const ExpenseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.payer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$subtitle • Paid by $payer'),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}