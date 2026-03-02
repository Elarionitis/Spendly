import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SettlementStatus {
  pending,
  verified,
  rejected,
}

class Settlement {
  final String id;
  final double amount;
  final SettlementStatus status;
  final int retryCount;

  Settlement({
    required this.id,
    required this.amount,
    this.status = SettlementStatus.pending,
    this.retryCount = 0,
  });
}

class SettlementNotifier extends StateNotifier<List<Settlement>> {
  SettlementNotifier() : super([]);

  void addSettlement(Settlement settlement) {
    state = [...state, settlement];
  }
}

final settlementProvider =
    StateNotifierProvider<SettlementNotifier, List<Settlement>>(
  (ref) => SettlementNotifier(),
);