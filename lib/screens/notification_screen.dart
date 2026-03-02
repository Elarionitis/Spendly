import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(
            backgroundColor: index == 0 ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            child: Icon(index == 0 ? Icons.notifications_active : Icons.notifications_none),
          ),
          title: Text(index == 0 ? "New Expense added" : "Payment Verified"),
          subtitle: const Text("2 hours ago"),
          trailing: index == 0 ? const Icon(Icons.circle, size: 10, color: Colors.blue) : null,
          onTap: () {},
        ),
      ),
    );
  }
}