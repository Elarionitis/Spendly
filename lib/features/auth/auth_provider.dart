import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/models/app_user.dart';
import '../../core/services/auth_service.dart';

/// ----------------------
/// In-memory user data (demo)
/// ----------------------
final usersDataProvider = StateProvider<List<AppUser>>((ref) {
  return [
    const AppUser(id: 'u1', name: 'Alice Kumar', email: 'alice@spendly.app'),
    const AppUser(id: 'u2', name: 'Bob Sharma', email: 'bob@spendly.app'),
    const AppUser(id: 'u3', name: 'Carol Singh', email: 'carol@spendly.app'),
    const AppUser(id: 'u4', name: 'Dave Patel', email: 'dave@spendly.app'),
  ];
});

/// ----------------------
/// Auth Service Provider
/// ----------------------
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// ----------------------
/// Auth Notifier
/// ----------------------
final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AppUser?> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(null) {
    _listenToFirebaseAuth();
  }

  /// 🔥 Listen to Firebase auth state
  void _listenToFirebaseAuth() {
    final authService = _ref.read(authServiceProvider);

    authService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        state = _mapFirebaseUser(firebaseUser);
      } else {
        state = null;
      }
    });
  }

  /// 🔁 Convert Firebase user → AppUser
  AppUser _mapFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      name: user.displayName ?? "User",
      email: user.email ?? "",
    );
  }

  /// ----------------------
  /// Google Sign-In
  /// ----------------------
 Future<void> signInWithGoogle() async {
  try {
    final authService = _ref.read(authServiceProvider);

    final userCredential = await authService.signInWithGoogle();

    if (userCredential == null || userCredential.user == null) {
      throw Exception("Google Sign-In failed");
    }

    final firebaseUser = userCredential.user!;

    // ⭐ UPDATE STATE HERE
    state = AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? "User",
      email: firebaseUser.email ?? "",
    );
  } catch (e) {
    throw Exception("Google Sign-In failed");
  }
}

  /// ----------------------
  /// Logout
  /// ----------------------
  Future<void> logout() async {
    final authService = _ref.read(authServiceProvider);
    await authService.signOut();
    state = null;
  }

  /// ----------------------
  /// Legacy (Optional - Keep for demo/testing)
  /// ----------------------
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

  bool get isAuthenticated => state != null;

  AppUser? getUserById(String id) {
    final users = _ref.read(usersDataProvider);

    return users.cast<AppUser?>().firstWhere(
          (u) => u?.id == id,
          orElse: () => null,
        );
  }
}

/// ----------------------
/// Get user by ID
/// ----------------------
final userByIdProvider = Provider.family<AppUser?, String>((ref, id) {
  final users = ref.watch(usersDataProvider);

  return users.cast<AppUser?>().firstWhere(
        (u) => u?.id == id,
        orElse: () => null,
      );
});