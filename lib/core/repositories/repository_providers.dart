import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

import 'auth_repository.dart';
import 'user_repository.dart';
import 'group_repository.dart';
import 'expense_repository.dart';
import 'comment_repository.dart';
import 'settlement_repository.dart';

import 'demo/demo_auth_repository.dart';
import 'demo/demo_user_repository.dart';
import 'demo/demo_group_repository.dart';
import 'demo/demo_expense_repository.dart';
import 'demo/demo_comment_repository.dart';
import 'demo/demo_settlement_repository.dart';

import 'firebase/firebase_auth_repository.dart';
import 'firebase/firebase_user_repository.dart';
import 'firebase/firebase_group_repository.dart';
import 'firebase/firebase_expense_repository.dart';
import 'firebase/firebase_comment_repository.dart';
import 'firebase/firebase_settlement_repository.dart';

// ─── User ────────────────────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (useDemoMode) return DemoUserRepository();
  return FirebaseUserRepository();
});

// ─── Auth ────────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  if (useDemoMode) return DemoAuthRepository(userRepo);
  return FirebaseAuthRepository(userRepo);
});

// ─── Groups ──────────────────────────────────────────────────────────────────

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  if (useDemoMode) return DemoGroupRepository();
  return FirebaseGroupRepository();
});

// ─── Expenses (Unified) ──────────────────────────────────────────────────────

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  if (useDemoMode) return DemoExpenseRepository();
  return FirebaseExpenseRepository();
});

// ─── Comments ────────────────────────────────────────────────────────────────

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  if (useDemoMode) return DemoCommentRepository();
  return FirebaseCommentRepository();
});

// ─── Settlements ─────────────────────────────────────────────────────────────

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  if (useDemoMode) return DemoSettlementRepository();
  return FirebaseSettlementRepository();
});
