import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.current);
  };

  await runZonedGuarded(() async {
    final firebaseReady = await _initializeFirebase();
    runApp(ProviderScope(child: SpendlyApp(firebaseReady: firebaseReady)));
  }, (error, stackTrace) {
    debugPrint('Uncaught zone error: $error');
    debugPrint('$stackTrace');
  });
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e, st) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('$st');
    return false;
  }
}

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//     statusBarColor: Colors.transparent,
//     statusBarIconBrightness: Brightness.dark,
//   ));
//   runApp(const ProviderScope(child: SpendlyApp()));
// }

class SpendlyApp extends ConsumerWidget {
  final bool firebaseReady;

  const SpendlyApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: SpendlyTheme.lightTheme,
      darkTheme: SpendlyTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (!firebaseReady) {
          return const _BootstrapErrorScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.cloud_off_rounded, size: 48),
              SizedBox(height: 12),
              Text(
                'Could not connect to Firebase. Please check configuration and restart the app.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}