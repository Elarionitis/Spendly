import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/router/app_router.dart';
import 'package:spendly/main.dart';

void main() {
  testWidgets('Spendly app smoke test', (WidgetTester tester) async {
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Material(
            child: Center(child: Text('Test Home')),
          ),
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(testRouter),
          ],
          child: const SpendlyApp(firebaseReady: true),
        ),
      );
    });
    // Drain all pending frames and timers (animations, GoRouter init, etc.)
    await tester.pump(const Duration(seconds: 2));
    // App should boot without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)));
}

