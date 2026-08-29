import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_button.dart';

void main() {
  Widget wrapWidget(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? schoolDarkTheme() : schoolTheme(),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('SchoolButton Tests', () {
    testWidgets('renders primary button and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          SchoolButton.primary(
            label: 'Submit',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(SchoolButton), findsOneWidget);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders loading state without calling onPressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          SchoolButton.primary(
            label: 'Submit',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(SchoolButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isFalse);
    });

    testWidgets('renders secondary, outlined, ghost and destructive variants', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          Column(
            children: [
              SchoolButton.secondary(label: 'Secondary', onPressed: () {}),
              SchoolButton.outlined(label: 'Outlined', onPressed: () {}),
              SchoolButton.ghost(label: 'Ghost', onPressed: () {}),
              SchoolButton.destructive(label: 'Delete', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('renders with leading and trailing icons', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SchoolButton.primary(
            label: 'Send',
            icon: const Icon(Icons.send),
            trailingIcon: const Icon(Icons.arrow_forward),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });
  });

  group('SchoolIconButton Tests', () {
    testWidgets('renders icon button and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          SchoolIconButton.tonal(
            icon: const Icon(Icons.star),
            tooltip: 'Star',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders loading state for icon button', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SchoolIconButton.standard(
            icon: const Icon(Icons.refresh),
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

    testWidgets('SchoolAddButton renders only the add icon and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          SchoolAddButton(
            tooltip: 'Add lesson',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(SchoolAddButton), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('Add lesson'), findsNothing);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets(
      'SchoolAddButton uses the mobile touch size on narrow layouts',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: wrapWidget(
              SchoolAddButton(tooltip: 'Add lesson', onPressed: () {}),
            ),
          ),
        );

        final iconButton = tester.widget<SchoolIconButton>(
          find.byType(SchoolIconButton),
        );
        expect(iconButton.size, SchoolIconButtonSize.lg);
        expect(iconButton.backgroundGradient, isA<LinearGradient>());
      },
    );

    testWidgets(
      'SchoolAddButton uses the compact size on desktop layouts',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1440, 900)),
            child: wrapWidget(
              SchoolAddButton(tooltip: 'Add lesson', onPressed: () {}),
            ),
          ),
        );

        final iconButton = tester.widget<SchoolIconButton>(
          find.byType(SchoolIconButton),
        );
        expect(iconButton.size, SchoolIconButtonSize.md);
        expect(iconButton.backgroundGradient, isA<LinearGradient>());
      },
    );

  group('SchoolButtonGroup Tests', () {
    testWidgets('renders horizontal dialog actions group', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SchoolButtonGroup.dialogActions(
            cancel: SchoolButton.ghost(label: 'Cancel', onPressed: () {}),
            confirm: SchoolButton.primary(label: 'Confirm', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });
  });
}
