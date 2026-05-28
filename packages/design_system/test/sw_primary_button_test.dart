import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sw_design_system/design_system.dart';

void main() {
  testWidgets('SwPrimaryButton renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwPrimaryButton(label: 'Send', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Send'), findsOneWidget);
  });
}
