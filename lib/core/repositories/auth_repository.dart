import '../models/app_user.dart';

abstract class AuthRepository {
  /// The currently authenticated user, or null if not signed in.
  AppUser? get currentUser;

  /// Stream that emits every time auth state changes.
  Stream<AppUser?> get authStateStream;

  /// Sign in with email + password (demo: matches seed data / Firebase: real auth).
  Future<void> login(String email, String password);

  /// Register a new account.
  Future<void> register(String name, String email, String password);

  /// Google OAuth sign-in (no-op in demo mode).
  Future<void> signInWithGoogle();

  /// Sign out.
  Future<void> logout();
}
