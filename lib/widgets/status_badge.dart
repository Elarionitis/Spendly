import 'package:flutter/material.dart';

enum BadgeStatus { pending, verified, rejected }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case BadgeStatus.pending:
        color = Colors.orange;
        text = "Pending";
        break;
      case BadgeStatus.verified:
        color = Colors.green;
        text = "Verified";
        break;
      case BadgeStatus.rejected:
        color = Colors.red;
        text = "Rejected";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}