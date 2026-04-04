import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/settlement.dart';
import '../../models/enums.dart';
import '../settlement_repository.dart';


/// Firestore-backed settlement repository.
class FirebaseSettlementRepository implements SettlementRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String groupId) =>
      _db.collection('groups').doc(groupId).collection('settlements');

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) {
    return _col(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Settlement.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Future<List<Settlement>> getSettlements(String groupId) async {
    final snap = await _col(groupId).orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => Settlement.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<void> addSettlement(Settlement settlement) async {
    if (settlement.groupId == null) throw Exception("Settlement must have a groupId");
    final data = settlement.toJson()..remove('id');
    await _col(settlement.groupId!).add(data);
  }

  @override
  Future<void> updateStatus(
    String groupId,
    String id,
    SettlementStatus status, {
    String? rejectionReason,
  }) async {
    await _col(groupId).doc(id).update({
      'status': status.name,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
  }

  @override
  Future<void> updateTransactionId(String groupId, String id, String transactionId) async {
    await _col(groupId).doc(id).update({'transactionId': transactionId});
  }
}
