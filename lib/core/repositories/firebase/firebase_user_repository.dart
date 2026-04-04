import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import '../user_repository.dart';

/// Firestore-backed user repository.
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  @override
  Future<List<AppUser>> getUsers() async {
    final snap = await _col.get();
    return snap.docs
        .map((doc) => AppUser.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromJson(doc.data()!, id: doc.id);
  }

  @override
  Future<void> saveUser(AppUser user) async {
    await _col.doc(user.id).set(user.toJson(), SetOptions(merge: true));
  }
}
