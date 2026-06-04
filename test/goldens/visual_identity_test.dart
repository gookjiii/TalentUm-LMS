import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import '../test_utils.dart';

void main() {
  late MockSchoolRepository mockRepo;
  late MockSchoolAppState mockAppState;

  setUp(() {
    mockRepo = MockSchoolRepository();
    mockAppState = MockSchoolAppState();
    when(() => mockAppState.performanceMode).thenReturn(false);
  });

  testWidgets('SchoolCard Golden Test', (tester) async {
    final widget = Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SchoolCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.school, size: 48, color: SchoolColors.primary),
              SizedBox(height: 16),
              Text(
                'Elite Digital Campus',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Premium Academic Experience',
                style: TextStyle(color: SchoolColors.muted),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(createTestableWidget(
      child: widget,
      repository: mockRepo,
      appState: mockAppState,
    ));

    // Skip golden tests in CI because of platform-specific font rendering differences
    final isCI = Platform.environment.containsKey('GITHUB_ACTIONS');
    if (isCI) return;

    await expectLater(
      find.byType(SchoolCard),
      matchesGoldenFile('goldens/school_card.png'),
    );
  });
}
