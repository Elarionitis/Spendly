import '../../models/app_user.dart';
import '../user_repository.dart';

/// In-memory user repository seeded with demo users.
class DemoUserRepository implements UserRepository {
  final List<AppUser> _users = [
    const AppUser(id: 'u1', name: 'Alice Kumar', email: 'alice@spendly.app'),
    const AppUser(id: 'u2', name: 'Bob Sharma', email: 'bob@spendly.app'),
    const AppUser(id: 'u3', name: 'Carol Singh', email: 'carol@spendly.app'),
    const AppUser(id: 'u4', name: 'Dave Patel', email: 'dave@spendly.app'),
  ];

  @override
  Future<List<AppUser>> getUsers() async => List.unmodifiable(_users);

  @override
  Future<AppUser?> getUserById(String id) async {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUser(AppUser user) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx >= 0) {
      _users[idx] = user;
    } else {
      _users.add(user);
    }
  }
}
