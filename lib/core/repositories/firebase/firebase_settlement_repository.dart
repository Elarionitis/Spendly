import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/settlement.dart';
import '../../models/enums.dart';
import '../../services/cloudinary_service.dart';
import '../settlement_repository.dart';


/// Firestore-backed settlement repository.
class FirebaseSettlementRepository implements SettlementRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('settlements');

  @override
  Stream<List<Settlement>> watchUserSettlements(String userId) {
    // Note: To watch both fromUser and toUser in one stream, we'd ideally use a 'participants' array.
    // For now, we'll use Filter.or if available, or just fromUser for simplicity in this MVP 
    // but better to implement proper bidirectional watching.
    return _col
        .where(Filter.or(
          Filter('fromUser', isEqualTo: userId),
          Filter('toUser', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Settlement.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Future<List<Settlement>> getUserSettlements(String userId) async {
    final snap = await _col
        .where(Filter.or(
          Filter('fromUser', isEqualTo: userId),
          Filter('toUser', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => Settlement.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<void> addSettlement(Settlement settlement, {dynamic imageFile}) async {
    String? proofUrl = settlement.proofUrl;

    if (imageFile is File) {
      proofUrl = await _cloudinary.uploadImage(imageFile);
    }

    final data = settlement
        .copyWith(proofUrl: proofUrl)
        .toJson()
      ..['createdAt'] = FieldValue.serverTimestamp();
      
    await _col.add(data);
  }

  @override
  Future<void> updateStatus(
    String id,
    SettlementStatus status, {
    String? rejectionReason,
    List<String>? approvals,
    List<String>? rejections,
  }) async {
    await _col.doc(id).update({
      'status': status.name,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (approvals != null) 'approvals': approvals,
      if (rejections != null) 'rejections': rejections,
    });
  }

  @override
  Future<void> updateTransactionId(String id, String transactionId) async {
    await _col.doc(id).update({'transactionId': transactionId});
  }
}
