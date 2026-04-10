import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import '../user_repository.dart';

/// Firestore-backed user repository.
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  @override
  Stream<List<AppUser>> watchUsers() {
    return _col.snapshots().map((snap) => snap.docs
        .map((doc) => AppUser.fromJson(doc.data(), id: doc.id))
        .toList());
  }

  @override
  Stream<AppUser?> watchUser(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromJson(doc.data()!, id: doc.id);
    });
  }

  @override
  Future<List<AppUser>> getUsers() async {
    final snap = await _col.snapshots().first;
    return snap.docs
        .map((doc) => AppUser.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    final doc = await _col.doc(id).snapshots().first;
    if (!doc.exists) return null;
    return AppUser.fromJson(doc.data()!, id: doc.id);
  }

  @override
  Future<void> saveUser(AppUser user) async {
    await _col.doc(user.id).set(user.toJson(), SetOptions(merge: true));
  }
}
