// Basic smoke test for the MapX Field Validator app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mapx_field_validator/app/app.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MapXFieldValidatorApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the splash screen's startup timer/auth check settle.
    await tester.pump(const Duration(milliseconds: 600));
  });
}
