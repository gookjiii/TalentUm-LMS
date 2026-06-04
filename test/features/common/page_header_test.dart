import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import '../../test_utils.dart';

void main() {
  late MockSchoolRepository mockRepo;
  late MockSchoolAppState mockAppState;

  setUp(() {
    mockRepo = MockSchoolRepository();
    mockAppState = MockSchoolAppState();
    when(() => mockAppState.performanceMode).thenReturn(false);
  });

  testWidgets('PageHeader renders correctly with class context', (tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const PageHeader(
        title: 'Test Title',
        subtitle: 'Test Subtitle',
        classContext: 'Mathematics 101',
      ),
      repository: mockRepo,
      appState: mockAppState,
    ));

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Subtitle'), findsOneWidget);
    expect(find.text('MATHEMATICS 101'), findsOneWidget);
  });

  testWidgets('PageHeader class switcher interaction', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(createTestableWidget(
      child: PageHeader(
        title: 'Test',
        classContext: 'Class A',
        onClassContextTap: () => tapped = true,
      ),
      repository: mockRepo,
      appState: mockAppState,
    ));

    final contextBadge = find.text('CLASS A');
    await tester.tap(contextBadge);
    expect(tapped, isTrue);
  });
}
