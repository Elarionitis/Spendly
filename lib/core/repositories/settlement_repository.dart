import '../models/settlement.dart';
import '../models/enums.dart';

abstract class SettlementRepository {
  /// Fetch a single settlement by ID.
  Future<Settlement?> getSettlementById(String id);

  /// Real-time stream of all settlements involving a user.
  Stream<List<Settlement>> watchUserSettlements(String userId);

  /// Fetch all settlements involving a user.
  Future<List<Settlement>> getUserSettlements(String userId);

  /// Create a new settlement record in the root collection.
  Future<void> addSettlement(Settlement settlement, {dynamic imageFile});

  /// Update settlement status (verified / rejected).
  Future<void> updateStatus(
    String id,
    SettlementStatus status, {
    String? rejectionReason,
    int? verificationAttempts,
    List<String>? approvals,
    List<String>? rejections,
  });

  /// Update transaction reference ID.
  Future<void> updateTransactionId(String id, String transactionId);
}
