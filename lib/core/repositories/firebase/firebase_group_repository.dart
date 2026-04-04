import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group.dart';
import '../group_repository.dart';

/// Firestore-backed group repository.
class FirebaseGroupRepository implements GroupRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('groups');

  @override
  Stream<List<Group>> watchGroups(String userId) {
    return _col
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Group.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Future<List<Group>> getGroups(String userId) async {
    final snap =
        await _col.where('memberIds', arrayContains: userId).get();
    return snap.docs
        .map((doc) => Group.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<void> createGroup(Group group) async {
    final data = group.toJson()..remove('id');
    await _col.doc(group.id).set(data);
  }

  @override
  Future<void> updateGroup(Group group) async {
    final data = group.toJson()..remove('id');
    await _col.doc(group.id).update(data);
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _col.doc(id).delete();
  }
}
