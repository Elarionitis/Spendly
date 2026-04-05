import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_user.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/repositories/auth_repository.dart';

// ─── Current user (stream-backed) ─────────────────────────────────────────────

/// Watches auth state changes; null = not logged in.
final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

// ─── Auth Notifier ───────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AppUser?> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(_repo.currentUser) {
    // Listen to auth state stream so state stays reactive
    _repo.authStateStream.listen((user) => state = user);
  }

  Future<void> login(String email, String password) =>
      _repo.login(email, password);

  Future<void> register(String name, String email, String password) =>
      _repo.register(name, email, password);

  Future<void> signInWithGoogle() => _repo.signInWithGoogle();

  Future<void> logout() async {
    await _repo.logout();
    _ref.invalidate(authProvider); // will reset notifier
    _ref.invalidate(allUsersProvider);
  }

  bool get isAuthenticated => state != null;
}

// ─── User lookup providers ─────────────────────────────────────────────────────

/// Provides the list of all users (used in group settings, split screens, etc.)
final allUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  return ref.watch(userRepositoryProvider).getUsers();
});

/// Convenience: look up a single user by ID.
/// Synchronous user lookup by ID.
/// Reads from the in-memory allUsersProvider cache (works in demo mode).
/// Returns null if the user hasn't been loaded yet.
final userByIdProvider = Provider.family<AppUser?, String>((ref, id) {
  final usersAsync = ref.watch(allUsersProvider);
  final users = usersAsync.value ?? [];
  try {
    return users.firstWhere((u) => u.id == id);
  } catch (_) {
    return null;
  }
});