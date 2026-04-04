import '../models/settlement.dart';
import '../models/enums.dart';

abstract class SettlementRepository {
  /// Real-time stream of settlements for a group.
  Stream<List<Settlement>> watchSettlements(String groupId);

  /// Fetch all settlements for a group.
  Future<List<Settlement>> getSettlements(String groupId);

  /// Create a new settlement record.
  Future<void> addSettlement(Settlement settlement);

  /// Update settlement status (verified / rejected).
  Future<void> updateStatus(
    String groupId,
    String id,
    SettlementStatus status, {
    String? rejectionReason,
  });

  /// Update transaction reference ID.
  Future<void> updateTransactionId(String groupId, String id, String transactionId);
}
