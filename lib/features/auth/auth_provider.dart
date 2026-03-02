import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';

// In-memory user storage
final usersProvider = StateNotifierProvider<UsersNotifier, List<AppUser>>((ref) {
  return UsersNotifier();
});

class UsersNotifier extends StateNotifier<List<AppUser>> {
  UsersNotifier() : super([]);

  void register(String name, String email, String password) {
    // Check if email already exists
    if (state.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Email already registered');
    }
    final newUser = AppUser(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );
    state = [...state, newUser];
  }

  AppUser? login(String email, String password) {
    final user = state.cast<AppUser?>().firstWhere(
      (u) => u?.email.toLowerCase() == email.toLowerCase(),
      orElse: () => null,
    );
    return user;
  }

  AppUser? getUserById(String id) {
    return state.cast<AppUser?>().firstWhere(
      (u) => u?.id == id,
      orElse: () => null,
    );
  }
}

// Current authenticated user
final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AppUser?> {
  final Ref ref;

  AuthNotifier(this.ref) : super(null);

  bool get isAuthenticated => state != null;

  void autoLogin() {
    // Auto-login for demo purposes
    final users = ref.read(usersProvider);
    if (users.isNotEmpty) {
      state = users.first;
    } else {
      // Create demo user
      final demoUser = AppUser(
        id: 'u1',
        name: 'Demo User',
        email: 'demo@example.com',
      );
      ref.read(usersProvider.notifier).state = [demoUser];
      state = demoUser;
    }
  }

  void login(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Please enter email and password');
    }
    final users = ref.read(usersProvider);
    final user = users.cast<AppUser?>().firstWhere(
      (u) => u?.email.toLowerCase() == email.toLowerCase(),
      orElse: () => null,
    );
    if (user == null) {
      throw Exception('Invalid email or password');
    }
    state = user;
  }

  void register(String name, String email, String password, String confirmPassword) {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('Please fill in all fields');
    }
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (!email.contains('@')) {
      throw Exception('Please enter a valid email');
    }

    final users = ref.read(usersProvider);
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Email already registered');
    }

    final newUser = AppUser(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );
    ref.read(usersProvider.notifier).state = [...users, newUser];
    state = newUser;
  }

  void logout() {
    state = null;
  }
}

// Navigation provider
final currentRouteProvider = StateProvider<String>((ref) => '/');