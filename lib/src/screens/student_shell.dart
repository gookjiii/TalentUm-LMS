import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_tab_flow.dart';
import 'package:school_world/src/features/journal/presentation/screens/journal_screen.dart';
import 'package:school_world/src/screens/teacher_schedule_screen.dart';
import 'package:school_world/src/screens/settings_screen.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/app_state.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/widgets/skeletal_loaders.dart';

import '../features/today/presentation/widgets/student_today.dart';
import '../features/homework/presentation/widgets/student_homework.dart';
import '../features/feed/presentation/widgets/student_feed.dart';
import '../features/shared/presentation/widgets/student_sidebar.dart';
import '../features/library/presentation/widgets/library_screen.dart';
import '../features/webinars/presentation/widgets/webinars_screen.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _tabIndex = 0;
  bool _showSettings = false;
  late final SchoolAppState _appState;
  int _handledChatNavigationRevision = 0;

  @override
  void initState() {
    super.initState();
    _appState = ref.read(schoolAppStateProvider);
    _handledChatNavigationRevision = _appState.chatNavigationRevision;
    if (_handledChatNavigationRevision > 0) _tabIndex = 2;
    _appState.addListener(_handleAppStateChange);
  }

  @override
  void dispose() {
    _appState.removeListener(_handleAppStateChange);
    super.dispose();
  }

  void _handleAppStateChange() {
    final revision = _appState.chatNavigationRevision;
    if (!mounted || revision == _handledChatNavigationRevision) return;
    _handledChatNavigationRevision = revision;
    if (_tabIndex != 2 || _showSettings) {
      setState(() {
        _showSettings = false;
        _tabIndex = 2;
      });
    }
  }

  void _openSettings() {
    if (!mounted) return;
    setState(() => _showSettings = true);
  }

  void _closeSettings() {
    if (!mounted) return;
    setState(() => _showSettings = false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedClassId = ref.watch(
      schoolAppStateProvider.select((state) => state.selectedClassId),
    );
    final classesAsync = ref.watch(studentClassesStreamProvider);
    final l10n = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).repository;
    final appState = AppScope.of(context).appState;
    return classesAsync.when(
      loading: () => const ShellLoadingSkeleton(),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.errorPrefix(err.toString()),
          ),
        ),
      ),
      data: (classes) {
        final selectedId = _selectedClassIdFromMap(selectedClassId, classes);
        final hasClasses = classes.isNotEmpty;

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            final navItems = [
              NavDest(
                l10n.today,
                Icons.dashboard_outlined,
                Icons.dashboard_rounded,
              ),
              NavDest(
                l10n.feed,
                Icons.campaign_outlined,
                Icons.campaign_rounded,
              ),
              NavDest(
                l10n.chat,
                Icons.chat_bubble_outline_rounded,
                Icons.chat_bubble_rounded,
              ),
              NavDest(
                l10n.homework,
                Icons.assignment_outlined,
                Icons.assignment_rounded,
              ),
              NavDest(
                AppLocalizations.of(context)!.schedule,
                Icons.calendar_month_outlined,
                Icons.calendar_month_rounded,
              ),
              NavDest(
                AppLocalizations.of(context)!.library,
                Icons.library_books_outlined,
                Icons.library_books_rounded,
              ),
              NavDest(
                AppLocalizations.of(context)!.webinars,
                Icons.ondemand_video_outlined,
                Icons.ondemand_video_rounded,
              ),
              NavDest(
                AppLocalizations.of(context)!.magazine,
                Icons.book_outlined,
                Icons.book_rounded,
              ),
            ];

            final content = _showSettings
                ? SettingsScreen(
                    repository: repo,
                    appState: appState,
                    onBack: _closeSettings,
                  )
                : FadeIndexedStack(
                    index: _tabIndex,
                    disposeInactive: appState.performanceMode,
                    children: [
                      if (!hasClasses)
                        JoinClassEmptyState(onProfileTap: _openSettings)
                      else
                        StudentToday(
                          classes: classes,
                          selectedClassId: selectedId,
                          onProfileTap: _openSettings,
                          onTabSelect: (i) => _handleTabSelection(
                            i,
                            wide,
                            selectedId,
                            repo,
                            appState,
                            l10n,
                            classes,
                          ),
                          onHomeworkTap: selectedId != null
                              ? () => _handleTabSelection(
                                  3,
                                  wide,
                                  selectedId,
                                  repo,
                                  appState,
                                  l10n,
                                  classes,
                                )
                              : () {},
                        ),

                      if (hasClasses && selectedId != null)
                        StudentFeed(
                          classId: selectedId,
                          classes: classes,
                          onClassSelect: (id) => appState.selectClass(id),
                          onProfileTap: _openSettings,
                        )
                      else
                        _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.ribbon,
                          icon: Icons.campaign_outlined,
                        ),

                      if (hasClasses)
                        ChatTabFlow(
                          repository: repo,
                          appState: appState,
                          classes: classes,
                          initialClassId: selectedId,
                          desktopMode: wide,
                          canInitializeRoom: false,
                        )
                      else
                        _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.chat,
                          icon: Icons.chat_bubble_outline_rounded,
                        ),

                      if (hasClasses && (!wide || selectedId != null))
                        StudentHomework(classId: wide ? (selectedId ?? '') : '')
                      else
                        _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.quests,
                          icon: Icons.assignment_outlined,
                        ),

                      if (hasClasses)
                        TeacherScheduleScreen(
                          readOnly: true,
                          studentClassIds: classes
                              .map((c) => c['id'] as String)
                              .toList(),
                          studentClasses: classes,
                        )
                      else
                        _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.schedule,
                          icon: Icons.calendar_month_outlined,
                        ),

                      if (hasClasses && (!wide || selectedId != null))
                        LibraryScreen(classId: wide ? (selectedId ?? '') : '')
                      else
                        _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.library,
                          icon: Icons.library_books_outlined,
                        ),

                      if (hasClasses && (!wide || selectedId != null))
                        WebinarsScreen(classId: wide ? (selectedId ?? '') : '')
                      else
                        _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.webinars,
                          icon: Icons.ondemand_video_outlined,
                        ),

                      // Journal — read-only, filtered to the current student
                      if (hasClasses && selectedId != null)
                        JournalScreen(classId: selectedId, studentId: repo.uid)
                      else
                        _FeatureLockedEmptyState(
                          title: AppLocalizations.of(context)!.magazine,
                          icon: Icons.book_outlined,
                        ),
                    ],
                  );

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: SafeArea(
                bottom: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      StudentSidebar(
                        extended: constraints.maxWidth >= 1200,
                        selectedIndex: _tabIndex,
                        onSelect: (i) {
                          setState(() {
                            _showSettings = false;
                            _tabIndex = i;
                          });
                        },
                        navigationItems: navItems,
                        classes: classes,
                        activeClassId: selectedId,
                        onSelectClass: (id) => appState.selectClass(id),
                        onProfileTap: _openSettings,
                      ),
                    Expanded(child: content),
                  ],
                ),
              ),
              bottomNavigationBar: wide
                  ? null
                  : ListenableBuilder(
                      listenable: AppScope.of(context).appState,
                      builder: (context, _) {
                        final isChatRoomOpen = AppScope.of(
                          context,
                        ).appState.isChatRoomMobileOpen;
                        if (_tabIndex == 2 && isChatRoomOpen) {
                          return const SizedBox.shrink();
                        }

                        // 0=Today, 2=Chat, 3=Homework, 4=Schedule; More opens sheet
                        const mobileIndices = [0, 2, 3, 4];
                        final mobileNavItems = mobileIndices.map((i) {
                          final item = navItems[i];
                          return SchoolMobileNavItem(
                            label: i == 3 ? l10n.homeworkShort : item.label,
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                          );
                        }).toList();
                        final mobileSelected = mobileIndices.indexOf(_tabIndex);

                        return SchoolMobileNavBar(
                          selectedIndex: mobileSelected,
                          onSelect: (i) {
                            setState(() {
                              _showSettings = false;
                              _tabIndex = mobileIndices[i];
                            });
                          },
                          items: mobileNavItems,
                          moreLabel: l10n.more,
                          onMoreTap: () => _showMoreSheet(
                            context,
                            classes,
                            selectedId,
                            repo,
                            appState,
                            l10n,
                          ),
                          moreSelected: mobileSelected < 0 && !_showSettings,
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  void _showMoreSheet(
    BuildContext context,
    List<Map<String, dynamic>> classes,
    String? selectedId,
    SchoolRepository repo,
    SchoolAppState appState,
    AppLocalizations l10n,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MoreSheet(
        onSelect: (index) {
          Navigator.pop(ctx);
          _handleTabSelection(
            index,
            false,
            selectedId,
            repo,
            appState,
            l10n,
            classes,
          );
        },
        l10n: l10n,
        onJoinClass: () {
          Navigator.pop(ctx);
          _showJoinDialog(context);
        },
      ),
    );
  }

  String? _selectedClassIdFromMap(
    String? current,
    List<Map<String, dynamic>> classes,
  ) {
    if (classes.isEmpty) return null;
    if (current != null && classes.any((doc) => doc['id'] == current))
      return current;
    return classes.first['id'] as String?;
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          JoinClassDialog(repository: AppScope.of(context).repository),
    );
  }

  void _handleTabSelection(
    int index,
    bool wide,
    String? selectedId,
    SchoolRepository repo,
    SchoolAppState appState,
    AppLocalizations l10n,
    List<Map<String, dynamic>> classes,
  ) {
    setState(() {
      _showSettings = false;
      _tabIndex = index;
    });
  }

  String _getStudentTabTitle(int index, AppLocalizations l10n) {
    switch (index) {
      case 4:
        return l10n.schedule;
      case 5:
        return l10n.library;
      case 6:
        return l10n.webinars;
      case 7:
        return l10n.magazine;
      default:
        return '';
    }
  }

  Widget _getStudentTabWidget(
    int index,
    String? selectedId,
    SchoolRepository repo,
    SchoolAppState appState,
    List<Map<String, dynamic>> classes,
  ) {
    switch (index) {
      case 4:
        return TeacherScheduleScreen(
          readOnly: true,
          studentClassIds: classes.map((c) => c['id'] as String).toList(),
          studentClasses: classes,
        );
      case 5:
        return LibraryScreen(classId: '');
      case 6:
        return WebinarsScreen(classId: '');
      case 7:
        return JournalScreen(classId: selectedId ?? '', studentId: repo.uid);
      default:
        return const SizedBox.shrink();
    }
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
      subtitle: AppLocalizations.of(context)!.joinTheClassToAccess,
    );
  }
}

class JoinClassEmptyState extends ConsumerWidget {
  const JoinClassEmptyState({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final userAsync = ref.watch(userDocumentProvider);
    final userData = userAsync.value ?? {};
    final rawName =
        userData['name']?.toString() ?? user?.displayName ?? l10n.student;
    final name = rawName.trim().isNotEmpty
        ? rawName.split(RegExp(r'\s+')).first
        : l10n.student;
    final avatarUrl = userData['avatarUrl']?.toString();

    final now = DateTime.now();
    final date = DateFormat('EEEE, MMMM d', l10n.localeName).format(now);

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
            title: AppLocalizations.of(context)!.joinYourFirstClass,
            subtitle: AppLocalizations.of(
              context,
            )!.enterTheTeacherInvitationCode,
            actionLabel: AppLocalizations.of(context)!.enterInvitationCode,
            action: () => showDialog(
              context: context,
              builder: (_) =>
                  JoinClassDialog(repository: AppScope.of(context).repository),
            ),
          ),
        ),
      ],
    );
  }
}



class _MoreSheet extends StatelessWidget {
  const _MoreSheet({
    required this.onSelect,
    required this.l10n,
    required this.onJoinClass,
  });
  final ValueChanged<int> onSelect;
  final AppLocalizations l10n;
  final VoidCallback onJoinClass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      (
        icon: Icons.campaign_rounded,
        label: l10n.feed,
        subtitle: 'Bản tin lớp học',
        color: SchoolColors.secondary,
        index: 1,
      ),
      (
        icon: Icons.library_books_rounded,
        label: l10n.library,
        subtitle: 'Tài liệu & sách',
        color: SchoolColors.accent,
        index: 5,
      ),
      (
        icon: Icons.ondemand_video_rounded,
        label: l10n.webinars,
        subtitle: 'Video & bài giảng',
        color: SchoolColors.primary,
        index: 6,
      ),
      (
        icon: Icons.book_rounded,
        label: l10n.magazine,
        subtitle: 'Nhật ký học tập',
        color: SchoolColors.orange,
        index: 7,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? SchoolColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : SchoolColors.border.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : SchoolColors.border.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.more,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? SchoolColors.darkText : SchoolColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: items
                    .map(
                      (item) => _MoreItem(
                        icon: item.icon,
                        label: item.label,
                        color: item.color,
                        isDark: isDark,
                        onTap: () => onSelect(item.index),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Material(
                color: SchoolColors.green.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onJoinClass,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SchoolColors.green.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.group_add_rounded,
                            color: SchoolColors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.joinAClass,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? SchoolColors.darkText
                                  : SchoolColors.text,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: isDark
                              ? SchoolColors.darkMuted
                              : SchoolColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({
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
      color: color.withValues(alpha: isDark ? 0.14 : 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class JoinClassDialog extends StatefulWidget {
  const JoinClassDialog({super.key, required this.repository});
  final SchoolRepository repository;
  @override
  State<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<JoinClassDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.joinTheClass),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.invitationCode,
                errorText: _error,
                prefixIcon: const Icon(Icons.key_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.or,
              style: const TextStyle(
                fontSize: 11,
                color: SchoolColors.muted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SchoolButton.outlined(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.theCameraWillBeAvailable,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: l10n.scanQrCode,
              isFullWidth: true,
            ),
          ],
        ),
      ),
      actions: [
        SchoolButton.ghost(
          onPressed: () => Navigator.pop(context),
          label: l10n.cancel,
        ),
        SchoolButton.primary(
          onPressed: _join,
          label: l10n.join,
          isLoading: _loading,
        ),
      ],
    );
  }

  Future<void> _join() async {
    final code = _controller.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (code.isEmpty) {
      setState(() => _error = l10n.enterCode);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.repository.validateInviteCode(code);
      final id = res['classId']?.toString();
      if (id == null) throw l10n.invalidCode;
      await widget.repository.joinClass(id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
