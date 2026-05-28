import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test harness renders material app', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('School World')));
    expect(find.text('School World'), findsOneWidget);
  });
}
