import 'dart:async';
import '../../models/settlement.dart';
import '../../models/enums.dart';
import '../settlement_repository.dart';

/// In-memory settlement repository seeded with demo settlements.
class DemoSettlementRepository implements SettlementRepository {
  final List<Settlement> _settlements = [];
  final _controller = StreamController<List<Settlement>>.broadcast();

  DemoSettlementRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    _settlements.addAll([
      Settlement(
        id: 's1', fromUserId: 'u2', toUserId: 'u1', amount: 6000,
        status: SettlementStatus.pendingVerification,
        createdAt: now.subtract(const Duration(days: 2)),
        transactionId: 'TXN12345678', groupId: 'g1',
      ),
      Settlement(
        id: 's2', fromUserId: 'u1', toUserId: 'u3', amount: 2875,
        status: SettlementStatus.verified,
        createdAt: now.subtract(const Duration(days: 10)),
        transactionId: 'TXN87654321', groupId: 'g1',
      ),
      Settlement(
        id: 's3', fromUserId: 'u4', toUserId: 'u1', amount: 1500,
        status: SettlementStatus.verified,
        createdAt: now.subtract(const Duration(days: 20)),
        groupId: 'g3',
      ),
    ]);
  }

  void _emit() => _controller.add(List.unmodifiable(_settlements));

  @override
  Stream<List<Settlement>> watchUserSettlements(String userId) {
    final filtered = _settlements
        .where((s) => s.fromUserId == userId || s.toUserId == userId)
        .toList();
    return Stream.value(filtered).mergeWith([
      _controller.stream.map((all) => all
          .where((s) => s.fromUserId == userId || s.toUserId == userId)
          .toList()),
    ]);
  }

  @override
  Future<List<Settlement>> getUserSettlements(String userId) async => _settlements
      .where((s) => s.fromUserId == userId || s.toUserId == userId)
      .toList();

  @override
  Future<void> addSettlement(Settlement settlement, {dynamic imageFile}) async {
    _settlements.add(settlement);
    _controller.add(List.unmodifiable(_settlements));
  }

  @override
  Future<void> updateStatus(
    String id,
    SettlementStatus status, {
    String? rejectionReason,
    List<String>? approvals,
    List<String>? rejections,
  }) async {
    final idx = _settlements.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _settlements[idx] = _settlements[idx].copyWith(
        status: status,
        rejectionReason: rejectionReason,
        approvals: approvals,
        rejections: rejections,
      );
      _emit();
    }
  }

  @override
  Future<void> updateTransactionId(String id, String transactionId) async {
    final idx = _settlements.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _settlements[idx] = _settlements[idx].copyWith(transactionId: transactionId);
      _emit();
    }
  }
}

extension _StreamMerge<T> on Stream<T> {
  Stream<T> mergeWith(List<Stream<T>> others) {
    final controller = StreamController<T>.broadcast();
    listen(controller.add, onError: controller.addError);
    for (final s in others) {
      s.listen(controller.add, onError: controller.addError);
    }
    return controller.stream;
  }
}
