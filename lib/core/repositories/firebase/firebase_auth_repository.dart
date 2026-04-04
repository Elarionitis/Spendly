import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/app_user.dart';
import '../auth_repository.dart';
import '../user_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configuration for Google Sign-In
  // Note: clientId is only required for iOS and Web. On Android, it's read from google-services.json.
  static const String _webClientId = "445139054884-95qd16k57ia8ii3asj9qem0943rar2in.apps.googleusercontent.com";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (kIsWeb || Platform.isIOS) ? _webClientId : null,
  );
  final UserRepository _userRepo;

  FirebaseAuthRepository(this._userRepo);

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      name: user.displayName ?? 'No Name',
      email: user.email ?? '',
      avatarUrl: user.photoURL,
    );
  }

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AppUser?> get authStateStream =>
      _auth.authStateChanges().map(_mapUser);

  @override
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> register(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    final user = credential.user;

    if (user != null) {
      await _userRepo.saveUser(AppUser(
        id: user.uid,
        name: name,
        email: email,
      ));
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      // 🔥 IMPORTANT: force account picker (fixes silent issues)
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Google sign-in cancelled");
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        final appUser = AppUser(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          avatarUrl: user.photoURL,
        );

        await _userRepo.saveUser(appUser);

        print("Google Sign-In SUCCESS: ${user.email}");

        return appUser;
      }

      return null;
    } catch (e, stack) {
      print("GOOGLE SIGN IN ERROR: $e");
      print("STACKTRACE: $stack");
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}