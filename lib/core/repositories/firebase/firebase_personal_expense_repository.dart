import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/personal_expense.dart';
import '../personal_expense_repository.dart';

class FirebasePersonalExpenseRepository implements PersonalExpenseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('personal_expenses');

  @override
  Stream<List<PersonalExpense>> watchPersonalExpenses(String userId) {
    return _col(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PersonalExpense.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Future<void> addPersonalExpense(String userId, PersonalExpense expense) async {
    final data = expense.toJson()..remove('id');
    await _col(userId).add(data);
  }

  @override
  Future<void> updatePersonalExpense(String userId, PersonalExpense expense) async {
    final data = expense.toJson()..remove('id');
    await _col(userId).doc(expense.id).update(data);
  }

  @override
  Future<void> deletePersonalExpense(String userId, String expenseId) async {
    await _col(userId).doc(expenseId).delete();
  }
}
