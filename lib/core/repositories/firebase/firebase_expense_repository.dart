import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group_expense.dart';
import '../../services/cloudinary_service.dart';
import '../expense_repository.dart';

/// Firestore-backed expense repository with Cloudinary image upload.
class FirebaseExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  CollectionReference<Map<String, dynamic>> _col(String groupId) =>
      _db.collection('groups').doc(groupId).collection('expenses');

  @override
  Stream<List<GroupExpense>> watchExpenses(String groupId) {
    return _col(groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GroupExpense.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Future<void> addExpense(GroupExpense expense, {dynamic imageFile}) async {
    String? imageUrl = expense.imageUrl;

    // Upload image to Cloudinary if provided
    if (imageFile is File) {
      imageUrl = await _cloudinary.uploadImage(imageFile);
    }

    final data = expense
        .copyWith(imageUrl: imageUrl)
        .toJson()
      ..remove('id')
      ..['date'] = FieldValue.serverTimestamp();

    await _col(expense.groupId).add(data);
  }

  @override
  Future<void> updateExpense(GroupExpense expense) async {
    final data = expense.toJson()..remove('id');
    await _col(expense.groupId).doc(expense.id).update(data);
  }

  @override
  Future<void> deleteExpense(String groupId, String id) async {
    await _col(groupId).doc(id).delete();
  }
}
