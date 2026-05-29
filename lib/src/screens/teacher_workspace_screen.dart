import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/app_state.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

import '../features/today/presentation/widgets/teacher_today.dart';
import '../features/feed/presentation/widgets/teacher_feed.dart';
import 'package:school_world/src/features/chat/presentation/screens/class_chat_screen.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_tab_flow.dart';
import '../features/homework/presentation/widgets/teacher_homework.dart';
import '../features/shared/presentation/widgets/teacher_sidebar.dart';
import 'teacher_schedule_screen.dart';

import '../features/shared/presentation/widgets/teacher_right_sidebar.dart';
import '../features/roster/presentation/screens/roster_screen.dart';
import '../features/settings/presentation/widgets/teacher_settings.dart';
import '../features/settings/presentation/tabs/admin_dashboard_tab.dart';
import '../features/library/presentation/widgets/library_screen.dart';
import '../features/webinars/presentation/widgets/webinars_screen.dart';
import '../features/journal/presentation/screens/journal_screen.dart';

class TeacherWorkspaceScreen extends ConsumerStatefulWidget {
  const TeacherWorkspaceScreen({super.key});

  @override
  ConsumerState<TeacherWorkspaceScreen> createState() =>
      _TeacherWorkspaceScreenState();
}

class _TeacherWorkspaceScreenState
    extends ConsumerState<TeacherWorkspaceScreen> {
  int _tabIndex = 0;
  bool _moreSelected = false;
  String? selectedClassId;
  late final SchoolAppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = ref.read(schoolAppStateProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _appState.addListener(_handleAppStateChange);
      setState(() {
        _tabIndex = _appState.teacherTabIndex;
        selectedClassId = _appState.selectedClassId;
      });
    });
  }

  @override
  void dispose() {
    _appState.removeListener(_handleAppStateChange);
    super.dispose();
  }

  void _handleAppStateChange() {
    if (!mounted) return;
    final appState = _appState;
    if (_tabIndex != appState.teacherTabIndex) {
      setState(() {
        _tabIndex = appState.teacherTabIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final l10n = AppLocalizations.of(context)!;
    final appState = ref.read(schoolAppStateProvider);
    final selectedIdFromState = ref.watch(
      schoolAppStateProvider.select((state) => state.selectedClassId),
    );
    final classesAsync = ref.watch(teacherClassesStreamProvider);

    // Use cached value while loading so sidebar/nav never disappear
    final isLoading = classesAsync.isLoading && !classesAsync.hasValue;
    final classes = classesAsync.value ?? [];

    final activeId = _selectedClassIdFromMap(
      selectedClassId ?? selectedIdFromState,
      classes,
    );
    final hasClasses = classes.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final extraWide = constraints.maxWidth >= 1200;
        const showRightSidebar = false;

        final navItems = [
          TeacherNavDest(
            l10n.today,
            Icons.dashboard_outlined,
            Icons.dashboard_rounded,
          ),
          TeacherNavDest(
            l10n.feed,
            Icons.campaign_outlined,
            Icons.campaign_rounded,
          ),
          TeacherNavDest(
            l10n.chat,
            Icons.chat_bubble_outline_rounded,
            Icons.chat_bubble_rounded,
          ),
          TeacherNavDest(
            AppLocalizations.of(context)!.teachersRoom,
            Icons.coffee_outlined,
            Icons.coffee_rounded,
          ),
          TeacherNavDest(
            l10n.homework,
            Icons.assignment_outlined,
            Icons.assignment_rounded,
          ),
          TeacherNavDest(
            AppLocalizations.of(context)!.library,
            Icons.library_books_outlined,
            Icons.library_books_rounded,
          ),
          TeacherNavDest(
            AppLocalizations.of(context)!.webinars,
            Icons.ondemand_video_outlined,
            Icons.ondemand_video_rounded,
          ),
          TeacherNavDest(
            AppLocalizations.of(context)!.magazine,
            Icons.book_outlined,
            Icons.book_rounded,
          ),
          TeacherNavDest(
            AppLocalizations.of(context)!.schedule,
            Icons.calendar_month_outlined,
            Icons.calendar_month_rounded,
          ),
          TeacherNavDest(
            AppLocalizations.of(context)!.participants,
            Icons.people_outline,
            Icons.people,
          ),
          if (appState.isLeadTeacher)
            TeacherNavDest(
              AppLocalizations.of(context)!.adminPanel,
              Icons.admin_panel_settings_outlined,
              Icons.admin_panel_settings_rounded,
            ),
          TeacherNavDest(
            AppLocalizations.of(context)!.settings,
            Icons.settings_outlined,
            Icons.settings_rounded,
          ),
        ];

        // Only the content area shows loading — sidebar/nav are always visible
        final content = isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeIndexedStack(
                index: _tabIndex,
                children: [
                  if (!hasClasses)
                    _TeacherEmptyState(onCreate: _createClass)
                  else
                    TeacherToday(
                      classes: classes,
                      selectedClassId: activeId ?? '',
                      onTabSelect: (i) => _handleTabSelection(i, wide, activeId, repo, appState, l10n, classes),
                      onSelectClass: (id) {
                        setState(() => selectedClassId = id);
                        appState.selectClass(id);
                      },
                      onDeleteClass: _deleteClass,
                      onCopyGuestLink: _copyGuestInviteLink,
                      onCreateClass: _createClass,
                      onProfileTap: () {
                        final profileIndex = appState.isLeadTeacher ? 11 : 10;
                        _handleTabSelection(profileIndex, wide, activeId, repo, appState, l10n, classes);
                      },
                      showSidebar: showRightSidebar,
                    ),

                  hasClasses && activeId != null
                      ? TeacherFeed(classId: activeId, classes: classes)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.ribbon,
                          icon: Icons.campaign_outlined,
                        ),

                  hasClasses && activeId != null
                      ? ChatTabFlow(
                          repository: repo,
                          appState: appState,
                          classes: classes,
                          initialClassId: activeId,
                          desktopMode: wide,
                          canInitializeRoom: true,
                        )
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.chat,
                          icon: Icons.chat_bubble_outline_rounded,
                        ),

                  // Учительская — lazily mounted only when tab is active
                  _tabIndex == 3
                      ? ClassChatScreen(
                          key: const ValueKey('chat-teachers_lounge'),
                          repository: repo,
                          appState: appState,
                          classId: 'teachers_lounge',
                          canInitializeRoom: true,
                        )
                      : const SizedBox.expand(),

                  hasClasses && activeId != null
                      ? TeacherAssignments(
                          classId: activeId,
                          className: classes
                              .firstWhere(
                                (c) => c['id'] == activeId,
                                orElse: () => {},
                              )['name']
                              ?.toString(),
                        )
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.quests,
                          icon: Icons.assignment_outlined,
                        ),

                  hasClasses && activeId != null
                      ? LibraryScreen(classId: activeId)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.library,
                          icon: Icons.library_books_outlined,
                        ),

                  hasClasses && activeId != null
                      ? WebinarsScreen(classId: activeId)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.webinars,
                          icon: Icons.ondemand_video_outlined,
                        ),

                  hasClasses && activeId != null
                      ? JournalScreen(classId: activeId)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.magazine,
                          icon: Icons.book_outlined,
                        ),

                  const TeacherScheduleScreen(),

                  hasClasses && activeId != null
                      ? RosterScreen(classId: activeId)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.participants,
                          icon: Icons.people_outline,
                        ),

                  appState.isLeadTeacher
                      ? const AdminDashboardTab()
                      : const TeacherSettingsTab(),

                  const TeacherSettingsTab(),
                ],
              );

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Row(

                children: [
                  if (wide)
                    RepaintBoundary(
                      child: _StableSidebar(
                        extended: extraWide,
                        tabIndex: _tabIndex,
                        onSelect: (i) {
                          setState(() => _tabIndex = i);
                          ref.read(schoolAppStateProvider).setTeacherTabIndex(i);
                        },
                        navItems: navItems,
                        onDeleteChat: _deleteClassChat,
                        onDeleteClass: _deleteClass,
                        onCopyGuestLink: _copyGuestInviteLink,
                        onSelectClass: (id) {
                          setState(() => selectedClassId = id);
                          appState.selectClass(id);
                        },
                        onCreateClass: _createClass,
                      ),
                    ),
                  Expanded(child: content),
                  if (showRightSidebar && hasClasses)
                    TeacherRightSidebar(classes: classes),
                ],
              ),
              bottomNavigationBar: wide
                  ? null
                  : Builder(
                      builder: (context) {
                        const mobileIndices = [0, 2, 4, 8]; // Today, Chat, Homework, Schedule
                        final mobileNavItems = mobileIndices
                            .map((i) => navItems[i])
                            .toList();
                        var mobileSelected = mobileIndices.indexOf(_tabIndex);

                        if (mobileSelected < 0 && !_moreSelected) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _tabIndex = 0);
                          });
                          mobileSelected = 0;
                        }

                        return _MobileBottomBar(
                          selectedIndex: _moreSelected ? -1 : mobileSelected,
                          onSelect: (i) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _tabIndex = mobileIndices[i];
                              _moreSelected = false;
                            });
                            ref.read(schoolAppStateProvider).setTeacherTabIndex(mobileIndices[i]);
                          },
                          items: mobileNavItems,
                          onMoreTap: () => _showTeacherMoreSheet(context, appState),
                          moreSelected: _moreSelected,
                        );
                      },
                    ),
            );
          },
        );
  }

  String? _selectedClassIdFromMap(
    String? current,
    List<Map<String, dynamic>> classes,
  ) {
    if (classes.isEmpty) return null;
    if (current != null && classes.any((c) => c['id'] == current))
      return current;
    return classes.first['id'] as String?;
  }

  Future<void> _createClass() async {
    final repo = AppScope.of(context).repository;
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createClass),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Class Name'),
              ),
              TextField(
                controller: subCtrl,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Invite Code'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await repo.createClass(
        name: nameCtrl.text,
        subject: subCtrl.text,
        inviteCode: codeCtrl.text,
      );
    }
  }

  Future<void> _copyGuestInviteLink(String classId, String inviteCode) async {
    final baseOrigin = kIsWeb ? Uri.base.origin : 'https://school-wolrd.web.app';
    final link =
        '$baseOrigin/#/join?classId=$classId&code=$inviteCode';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.inviteToClass),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.showThisQrCodeTo,
                style: TextStyle(fontSize: 13, color: SchoolColors.muted),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SchoolColors.border),
                ),
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: SchoolColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: SchoolColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Код: $inviteCode',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.linkCopied)),
                );
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.copyLink),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClassChat(String classId, String className) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n.clearChat,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : SchoolColors.darkSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Вы уверены, что хотите очистить всю историю чата для класса "$className"? Это действие невозможно отменить.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.clearChat,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(SchoolColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.clearingChat,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final repo = ref.read(repositoryProvider);
      final classDoc = await repo.firestore
          .collection('classes')
          .doc(classId)
          .get();
      final roomId = classDoc.data()?['chatRoomId'] as String?;

      if (roomId != null) {
        // Delete messages in Firestore
        final messagesRef = repo.firestore
            .collection('rooms')
            .doc(roomId)
            .collection('messages');

        final snapshots = await messagesRef.get();
        final docs = snapshots.docs;

        // Delete in chunks of 500 (Firestore batch limit)
        for (var i = 0; i < docs.length; i += 500) {
          final batch = repo.firestore.batch();
          final chunk = docs.sublist(
            i,
            i + 500 > docs.length ? docs.length : i + 500,
          );
          for (final doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }

        // Clear local Hive cache
        try {
          if (Hive.isBoxOpen('chat_cache')) {
            final box = Hive.box('chat_cache');
            await box.delete('msgs_$roomId');
          }
        } catch (e) {
          debugPrint('Error clearing chat cache: $e');
        }
      }

      if (mounted) {
        if (roomId != null) {
          ref.invalidate(preloadedChatControllerProvider(roomId));
        }
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.chatHistoryCleared)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при очистке чата: $e')));
      }
    }
  }

  Future<void> _deleteClass(String classId, String className) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.deleteClass,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : SchoolColors.darkSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Вы уверены, что хотите удалить класс "$className"? Это действие полностью удалит класс, список учеников, все задания и оценки. Это действие невозможно отменить.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.delete,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(SchoolColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.removingAClass,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final repo = ref.read(repositoryProvider);
      await repo.firestore.collection('classes').doc(classId).delete();

      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.classDeletedSuccessfully)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении класса: $e')),
        );
      }
    }
  }

  void _handleTabSelection(
    int index,
    bool wide,
    String? activeId,
    SchoolRepository repo,
    SchoolAppState appState,
    AppLocalizations l10n,
    List<Map<String, dynamic>> classes,
  ) {
    const mobileIndices = [0, 2, 4, 8];

    if (!wide && !mobileIndices.contains(index)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(_getTabTitle(index, l10n)),
            ),
            body: Container(
              color: Theme.of(ctx).colorScheme.surface,
              child: _getTabWidget(index, activeId, repo, appState, classes, wide),
            ),
          ),
        ),
      );
    } else {
      setState(() => _tabIndex = index);
      ref.read(schoolAppStateProvider).setTeacherTabIndex(index);
    }
  }

  void _showTeacherMoreSheet(BuildContext context, SchoolAppState appState) {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TeacherMoreSheet(
        isLeadTeacher: appState.isLeadTeacher,
        onSelect: (index) {
          Navigator.pop(ctx);
          setState(() {
            _tabIndex = index;
            _moreSelected = true;
          });
          ref.read(schoolAppStateProvider).setTeacherTabIndex(index);
        },
        l10n: l10n,
      ),
    );
  }

  String _getTabTitle(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.today;
      case 1:
        return l10n.feed;
      case 2:
        return l10n.chat;
      case 3:
        return AppLocalizations.of(context)!.teachersRoom;
      case 4:
        return l10n.homework;
      case 5:
        return AppLocalizations.of(context)!.library;
      case 6:
        return AppLocalizations.of(context)!.webinars;
      case 7:
        return AppLocalizations.of(context)!.magazine;
      case 8:
        return AppLocalizations.of(context)!.schedule;
      case 9:
        return AppLocalizations.of(context)!.participants;
      case 10:
        return _appState.isLeadTeacher ? AppLocalizations.of(context)!.adminPanel : AppLocalizations.of(context)!.settings;
      case 11:
        return AppLocalizations.of(context)!.settings;
      default:
        return '';
    }
  }

  Widget _getTabWidget(
    int index,
    String? activeId,
    SchoolRepository repo,
    SchoolAppState appState,
    List<Map<String, dynamic>> classes,
    bool wide,
  ) {
    switch (index) {
      case 3:
        return ClassChatScreen(
          key: const ValueKey('chat-teachers_lounge'),
          repository: repo,
          appState: appState,
          classId: 'teachers_lounge',
          canInitializeRoom: true,
        );
      case 4:
        return TeacherAssignments(
          classId: activeId ?? '',
          className: classes
              .firstWhere(
                (c) => c['id'] == activeId,
                orElse: () => {},
              )['name']
              ?.toString(),
        );
      case 5:
        return LibraryScreen(classId: activeId ?? '');
      case 6:
        return WebinarsScreen(classId: activeId ?? '');
      case 7:
        return JournalScreen(classId: activeId ?? '');
      case 8:
        return const TeacherScheduleScreen();
      case 9:
        return RosterScreen(classId: activeId ?? '');
      case 10:
        return appState.isLeadTeacher
            ? const AdminDashboardTab()
            : const TeacherSettingsTab();
      case 11:
        return const TeacherSettingsTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// A self-contained sidebar widget that watches the classes stream
/// independently. This breaks the coupling to the parent's rebuild cycle,
/// so Firestore snapshots that change [classes] only repaint the sidebar,
/// not the entire Scaffold + content area.
class _StableSidebar extends ConsumerWidget {
  const _StableSidebar({
    required this.extended,
    required this.tabIndex,
    required this.onSelect,
    required this.navItems,
    required this.onDeleteChat,
    required this.onDeleteClass,
    required this.onCopyGuestLink,
    required this.onSelectClass,
    this.onCreateClass,
  });

  final bool extended;
  final int tabIndex;
  final ValueChanged<int> onSelect;
  final List<TeacherNavDest> navItems;
  final void Function(String, String) onDeleteChat;
  final void Function(String, String) onDeleteClass;
  final void Function(String, String) onCopyGuestLink;
  final ValueChanged<String> onSelectClass;
  final VoidCallback? onCreateClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherClassesStreamProvider);
    final classes = classesAsync.value ?? [];
    final activeId = ref.watch(
      schoolAppStateProvider.select((s) => s.selectedClassId),
    );

    return TeacherSidebar(
      extended: extended,
      selectedIndex: tabIndex,
      onSelect: onSelect,
      navigationItems: navItems,
      classes: classes,
      activeClassId: activeId,
      onDeleteChat: onDeleteChat,
      onDeleteClass: onDeleteClass,
      onCopyGuestLink: onCopyGuestLink,
      onSelectClass: onSelectClass,
      onCreateClass: onCreateClass,
    );
  }
}

class _FeatureLockedEmptyState extends StatelessWidget {
  const _FeatureLockedEmptyState({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: AppLocalizations.of(context)!.createAClassToOpen,
    );
  }
}

class _TeacherEmptyState extends StatelessWidget {
  const _TeacherEmptyState({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) {
    final isLead = AppScope.of(context).appState.isLeadTeacher;
    return EmptyState(
      icon: Icons.school_outlined,
      title: isLead ? AppLocalizations.of(context)!.createYourFirstClass : AppLocalizations.of(context)!.youDontHaveAnyClasses,
      subtitle: isLead ? AppLocalizations.of(context)!.addStudentsAndGetStarted : AppLocalizations.of(context)!.waitToBeAddedTo,
      actionLabel: isLead ? AppLocalizations.of(context)!.createAClass : null,
      action: isLead ? onCreate : null,
    );
  }
}

class _MobileBottomBar extends StatelessWidget {
  const _MobileBottomBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
    required this.onMoreTap,
    this.moreSelected = false,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<TeacherNavDest> items;
  final VoidCallback onMoreTap;
  final bool moreSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: isDark
              ? SchoolColors.darkSurface.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : SchoolColors.border.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final selected = selectedIndex == index;

                  return Expanded(
                    child: InkWell(
                      onTap: () => onSelect(index),
                      borderRadius: BorderRadius.circular(20),
                      highlightColor: Colors.transparent,
                      splashColor: SchoolColors.primary.withValues(alpha: 0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: selected ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? (isDark
                                        ? SchoolColors.primary.withValues(alpha: 0.18)
                                        : SchoolColors.primary.withValues(alpha: 0.1))
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                selected ? item.selectedIcon : item.icon,
                                color: selected
                                    ? SchoolColors.primary
                                    : (isDark
                                        ? SchoolColors.darkTextSecondary.withValues(alpha: 0.5)
                                        : SchoolColors.textSecondary.withValues(alpha: 0.5)),
                                size: 24,
                              ),
                            ),
                          ),
                          if (selected)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: SchoolColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                Expanded(
                  child: InkWell(
                    onTap: onMoreTap,
                    borderRadius: BorderRadius.circular(20),
                    highlightColor: Colors.transparent,
                    splashColor: SchoolColors.primary.withValues(alpha: 0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: moreSelected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: moreSelected
                                  ? (isDark
                                      ? SchoolColors.primary.withValues(alpha: 0.18)
                                      : SchoolColors.primary.withValues(alpha: 0.1))
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              moreSelected ? Icons.grid_view_rounded : Icons.grid_view_outlined,
                              color: moreSelected
                                  ? SchoolColors.primary
                                  : (isDark
                                      ? SchoolColors.darkTextSecondary.withValues(alpha: 0.5)
                                      : SchoolColors.textSecondary.withValues(alpha: 0.5)),
                              size: 24,
                            ),
                          ),
                        ),
                        if (moreSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: SchoolColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavIcon extends StatefulWidget {
  const _AnimatedNavIcon({required this.icon, required this.selected});
  final IconData icon;
  final bool selected;

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    if (widget.selected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedNavIcon old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: Icon(widget.icon));
  }
}

class _TeacherMoreSheet extends StatelessWidget {
  const _TeacherMoreSheet({
    required this.isLeadTeacher,
    required this.onSelect,
    required this.l10n,
  });
  final bool isLeadTeacher;
  final ValueChanged<int> onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (icon: Icons.campaign_rounded, label: l10n.feed, color: SchoolColors.secondary, index: 1),
      (icon: Icons.coffee_rounded, label: l10n.teachersRoom, color: SchoolColors.accent, index: 3),
      (icon: Icons.library_books_rounded, label: l10n.library, color: const Color(0xFF059669), index: 5),
      (icon: Icons.ondemand_video_rounded, label: l10n.webinars, color: SchoolColors.primary, index: 6),
      (icon: Icons.book_rounded, label: l10n.magazine, color: SchoolColors.orange, index: 7),
      (icon: Icons.people_rounded, label: l10n.participants, color: SchoolColors.textSecondary, index: 9),
      if (isLeadTeacher)
        (icon: Icons.admin_panel_settings_rounded, label: l10n.adminPanel, color: Colors.redAccent, index: 10),
      (icon: Icons.settings_rounded, label: l10n.settings, color: SchoolColors.muted, index: isLeadTeacher ? 11 : 10),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? SchoolColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
          width: 1.0,
        ),
        boxShadow: [SchoolColors.elevatedShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'More',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? SchoolColors.darkText : SchoolColors.text,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: items
                  .map(
                    (item) => _MoreSheetItem(
                      icon: item.icon,
                      label: item.label,
                      color: item.color,
                      isDark: isDark,
                      onTap: () => onSelect(item.index),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MoreSheetItem extends StatelessWidget {
  const _MoreSheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: isDark ? 0.12 : 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? SchoolColors.darkText : SchoolColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
