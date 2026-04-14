import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/expense.dart';
import '../../services/cloudinary_service.dart';
import '../expense_repository.dart';

/// Firestore-backed expense repository using a unified root collection.
class FirebaseExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('expenses');

  bool _isIndexError(FirebaseException e) {
    final message = e.message ?? '';
    return e.code == 'failed-precondition' && message.toLowerCase().contains('index');
  }

  List<Expense> _mapAndSort(QuerySnapshot<Map<String, dynamic>> snap) {
    final expenses = snap.docs
        .map((doc) => Expense.fromJson(doc.data(), id: doc.id))
        .toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  @override
  Stream<List<Expense>> watchUserExpenses(String userId) {
    final primary = _col
        .where('participants', arrayContains: userId)
        .orderBy('date', descending: true);

    final fallback = _col.where('participants', arrayContains: userId);

    return (() async* {
      try {
        await primary.limit(1).get();
        yield* primary.snapshots().map(_mapAndSort);
      } on FirebaseException catch (e) {
        if (!_isIndexError(e)) rethrow;
        debugPrint('Missing Firestore index for watchUserExpenses. Falling back to client sorting.');
        yield* fallback.snapshots().map(_mapAndSort);
      }
    })();
  }

  @override
  Stream<List<Expense>> watchGroupExpenses(String groupId) {
    final primary = _col
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true);
    final fallback = _col.where('groupId', isEqualTo: groupId);

    return (() async* {
      try {
        await primary.limit(1).get();
        yield* primary.snapshots().map(_mapAndSort);
      } on FirebaseException catch (e) {
        if (!_isIndexError(e)) rethrow;
        debugPrint('Missing Firestore index for watchGroupExpenses. Falling back to client sorting.');
        yield* fallback.snapshots().map(_mapAndSort);
      }
    })();
  }

  @override
  Future<void> addExpense(Expense expense, {dynamic imageFile}) async {
    String? imageUrl = expense.imageUrl;

    if (imageFile is File) {
      imageUrl = await _cloudinary.uploadImage(imageFile);
    }

    final data = expense
        .copyWith(imageUrl: imageUrl)
        .toJson()
      ..remove('id');
    
    // Use server timestamp if date is very recent (optional refinement)
    // For now keep the model's date but could use FieldValue.serverTimestamp() for a 'createdAt' field
    data['createdAt'] = FieldValue.serverTimestamp();

    await _col.add(data);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final data = expense.toJson()..remove('id');
    await _col.doc(expense.id).update(data);
  }

  @override
  Future<void> updateApprovalStatus(
    String id, {
    List<String>? approvals,
    List<String>? rejections,
  }) async {
    await _col.doc(id).update({
      if (approvals != null) 'approvals': approvals,
      if (rejections != null) 'rejections': rejections,
    });
  }

  @override
  Future<void> deleteExpense(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return;

    final expense = Expense.fromJson(doc.data()!, id: doc.id);
    final hasVerifiedSettlement = await _hasVerifiedSettlementAfterExpense(expense);
    if (hasVerifiedSettlement) {
      throw StateError(
        'This expense cannot be deleted because a verified settlement already depends on it.',
      );
    }

    await _col.doc(id).delete();
  }

  Future<bool> _hasVerifiedSettlementAfterExpense(Expense expense) async {
    final settlementsCol = _db.collection('settlements');

    DateTime parseCreatedAt(dynamic raw) {
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is Timestamp) return raw.toDate();
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    bool isVerified(Map<String, dynamic> data) => data['status'] == 'verified';

    final cutoff = expense.date.subtract(const Duration(seconds: 1));
    final normalizedGroupId = (expense.groupId ?? '').trim();

    if (normalizedGroupId.isNotEmpty) {
      final groupSettlements = await settlementsCol
          .where('groupId', isEqualTo: normalizedGroupId)
          .get();

      return groupSettlements.docs.any((doc) {
        final data = doc.data();
        if (!isVerified(data)) return false;
        final createdAt = parseCreatedAt(data['createdAt']);
        return !createdAt.isBefore(cutoff);
      });
    }

    final counterpartIds = expense.participants
        .where((id) => id != expense.paidById)
        .toSet();

    for (final counterpartId in counterpartIds) {
      final directional = await settlementsCol
          .where('fromUser', isEqualTo: expense.paidById)
          .where('toUser', isEqualTo: counterpartId)
          .get();
      final reverse = await settlementsCol
          .where('fromUser', isEqualTo: counterpartId)
          .where('toUser', isEqualTo: expense.paidById)
          .get();

      final directionalMatch = directional.docs.any((doc) {
        final data = doc.data();
        if (!isVerified(data)) return false;
        final createdAt = parseCreatedAt(data['createdAt']);
        return !createdAt.isBefore(cutoff);
      });
      if (directionalMatch) return true;

      final reverseMatch = reverse.docs.any((doc) {
        final data = doc.data();
        if (!isVerified(data)) return false;
        final createdAt = parseCreatedAt(data['createdAt']);
        return !createdAt.isBefore(cutoff);
      });
      if (reverseMatch) return true;
    }

    return false;
  }
}
