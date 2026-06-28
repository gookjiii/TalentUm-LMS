import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'src/app_state.dart';
import 'src/firebase/school_repository.dart';
import 'src/providers/app_providers.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/guest_join_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/student_shell.dart';
import 'src/screens/teacher_workspace_screen.dart';
import 'src/features/parent_dashboard/presentation/screens/parent_home_screen.dart';
import 'src/theme.dart';
import 'src/utils/splash_loader.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'src/firebase/push_notification_manager.dart';
import 'src/widgets/cached_stream_builder.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  try {
    provider_pkg.Provider.debugCheckInvalidValueType = null;
    WidgetsFlutterBinding.ensureInitialized();

    // Hide splash as soon as possible
    // (Removed to keep HTML splash visible until Flutter app is fully ready)
    // try {
    //   hideSplash();
    // } catch (_) {}

    // Improve image caching for better render performance
    PaintingBinding.instance.imageCache.maximumSize = 2000;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        200 * 1024 * 1024; // 200 MB

    FlutterError.onError = (FlutterErrorDetails details) {
      // Framework-level safety
      final exception = details.exception;

      debugPrint('--- FLUTTER ERROR ---');
      debugPrint(exception.toString());

      try {
        if (details.context != null) {
          FlutterError.presentError(details);
        }
      } catch (e) {
        // Ignore failures in presentError on Web
      }
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Container(
        color: Colors.red,
        alignment: Alignment.center,
        child: Text(
          'Error: ${details.exception}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
          textDirection: TextDirection.ltr,
        ),
      );
    };

    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('app_settings'),
      Hive.openBox('data_cache'),
      Hive.openBox('chat_cache'),
    ]);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore settings failed: $e');
    }
    await initializeDateFormatting('ru', null);

    // Hide splash early to avoid getting stuck if streams take too long
    hideSplash();

    runApp(const ProviderScope(child: SchoolWorldApp()));
  } catch (e, stack) {
    debugPrint('Fatal init error: $e\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Text(
                'Критическая ошибка запуска:\n\n$e\n\n$stack',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SchoolWorldApp extends ConsumerStatefulWidget {
  const SchoolWorldApp({super.key});

  @override
  ConsumerState<SchoolWorldApp> createState() => _SchoolWorldAppState();
}

class _SchoolWorldAppState extends ConsumerState<SchoolWorldApp> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _settingsFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future so it doesn't re-fire on every rebuild
    final repository = ref.read(repositoryProvider);
    _settingsFuture = repository.firestore
        .collection('settings')
        .doc('system')
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(
      schoolAppStateProvider.select((state) => state.isDarkMode),
    );
    final activeLocale = ref.watch(
      schoolAppStateProvider.select((state) => state.locale),
    );
    final appState = ref.watch(schoolAppStateProvider.notifier);
    final repository = ref.watch(repositoryProvider);
    final guestParams = getGuestInviteParams();
    if (guestParams != null) {
      debugPrint(
        'Deep Link Detected: classId=${guestParams.classId}, code=${guestParams.inviteCode}',
      );
    }
    return AppScope(
      repository: repository,
      appState: appState,
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (snapshot.hasError) {
            debugPrint('System Settings Error: ${snapshot.error}');
          }

          final settings = snapshot.data?.data();
          final appName = settings?['appName'] as String? ?? 'TalentUm';

          return MaterialApp(
            title: appName,
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            theme: schoolTheme(primaryColor: appState.accentColor),
            darkTheme: schoolDarkTheme(primaryColor: appState.accentColor),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: activeLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            localeResolutionCallback: (locale, supportedLocales) {
              if (activeLocale != null) return activeLocale;
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return const Locale('ru');
            },
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              final isMobile = mediaQueryData.size.width < 700;

              // Force a directionality and default text style to prevent crashes in sub-widgets
              return Directionality(
                textDirection: TextDirection.ltr,
                child: MediaQuery(
                  data: mediaQueryData.copyWith(
                    textScaler: isMobile
                        ? const TextScaler.linear(1.15)
                        : mediaQueryData.textScaler,
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: AuthGate(repository: repository, appState: appState),
          );
        },
      ),
    );
  }
}

GuestInviteParams? getGuestInviteParams() {
  final uri = Uri.base;

  // 1. Try standard query parameters
  String? classId =
      uri.queryParameters['classId'] ?? uri.queryParameters['class'];
  String? inviteCode =
      uri.queryParameters['invite'] ?? uri.queryParameters['code'];

  // 2. Try fragment query parameters (for Hash URL strategy)
  if (classId == null || inviteCode == null) {
    if (uri.fragment.contains('?')) {
      final fragmentParts = uri.fragment.split('?');
      if (fragmentParts.length > 1) {
        final queryParams = Uri.splitQueryString(fragmentParts[1]);
        classId ??= queryParams['classId'] ?? queryParams['class'];
        inviteCode ??= queryParams['invite'] ?? queryParams['code'];
      }
    }
  }

  if (classId == null ||
      classId.isEmpty ||
      inviteCode == null ||
      inviteCode.isEmpty) {
    return null;
  }
  return GuestInviteParams(classId: classId, inviteCode: inviteCode);
}

class GuestInviteParams {
  const GuestInviteParams({required this.classId, required this.inviteCode});

  final String classId;
  final String inviteCode;
}


class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required this.appState,
    required super.child,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return repository != oldWidget.repository || appState != oldWidget.appState;
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.repository, required this.appState});

  final SchoolRepository repository;
  final SchoolAppState appState;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _processingInvite = false;
  String? _initializedUid;

  late Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = widget.repository.authState();
  }

  @override
  Widget build(BuildContext context) {
    final guestParams = getGuestInviteParams();
    final hasPendingInvite =
        guestParams != null && !widget.appState.joinedClassRecently;

    if (_processingInvite) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.joiningClass),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          debugPrint('AuthGate Auth Error: ${authSnapshot.error}');
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Ошибка авторизации:\n${authSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (!authSnapshot.hasData &&
            authSnapshot.connectionState == ConnectionState.waiting) {
          // Timeout to prevent infinite spinner
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && !authSnapshot.hasData) {
              debugPrint('Auth stream timeout');
            }
          });
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: SizedBox.shrink(),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          _initializedUid = null;
          WidgetsBinding.instance.addPostFrameCallback((_) => hideSplash());
          if (hasPendingInvite) {
            return GuestJoinScreen(
              classId: guestParams.classId,
              inviteCode: guestParams.inviteCode,
            );
          }
          return const AuthScreen();
        }

        // Only start presence and update activity ONCE per user login
        if (_initializedUid != user.uid) {
          _initializedUid = user.uid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.repository.startPresenceMonitoring();
            widget.repository.updateActivity();

            // Initialize push notifications reactively on login
            PushNotificationManager.syncTokenSubscription(
              userId: user.uid,
              enabled: widget.appState.pushNotifications,
            );
            PushNotificationManager.initNotificationListeners();
          });
        }

        return CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          streamFactory: () => widget.repository.userDocStream(),
          keys: [user.uid],
          builder: (context, profileSnap) {
            if (profileSnap.hasError) {
              debugPrint('AuthGate Profile Error: ${profileSnap.error}');
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Ошибка загрузки профиля:\n${profileSnap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              );
            }

            if (!profileSnap.hasData &&
                profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.transparent,
                body: SizedBox.shrink(),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) => hideSplash());

            final doc = profileSnap.data;
            final data = doc?.data();
            final role = data?['role'] as String?;

            // If user has no profile or no role, they act like a new guest
            if (doc == null || !doc.exists || role == null) {
              if (hasPendingInvite) {
                return GuestJoinScreen(
                  classId: guestParams.classId,
                  inviteCode: guestParams.inviteCode,
                );
              }
              return const OnboardingScreen();
            }

            // We have a user profile and a pending invite: process it automatically
            if (hasPendingInvite) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (_processingInvite) return;
                setState(() => _processingInvite = true);
                try {
                  // Make sure they have a student or parent role before joining via normal API
                  if (role == 'student' || role == 'parent') {
                    await widget.repository.joinClass(guestParams.classId);
                    widget.appState.selectClass(guestParams.classId);
                  }
                } catch (e) {
                  debugPrint('Error auto-joining class: $e');
                } finally {
                  widget.appState.markJoined();
                  if (mounted) setState(() => _processingInvite = false);
                }
              });
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.joiningClass),
                    ],
                  ),
                ),
              );
            }

            // Normal flow: go to dashboard based on role
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (widget.appState.role != role) {
                widget.appState.setRole(role);
              }
            });

            if (role == 'teacher' || role == 'admin' || role == 'leadTeacher')
              return const TeacherWorkspaceScreen();
            if (role == 'student') return const StudentShell();
            if (role == 'parent') return const ParentHomeScreen();

            return const OnboardingScreen();
          },
        );
      },
    );
  }
}
