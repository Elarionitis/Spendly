import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_user.dart';

// In-memory user data
final usersDataProvider = StateProvider<List<AppUser>>((ref) {
  return [
    const AppUser(id: 'u1', name: 'Alice Kumar', email: 'alice@spendly.app'),
    const AppUser(id: 'u2', name: 'Bob Sharma', email: 'bob@spendly.app'),
    const AppUser(id: 'u3', name: 'Carol Singh', email: 'carol@spendly.app'),
    const AppUser(id: 'u4', name: 'Dave Patel', email: 'dave@spendly.app'),
  ];
});

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AppUser?> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(null) {
    // Auto-login as Alice for demo
    _autoLogin();
  }

  void _autoLogin() {
    final users = _ref.read(usersDataProvider);
    state = users.first;
  }

  bool get isAuthenticated => state != null;

  void login(String email, String password) {
    final users = _ref.read(usersDataProvider);
    final user = users.cast<AppUser?>().firstWhere(
          (u) => u?.email.toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );
    if (user == null) {
      throw Exception('No account found with that email.');
    }
    state = user;
  }

  void register(String name, String email, String password) {
    final users = _ref.read(usersDataProvider);
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Email already in use.');
    }
    final newUser = AppUser(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
    );
    _ref.read(usersDataProvider.notifier).state = [...users, newUser];
    state = newUser;
  }

  void logout() {
    state = null;
  }

  AppUser? getUserById(String id) {
    final users = _ref.read(usersDataProvider);
    return users.cast<AppUser?>().firstWhere(
          (u) => u?.id == id,
          orElse: () => null,
        );
  }
}

// Convenience provider to get a user by ID from anywhere
final userByIdProvider = Provider.family<AppUser?, String>((ref, id) {
  final users = ref.watch(usersDataProvider);
  return users.cast<AppUser?>().firstWhere(
        (u) => u?.id == id,
        orElse: () => null,
      );
});