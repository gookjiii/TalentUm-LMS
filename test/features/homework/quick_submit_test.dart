import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_world/src/features/homework/presentation/widgets/student_homework.dart';
import 'package:school_world/src/theme.dart';
import '../../test_utils.dart';

class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockSchoolRepository mockRepo;
  late MockSchoolAppState mockAppState;
  late MockQueryDocumentSnapshot mockDoc;

  setUp(() {
    mockRepo = MockSchoolRepository();
    mockAppState = MockSchoolAppState();
    mockDoc = MockQueryDocumentSnapshot();

    when(() => mockDoc.id).thenReturn('test_assignment_id');
    when(() => mockDoc.data()).thenReturn({
      'title': 'Test Assignment',
      'description': 'Test Description',
      'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
    });

    when(() => mockAppState.performanceMode).thenReturn(false);
  });

  testWidgets('HomeworkCard renders correct data and opens quick submit', (tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: HomeworkCard(doc: mockDoc),
      repository: mockRepo,
      appState: mockAppState,
    ));
    await tester.pumpAndSettle();

    // Verify title
    expect(find.text('Test Assignment'), findsOneWidget);

    // Find and tap Quick Submit button (it's an OutlinedButton with icon and text)
    final quickSubmitBtn = find.textContaining('Quick submit');
    expect(quickSubmitBtn, findsOneWidget);
    
    await tester.tap(quickSubmitBtn);
    await tester.pumpAndSettle();

    // Verify Bottom Sheet opened - check for title in the sheet
    expect(find.text('Test Assignment'), findsWidgets); // Found in card and sheet
    expect(find.byType(TextField), findsOneWidget);
  });
}
