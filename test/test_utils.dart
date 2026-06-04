import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/app_state.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockSchoolRepository extends Mock implements SchoolRepository {}
class MockSchoolAppState extends Mock implements SchoolAppState {}

Widget createTestableWidget({
  required Widget child,
  required SchoolRepository repository,
  required SchoolAppState appState,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: AppScope(
      repository: repository,
      appState: appState,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ru'),
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
}
