import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/app_state.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

import '../features/today/presentation/widgets/teacher_today.dart';
import '../features/feed/presentation/widgets/teacher_feed.dart';
import 'package:school_world/src/features/chat/presentation/screens/class_chat_screen.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_tab_flow.dart';
import '../features/homework/presentation/widgets/teacher_homework.dart';
import '../features/shared/presentation/widgets/teacher_sidebar.dart';
import 'teacher_schedule_screen.dart';

import '../features/roster/presentation/screens/roster_screen.dart';
import '../features/settings/presentation/widgets/teacher_settings.dart';
import '../features/settings/presentation/tabs/admin_dashboard_tab.dart';
import '../features/library/presentation/widgets/library_screen.dart';
import '../features/webinars/presentation/widgets/webinars_screen.dart';
import '../features/journal/presentation/screens/journal_screen.dart';

import 'package:school_world/src/widgets/skeletal_loaders.dart';

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
    _appState.addListener(_handleAppStateChange);
    _tabIndex = _appState.teacherTabIndex;
    selectedClassId = _appState.selectedClassId;
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
    final l10n = AppLocalizations.of(context)!;
    final selectedIdFromState = ref.watch(
      schoolAppStateProvider.select((state) => state.selectedClassId),
    );
    final lastChatClassId = ref.watch(
      schoolAppStateProvider.select((s) => s.lastChatClassId),
    );
    final classesAsync = ref.watch(teacherClassesStreamProvider);

    final isLoading = classesAsync.isLoading;
    final classes = classesAsync.value ?? [];

    final activeId = _selectedClassIdFromMap(selectedIdFromState, classes);
    final repo = AppScope.of(context).repository;
    final appState = AppScope.of(context).appState;
    final hasClasses = classes.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final extraWide = constraints.maxWidth >= 1200;

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
        ];

        void onProfileTap() {
          final profileIndex = appState.isLeadTeacher ? 11 : 10;
          _handleTabSelection(profileIndex, wide);
        }

        // Only the content area shows loading — sidebar/nav are always visible
        final content = isLoading
            ? Column(
                children: [
                  const PageHeader(title: '...', subtitle: '...'),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 6,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ClassCardSkeleton(),
                      ),
                    ),
                  ),
                ],
              )
            : FadeIndexedStack(
                index: _tabIndex,
                // Keep inactive teacher tabs out of the layout. IndexedStack
                // normally builds every child, so a transient null in an
                // unrelated tab could replace the whole workspace with the
                // red Flutter error widget (including while opening Settings).
                disposeInactive: true,
                children: [
                  // 0 — Today
                  if (!hasClasses)
                    _TeacherEmptyState(
                      onCreate: _createClass,
                      onProfileTap: onProfileTap,
                    )
                  else
                    TeacherToday(
                      classes: classes,
                      selectedClassId: activeId ?? '',
                      onTabSelect: (i) => _handleTabSelection(i, wide),
                      onSelectClass: (id) {
                        appState.selectClass(id);
                      },
                      onDeleteClass: _deleteClass,
                      onCopyGuestLink: _copyGuestInviteLink,
                      onCreateClass: _createClass,
                      onProfileTap: onProfileTap,
                    ),

                  // 1 — Feed
                  hasClasses && activeId != null
                      ? TeacherFeed(classId: activeId, classes: classes)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.ribbon,
                          icon: Icons.campaign_outlined,
                        ),

                  // 2 — Chat
                  ChatTabFlow(
                    repository: repo,
                    appState: appState,
                    classes: classes,
                    initialClassId: activeId,
                    desktopMode: wide,
                    canInitializeRoom: true,
                  ),

                  // 3 — Учительская (always available, no class dependency)
                  _tabIndex == 3
                      ? ClassChatScreen(
                          key: const ValueKey('chat-teachers_lounge'),
                          repository: repo,
                          appState: appState,
                          classId: 'teachers_lounge',
                          canInitializeRoom: true,
                          initialTopicId:
                              appState.lastChatClassId == 'teachers_lounge'
                              ? appState.lastChatTopicId
                              : null,
                        )
                      : const SizedBox.expand(),

                  // 4 — Homework
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

                  // 5 — Library
                  hasClasses && activeId != null
                      ? LibraryScreen(classId: activeId)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.library,
                          icon: Icons.library_books_outlined,
                        ),

                  // 6 — Webinars
                  hasClasses && activeId != null
                      ? WebinarsScreen(classId: activeId)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.webinars,
                          icon: Icons.ondemand_video_outlined,
                        ),

                  // 7 — Journal
                  hasClasses && activeId != null
                      ? JournalScreen(classId: activeId)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.magazine,
                          icon: Icons.book_outlined,
                        ),

                  // 8 — Schedule
                  TeacherScheduleScreen(initialClassId: activeId),

                  // 9 — Roster
                  hasClasses && activeId != null
                      ? RosterScreen(classId: activeId)
                      : _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.participants,
                          icon: Icons.people_outline,
                        ),

                  // 10 — Admin / Settings
                  appState.isLeadTeacher
                      ? const AdminDashboardTab()
                      : const TeacherSettingsTab(),

                  // 11 — Settings (profile)
                  const TeacherSettingsTab(),
                ],
              );

        return Scaffold(
          extendBody:
              true, // Allow content to scroll under the frosted glass bottom bar
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            bottom: false,
            child: Row(
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
                        appState.selectClass(id);
                      },
                      onCreateClass: _createClass,
                      onProfileTap: onProfileTap,
                    ),
                  ),
                Expanded(child: content),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : Builder(
                  builder: (context) {
                    if (_tabIndex == 2 && lastChatClassId != null) {
                      return const SizedBox.shrink();
                    }
                    const mobileIndices = [
                      0,
                      2,
                      4,
                      8,
                    ]; // Today, Chat, Homework, Schedule
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
                        ref
                            .read(schoolAppStateProvider)
                            .setTeacherTabIndex(mobileIndices[i]);
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
    if (!mounted) return;
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
                decoration: InputDecoration(labelText: l10n.className),
              ),
              TextField(
                controller: subCtrl,
                decoration: InputDecoration(labelText: l10n.subject),
              ),
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(labelText: l10n.inviteCode),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            child: Text(l10n.create),
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
    final baseOrigin = kIsWeb
        ? Uri.base.origin
        : 'https://school-wolrd.web.app';
    final link = '$baseOrigin/#/join?classId=$classId&code=$inviteCode';

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
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.linkCopied),
                  ),
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

        // Delete polls in Firestore
        final pollsRef = repo.firestore
            .collection('rooms')
            .doc(roomId)
            .collection('polls');
        final pollsSnap = await pollsRef.get();
        final pollDocs = pollsSnap.docs;

        for (var i = 0; i < pollDocs.length; i += 500) {
          final batch = repo.firestore.batch();
          final chunk = pollDocs.sublist(
            i,
            i + 500 > pollDocs.length ? pollDocs.length : i + 500,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatHistoryCleared),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorClearingChat(e.toString()),
            ),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.classDeletedSuccessfully,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorDeletingClass(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _handleTabSelection(int index, bool wide) {
    const mobileIndices = [0, 2, 4, 8];

    // Keep every teacher page inside the workspace on mobile. This leaves
    // the bottom navigation visible for pages opened from the More sheet and
    // avoids stacking a second route/app bar with an inner page header.
    setState(() {
      _tabIndex = index;
      _moreSelected = !wide && !mobileIndices.contains(index);
    });
    ref.read(schoolAppStateProvider).setTeacherTabIndex(index);
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
        onCreateClass: () {
          Navigator.pop(ctx);
          _createClass();
        },
      ),
    );
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
    this.onProfileTap,
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
  final VoidCallback? onProfileTap;

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
      onProfileTap: onProfileTap,
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
  const _TeacherEmptyState({
    required this.onCreate,
    required this.onProfileTap,
  });
  final VoidCallback onCreate;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final user = repo.auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final isLead = AppScope.of(context).appState.isLeadTeacher;
    final now = DateTime.now();
    final date = DateFormat('EEEE, MMMM d', l10n.localeName).format(now);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.userDocStream(),
      builder: (context, profileSnap) {
        final profile = profileSnap.data?.data() ?? const <String, dynamic>{};
        final rawName =
            profile['name']?.toString() ?? user?.displayName ?? l10n.teacher;
        final name = rawName.trim().isNotEmpty
            ? rawName.split(RegExp(r'\s+')).first
            : l10n.teacher;
        final avatarUrl = profile['avatarUrl']?.toString();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: PageHeader(
                title: l10n.welcomeToTalentUm,
                subtitle: date,
                trailing: SchoolAvatar(
                  name: name,
                  avatarUrl: avatarUrl,
                  radius: 23,
                  onTap: onProfileTap,
                  showBorder: true,
                ),
              ),
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.school_outlined,
                title: isLead
                    ? l10n.createYourFirstClass
                    : l10n.youDontHaveAnyClasses,
                subtitle: isLead
                    ? l10n.addStudentsAndGetStarted
                    : l10n.waitToBeAddedTo,
                actionLabel: isLead ? l10n.createAClass : null,
                action: isLead ? onCreate : null,
              ),
            ),
          ],
        );
      },
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
    final performanceMode = AppScope.of(context).appState.performanceMode;

    if (performanceMode) {
      return SafeArea(
        top: false,
        child: Container(
          height: 72,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? SchoolColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : SchoolColors.border.withValues(alpha: 0.8),
              width: 1.0,
            ),
          ),
          child: _buildIcons(isDark, context),
        ),
      );
    }

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
        child: _buildIcons(isDark, context),
      ),
    );
  }

  Widget _buildIcons(bool isDark, BuildContext context) {
    return Row(
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
                                  ? SchoolColors.darkTextSecondary.withValues(
                                      alpha: 0.5,
                                    )
                                  : SchoolColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    )),
                        size: 28,
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
                      moreSelected
                          ? Icons.grid_view_rounded
                          : Icons.grid_view_outlined,
                      color: moreSelected
                          ? SchoolColors.primary
                          : (isDark
                                ? SchoolColors.darkTextSecondary.withValues(
                                    alpha: 0.5,
                                  )
                                : SchoolColors.textSecondary.withValues(
                                    alpha: 0.5,
                                  )),
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
    required this.onCreateClass,
  });
  final bool isLeadTeacher;
  final ValueChanged<int> onSelect;
  final AppLocalizations l10n;
  final VoidCallback onCreateClass;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (
        icon: Icons.campaign_rounded,
        label: l10n.feed,
        color: SchoolColors.secondary,
        index: 1,
      ),
      (
        icon: Icons.library_books_rounded,
        label: l10n.library,
        color: const Color(0xFF059669),
        index: 5,
      ),
      (
        icon: Icons.ondemand_video_rounded,
        label: l10n.webinars,
        color: SchoolColors.primary,
        index: 6,
      ),
      (
        icon: Icons.book_rounded,
        label: l10n.magazine,
        color: SchoolColors.orange,
        index: 7,
      ),
      (
        icon: Icons.people_rounded,
        label: l10n.participants,
        color: SchoolColors.textSecondary,
        index: 9,
      ),
      if (isLeadTeacher)
        (
          icon: Icons.admin_panel_settings_rounded,
          label: l10n.adminPanel,
          color: Colors.redAccent,
          index: 10,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 600,
            constraints: const BoxConstraints(maxWidth: 600),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? SchoolColors.darkBorder
                          : SchoolColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.center,
                  ),
                  Text(
                    l10n.more,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? SchoolColors.darkText : SchoolColors.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  if (isLeadTeacher) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onCreateClass,
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: Text(
                        l10n.createClass,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: SchoolColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
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
