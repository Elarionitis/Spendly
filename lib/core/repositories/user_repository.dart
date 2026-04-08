import '../models/app_user.dart';

abstract class UserRepository {
  /// Real-time stream of all users.
  Stream<List<AppUser>> watchUsers();

  /// Real-time stream of a specific user.
  Stream<AppUser?> watchUser(String id);

  /// All known users (seed data in demo; Firestore collection in Firebase).
  Future<List<AppUser>> getUsers();

  /// Lookup a single user by ID. Returns null if not found.
  Future<AppUser?> getUserById(String id);

  /// Persist a user profile (used during registration / Google sign-in).
  Future<void> saveUser(AppUser user);
}
