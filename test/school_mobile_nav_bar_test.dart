import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/widgets/school_mobile_nav_bar.dart';

void main() {
  group('SchoolMobileNavBar Tests', () {
    testWidgets('renders items and handles tab selection', (tester) async {
      int selected = 0;

      final items = [
        const SchoolMobileNavItem(
          label: 'Today',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        const SchoolMobileNavItem(
          label: 'Chat',
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
        ),
        const SchoolMobileNavItem(
          label: 'Homework',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment_rounded,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) => SchoolMobileNavBar(
                selectedIndex: selected,
                onSelect: (i) {
                  setState(() => selected = i);
                },
                items: items,
                moreLabel: 'More',
                onMoreTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify all labels render
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Homework'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Tap on 'Chat'
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });

    testWidgets('triggers onMoreTap callback', (tester) async {
      bool moreTapped = false;

      final items = [
        const SchoolMobileNavItem(
          label: 'Today',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: SchoolMobileNavBar(
              selectedIndex: 0,
              onSelect: (_) {},
              items: items,
              moreLabel: 'More',
              onMoreTap: () {
                moreTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(moreTapped, true);
    });

    testWidgets('shows badge count when provided', (tester) async {
      final items = [
        const SchoolMobileNavItem(
          label: 'Chat',
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
          badgeCount: 5,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: SchoolMobileNavBar(
              selectedIndex: 0,
              onSelect: (_) {},
              items: items,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });
  });
}
