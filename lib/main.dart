import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/settlement_screen.dart';
import 'screens/group_detail_screen.dart';

void main() {
  runApp(const ProviderScope(child: SpendlyApp()));
}

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/add-expense':
            return MaterialPageRoute(builder: (_) => const AddExpenseScreen());
          case '/settlement':
            return MaterialPageRoute(builder: (_) => const SettlementScreen());
          case '/group-detail':
            return MaterialPageRoute(builder: (_) => const GroupDetailScreen());
          default:
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
        }
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Auto-login for demo
    if (authState == null) {
      // Try auto-login first time
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authProvider.notifier).autoLogin();
      });
    }
    
    return authState != null 
        ? const DashboardScreen() 
        : const LoginScreen();
  }
}