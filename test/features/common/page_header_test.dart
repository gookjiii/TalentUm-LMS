import 'package:flutter/material.dart';
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

  testWidgets('PageHeader renders correctly with class context', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestableWidget(
        child: const PageHeader(
          title: 'Test Title',
          subtitle: 'Test Subtitle',
          classContext: 'Mathematics 101',
        ),
        repository: mockRepo,
        appState: mockAppState,
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Subtitle'), findsOneWidget);
    expect(find.text('MATHEMATICS 101'), findsOneWidget);
  });

  testWidgets('PageHeader class switcher interaction', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      createTestableWidget(
        child: PageHeader(
          title: 'Test',
          classContext: 'Class A',
          onClassContextTap: () => tapped = true,
        ),
        repository: mockRepo,
        appState: mockAppState,
      ),
    );

    final contextBadge = find.text('CLASS A');
    await tester.tap(contextBadge);
    expect(tapped, isTrue);
  });

  testWidgets('PageHeader keeps the class switcher available without a name', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      createTestableWidget(
        child: PageHeader(
          title: 'Test',
          onClassContextTap: () => tapped = true,
        ),
        repository: mockRepo,
        appState: mockAppState,
      ),
    );

    expect(find.text('SELECT CLASS'), findsOneWidget);
    await tester.tap(find.text('SELECT CLASS'));
    expect(tapped, isTrue);
  });

  testWidgets('PageHeader constrains a long class name on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    const className = 'A very long class name that must not overflow';
    await tester.pumpWidget(
      createTestableWidget(
        child: PageHeader(
          title: 'Tasks',
          classContext: className,
          onClassContextTap: () => tapped = true,
        ),
        repository: mockRepo,
        appState: mockAppState,
      ),
    );

    final badgeLabel = tester.widget<Text>(find.text(className.toUpperCase()));
    expect(badgeLabel.maxLines, 1);
    expect(badgeLabel.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(className.toUpperCase()));
    expect(tapped, isTrue);
  });

  testWidgets('PageHeader keeps an icon action at the mobile header edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createTestableWidget(
        child: PageHeader(
          title: 'Tasks',
          trailing: SchoolAddButton(tooltip: 'Add task', onPressed: () {}),
        ),
        repository: mockRepo,
        appState: mockAppState,
      ),
    );

    final buttonRect = tester.getRect(find.byType(SchoolIconButton));
    expect(buttonRect.width, 48);
    expect(buttonRect.right, closeTo(340, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PageHeader keeps a compact primary action tappable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    await tester.pumpWidget(
      createTestableWidget(
        child: PageHeader(
          title: 'Tasks',
          trailingBelowTitle: true,
          trailing: FilledButton(
            onPressed: () => tapped = true,
            child: const Text('Create task'),
          ),
        ),
        repository: mockRepo,
        appState: mockAppState,
      ),
    );

    final buttonRect = tester.getRect(find.byType(FilledButton));
    expect(buttonRect.width, greaterThan(200));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Create task'));
    expect(tapped, isTrue);
  });
}
