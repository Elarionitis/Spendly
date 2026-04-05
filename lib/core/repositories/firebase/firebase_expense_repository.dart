import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/expense.dart';
import '../../services/cloudinary_service.dart';
import '../expense_repository.dart';

/// Firestore-backed expense repository using a unified root collection.
class FirebaseExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('expenses');

  @override
  Stream<List<Expense>> watchUserExpenses(String userId) {
    return _col
        .where('participants', arrayContains: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Expense.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Stream<List<Expense>> watchGroupExpenses(String groupId) {
    return _col
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Expense.fromJson(doc.data(), id: doc.id))
            .toList());
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
    await _col.doc(id).delete();
  }
}
