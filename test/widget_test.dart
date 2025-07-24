// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Prince/main.dart';

void main() {
  testWidgets('Prince app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(Prince());

    // Verify that we can build the app without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}