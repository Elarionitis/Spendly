import '../models/settlement.dart';
import '../models/enums.dart';

abstract class SettlementRepository {
  /// Real-time stream of settlements involving [userId].
  Stream<List<Settlement>> watchSettlements(String userId);

  /// Fetch all settlements for a user once.
  Future<List<Settlement>> getSettlements(String userId);

  /// Create a new settlement record.
  Future<void> addSettlement(Settlement settlement);

  /// Update settlement status (verified / rejected).
  Future<void> updateStatus(
    String id,
    SettlementStatus status, {
    String? rejectionReason,
  });

  /// Update transaction reference ID.
  Future<void> updateTransactionId(String id, String transactionId);
}
