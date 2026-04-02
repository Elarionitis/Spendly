import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/groups/group_detail_screen.dart';
import '../../features/groups/add_group_expense_screen.dart';
import '../../features/groups/add_group_screen.dart';
import '../../features/groups/group_settings_screen.dart';
import '../../features/expenses/transaction_detail_screen.dart';
import '../../features/personal_finance/personal_expenses_screen.dart';
import '../../features/personal_finance/add_personal_expense_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/settlements/settlements_screen.dart';
import '../../features/settlements/settle_up_screen.dart';
import '../../features/friends/friends_screen.dart';
import '../../features/friends/friend_detail_screen.dart';
import '../../features/activity/activity_screen.dart';
import '../../features/account/account_screen.dart';
import '../../features/shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider) != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // ── Home tab ───────────────────────────────────────────────────
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const DashboardScreen(),
          ),

          // ── Groups tab ──────────────────────────────────────────────────
          GoRoute(
            path: '/groups',
            name: 'groups',
            builder: (context, state) => const GroupsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-group',
                builder: (context, state) => const AddGroupScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'group-detail',
                builder: (context, state) {
                  final groupId = state.pathParameters['id']!;
                  return GroupDetailScreen(groupId: groupId);
                },
                routes: [
                  GoRoute(
                    path: 'add-expense',
                    name: 'add-group-expense',
                    builder: (context, state) {
                      final groupId = state.pathParameters['id']!;
                      return AddGroupExpenseScreen(groupId: groupId);
                    },
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'group-settings',
                    builder: (context, state) {
                      final groupId = state.pathParameters['id']!;
                      return GroupSettingsScreen(groupId: groupId);
                    },
                  ),
                  GoRoute(
                    path: 'expense/:expenseId',
                    name: 'transaction-detail',
                    builder: (context, state) {
                      final groupId = state.pathParameters['id']!;
                      final expenseId = state.pathParameters['expenseId']!;
                      return TransactionDetailScreen(
                          groupId: groupId, expenseId: expenseId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Friends tab ────────────────────────────────────────────────
          GoRoute(
            path: '/friends',
            name: 'friends',
            builder: (context, state) => const FriendsScreen(),
            routes: [
              GoRoute(
                path: ':userId',
                name: 'friend-detail',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return FriendDetailScreen(friendUserId: userId);
                },
              ),
            ],
          ),

          // ── Activity tab ───────────────────────────────────────────────
          GoRoute(
            path: '/activity',
            name: 'activity',
            builder: (context, state) => const ActivityScreen(),
          ),

          // ── Account tab ────────────────────────────────────────────────
          GoRoute(
            path: '/account',
            name: 'account',
            builder: (context, state) => const AccountScreen(),
          ),

          // ── Secondary routes (accessible from Account tab & deep links) ─
          GoRoute(
            path: '/personal',
            name: 'personal',
            builder: (context, state) => const PersonalExpensesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-personal-expense',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final expenseId = extra?['expenseId'] as String?;
                  return AddPersonalExpenseScreen(expenseId: expenseId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settlements',
            name: 'settlements',
            builder: (context, state) => const SettlementsScreen(),
          ),
          GoRoute(
            path: '/settle',
            name: 'settle',
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'];
              return SettleUpScreen(preselectedUserId: userId);
            },
          ),
        ],
      ),
    ],
  );
});
