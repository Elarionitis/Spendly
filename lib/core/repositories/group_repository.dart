import '../models/group.dart';

abstract class GroupRepository {
  /// Real-time stream of groups the [userId] belongs to.
  Stream<List<Group>> watchGroups(String userId);

  /// Fetch all groups once.
  Future<List<Group>> getGroups(String userId);

  /// Create a new group.
  Future<void> createGroup(Group group);

  /// Update an existing group.
  Future<void> updateGroup(Group group);

  /// Delete a group by ID.
  Future<void> deleteGroup(String id);
}
