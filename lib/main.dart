import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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
import 'src/utils/reload_app.dart';
import 'src/utils/splash_loader.dart';
import 'package:provider/provider.dart' as provider_pkg;

Future<void> main() async {
  try {
    provider_pkg.Provider.debugCheckInvalidValueType = null;
    WidgetsFlutterBinding.ensureInitialized();

    // Hide splash as soon as possible
    try {
      hideSplash();
    } catch (_) {}

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
    await Hive.openBox('app_settings');
    await Hive.openBox('data_cache');
    await Hive.openBox('chat_cache');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
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
    _settingsFuture = repository.firestore.collection('settings').doc('system').get();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(
      schoolAppStateProvider.select((state) => state.isDarkMode),
    );
    final activeLocale = ref.watch(
      schoolAppStateProvider.select((state) => state.locale),
    );
    final appState = ref.read(schoolAppStateProvider);
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
            return const Directionality(
              textDirection: TextDirection.ltr,
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Загрузка настроек системы...', style: TextStyle(color: Colors.black, fontSize: 14, decoration: TextDecoration.none)),
                    ],
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('System Settings Error: ${snapshot.error}');
          }

          final settings = snapshot.data?.data();
          final appName = settings?['appName'] as String? ?? 'TalentUm';

          return MaterialApp(
            title: appName,
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
              // Force a directionality and default text style to prevent crashes in sub-widgets
              return Directionality(
                textDirection: TextDirection.ltr,
                child: child!,
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

class _AppErrorWidget extends StatelessWidget {
  const _AppErrorWidget({required this.details});
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B1120),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Color(0x33DC2626), Color(0x00DC2626)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Что-то пошло не так',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Попробуйте перезагрузить приложение. Если проблема повторяется — обратитесь в поддержку.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      height: 1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: reloadApp,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Перезагрузить'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 52),
                      ),
                    ),
                  ),
                  if (!kReleaseMode) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(
                            0xFFDC2626,
                          ).withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Debug Details:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              details.exceptionAsString(),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  String? _currentProfileUid;

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
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tham gia lớp học...'),
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
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Проверка авторизации...'),
                ],
              ),
            ),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          _initializedUid = null;
          _profileStream = null;
          _currentProfileUid = null;
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
          });
        }

        // Cache profile stream based on UID to avoid infinite rebuild loops
        if (_currentProfileUid != user.uid) {
          _currentProfileUid = user.uid;
          _profileStream = widget.repository.userDocStream();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profileStream,
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
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Загрузка профиля...'),
                    ],
                  ),
                ),
              );
            }

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
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang tham gia lớp học...'),
                    ],
                  ),
                ),
              );
            }

            // Normal flow: go to dashboard based on role
            WidgetsBinding.instance.addPostFrameCallback((_) {
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
