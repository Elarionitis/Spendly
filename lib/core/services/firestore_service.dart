import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= USERS =================
  Future<void> saveUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
    });
  }

  // ================= GROUPS =================
  Future<void> createGroup({
    required String name,
    required List<String> members,
  }) async {
    await _db.collection('groups').add({
      'name': name,
      'members': members,
    });
  }

  // ================= EXPENSE =================
  Future<void> addExpense({
    required String groupId,
    required double amount,
    required String description,
    required String category,
    required String createdBy,
    required Map<String, double> splitDetails,
    String? imageUrl,
  }) async {
    await _db.collection('expenses').add({
      'groupId': groupId,
      'amount': amount,
      'description': description,
      'category': category,
      'createdBy': createdBy,
      'splitDetails': splitDetails,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= FETCH EXPENSE =================
Stream<List<Map<String, dynamic>>> getGroupExpenses(String groupId) {
  return _db
      .collection('expenses')
      .where('groupId', isEqualTo: groupId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // 🔥 IMPORTANT
            return data;
          }).toList());
}

  // ================= COMMENTS =================
  Future<void> addComment({
    required String expenseId,
    required String userId,
    required String message,
  }) async {
    await _db.collection('comments').add({
      'expenseId': expenseId,
      'userId': userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}