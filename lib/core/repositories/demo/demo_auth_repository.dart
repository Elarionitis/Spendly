import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/app_user.dart';
import '../auth_repository.dart';
import '../user_repository.dart';

/// In-memory auth repository using seed users.
class DemoAuthRepository implements AuthRepository {
  final UserRepository _userRepo;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  DemoAuthRepository(this._userRepo) {
    // Auto-login as first seed user
    _userRepo.getUsers().then((users) {
      if (users.isNotEmpty) {
        _currentUser = users.first;
        _controller.add(_currentUser);
      }
    });
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateStream => _controller.stream;

  @override
  Future<void> login(String email, String password) async {
    final users = await _userRepo.getUsers();
    final user = users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('User not found'),
    );
    _currentUser = user;
    _controller.add(_currentUser);
  }

  @override
  Future<void> register(String name, String email, String password) async {
    final users = await _userRepo.getUsers();
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Email already in use.');
    }
    final newUser = AppUser(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
    );
    await _userRepo.saveUser(newUser);
    _currentUser = newUser;
    _controller.add(_currentUser);
  }

  @override
  Future<void> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final users = await _userRepo.getUsers();
    // Log in as Carol Singh (demo user) for Google simulation
    final user = users.length > 2 ? users[2] : users.first;
    _currentUser = user;
    _controller.add(_currentUser);
    debugPrint('DEMO Google Sign-In SUCCESS: ${user.email}');
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
