import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/main.dart';

void main() {
  testWidgets('Spendly app smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: SpendlyApp()));
    });
    // Drain all pending frames and timers (animations, GoRouter init, etc.)
    await tester.pump(const Duration(seconds: 2));
    // App should boot without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)));
}

