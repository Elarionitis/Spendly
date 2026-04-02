import 'enums.dart';

class Settlement {
  final String id;
  final String fromUserId; // payer (owes money)
  final String toUserId;   // payee (receives money)
  final double amount;
  final SettlementStatus status;
  final DateTime createdAt;
  final String? transactionId;
  final String? proofUrl;
  /// Local file path for an optionally attached payment screenshot.
  final String? proofImagePath;
  final String? groupId;
  final String? rejectionReason;

  const Settlement({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.transactionId,
    this.proofUrl,
    this.proofImagePath,
    this.groupId,
    this.rejectionReason,
  });

  Settlement copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    double? amount,
    SettlementStatus? status,
    DateTime? createdAt,
    String? transactionId,
    String? proofUrl,
    String? proofImagePath,
    String? groupId,
    String? rejectionReason,
    bool clearProofImage = false,
  }) {
    return Settlement(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      transactionId: transactionId ?? this.transactionId,
      proofUrl: proofUrl ?? this.proofUrl,
      proofImagePath:
          clearProofImage ? null : (proofImagePath ?? this.proofImagePath),
      groupId: groupId ?? this.groupId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isPending => status == SettlementStatus.pendingVerification;
  bool get isVerified => status == SettlementStatus.verified;
  bool get isRejected => status == SettlementStatus.rejected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Settlement && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a simplified debt recommendation from the algorithm
class DebtSuggestion {
  final String fromUserId;
  final String toUserId;
  final double amount;

  const DebtSuggestion({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}
