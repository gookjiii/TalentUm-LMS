import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/src/screens/prototype_showcase_screen.dart';

void main() {
  group('PrototypeShowcaseScreen Tests', () {
    testWidgets('renders all tabs and switches between them', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ru'),
          home: PrototypeShowcaseScreen(),
        ),
      );

      // Check title and tabs
      expect(find.text('✨ Prototype Update Mới (UI/UX 2.0)'), findsOneWidget);
      expect(find.text('Mobile Simulator'), findsOneWidget);
      expect(find.text('Button System'), findsOneWidget);
      expect(find.text('PageHeader & Layout'), findsOneWidget);
      expect(find.text('Mobile Chat UX'), findsOneWidget);

      // Switch to Button System tab
      await tester.tap(find.text('Button System'));
      await tester.pumpAndSettle();

      expect(find.text('🎛️ Interactive Button Playground'), findsOneWidget);
      expect(find.text('Thực Hiện Hành Động'), findsOneWidget);

      // Switch to PageHeader tab
      await tester.tap(find.text('PageHeader & Layout'));
      await tester.pumpAndSettle();

      expect(find.text('📱 Responsive PageHeader Demo'), findsOneWidget);

      // Switch to Mobile Chat UX tab
      await tester.tap(find.text('Mobile Chat UX'));
      await tester.pumpAndSettle();

      expect(find.text('💬 Nâng Cấp Header Chat Mobile'), findsOneWidget);
    });
  });
}
