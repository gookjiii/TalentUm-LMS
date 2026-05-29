import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_tab_flow.dart';
import 'package:school_world/src/features/journal/presentation/screens/journal_screen.dart';
import 'package:school_world/src/screens/teacher_schedule_screen.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/app_state.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

import '../features/today/presentation/widgets/student_today.dart';
import '../features/homework/presentation/widgets/student_homework.dart';
import '../features/feed/presentation/widgets/student_feed.dart';
import '../features/shared/presentation/widgets/student_sidebar.dart';
import '../features/shared/presentation/widgets/student_right_sidebar.dart';
import '../features/library/presentation/widgets/library_screen.dart';
import '../features/webinars/presentation/widgets/webinars_screen.dart';
class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final selectedClassId = ref.watch(
      schoolAppStateProvider.select((state) => state.selectedClassId),
    );
    final appState = ref.read(schoolAppStateProvider);
    final classesAsync = ref.watch(studentClassesStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return classesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (classes) {
        final selectedId = _selectedClassIdFromMap(selectedClassId, classes);
        final hasClasses = classes.isNotEmpty;

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            const showRightSidebar = false;

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

            final content = FadeIndexedStack(
              index: _tabIndex,
              children: [
                if (!hasClasses)
                  const JoinClassEmptyState()
                else
                  StudentToday(
                    classes: classes,
                    selectedClassId: selectedId,
                    onTabSelect: (i) => _handleTabSelection(i, wide, selectedId, repo, appState, l10n, classes),
                    showSidebar: showRightSidebar,
                    onHomeworkTap: selectedId != null
                        ? () => _handleTabSelection(3, wide, selectedId, repo, appState, l10n, classes)
                        : () {},
                  ),

                if (hasClasses && selectedId != null)
                  StudentFeed(
                    classId: selectedId,
                    classes: classes,
                    onClassSelect: (id) => appState.selectClass(id),
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

                if (hasClasses && selectedId != null)
                  StudentHomework(classId: selectedId)
                else
                  _FeatureLockedEmptyState(
                    title: AppLocalizations.of(context)!.quests,
                    icon: Icons.assignment_outlined,
                  ),

                if (hasClasses)
                  TeacherScheduleScreen(
                    readOnly: true,
                    studentClassIds: classes.map((c) => c['id'] as String).toList(),
                  )
                else
                  _FeatureLockedEmptyState(
                    title: AppLocalizations.of(context)!.schedule,
                    icon: Icons.calendar_month_outlined,
                  ),

                if (hasClasses && selectedId != null)
                  LibraryScreen(classId: selectedId)
                else
                  _FeatureLockedEmptyState(
                    title: AppLocalizations.of(context)!.library,
                    icon: Icons.library_books_outlined,
                  ),

                if (hasClasses && selectedId != null)
                  WebinarsScreen(classId: selectedId)
                else
                  _FeatureLockedEmptyState(
                    title: AppLocalizations.of(context)!.webinars,
                    icon: Icons.ondemand_video_outlined,
                  ),

                // Journal — read-only, filtered to the current student
                if (hasClasses && selectedId != null)
                  JournalScreen(
                    classId: selectedId,
                    studentId: repo.uid,
                  )
                else
                  _FeatureLockedEmptyState(
                    title: AppLocalizations.of(context)!.magazine,
                    icon: Icons.book_outlined,
                  ),
              ],
            );

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    StudentSidebar(
                      extended: constraints.maxWidth >= 1200,
                      selectedIndex: _tabIndex,
                      onSelect: (i) => setState(() => _tabIndex = i),
                      navigationItems: navItems,
                      classes: classes,
                      activeClassId: selectedId,
                      onSelectClass: (id) => appState.selectClass(id),
                    ),
                  Expanded(child: content),
                  if (showRightSidebar && hasClasses)
                    SizedBox(
                      width: 320,
                      child: StudentRightSidebar(classes: classes),
                    ),
                ],
              ),
              bottomNavigationBar: wide
                  ? null
                  : Builder(
                      builder: (context) {
                        // 0=Today, 2=Chat, 3=Homework, 4=Schedule; More opens sheet
                        const mobileIndices = [0, 2, 3, 4];
                        final mobileNavItems = mobileIndices.map((i) => navItems[i]).toList();
                        var mobileSelected = mobileIndices.indexOf(_tabIndex);

                        if (mobileSelected < 0) mobileSelected = -1;

                        return _MobileTabBar(
                          selectedIndex: mobileSelected,
                          onSelect: (i) {
                            HapticFeedback.lightImpact();
                            setState(() => _tabIndex = mobileIndices[i]);
                          },
                          items: mobileNavItems,
                          onMoreTap: () => _showMoreSheet(
                            context,
                            classes,
                            selectedId,
                            repo,
                            appState,
                            l10n,
                          ),
                          moreSelected: mobileSelected < 0,
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
          _handleTabSelection(index, false, selectedId, repo, appState, l10n, classes);
        },
        l10n: l10n,
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
    const mobileIndices = [0, 1, 2, 3, 7];

    if (!wide && !mobileIndices.contains(index)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(_getStudentTabTitle(index, l10n)),
            ),
            body: Container(
              color: Theme.of(ctx).colorScheme.surface,
              child: _getStudentTabWidget(index, selectedId, repo, appState, classes),
            ),
          ),
        ),
      );
    } else {
      setState(() => _tabIndex = index);
    }
  }

  String _getStudentTabTitle(int index, AppLocalizations l10n) {
    switch (index) {
      case 4:
        return AppLocalizations.of(context)!.schedule;
      case 5:
        return AppLocalizations.of(context)!.library;
      case 6:
        return AppLocalizations.of(context)!.webinars;
      case 7:
        return AppLocalizations.of(context)!.magazine;
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
        );
      case 5:
        return LibraryScreen(classId: selectedId ?? '');
      case 6:
        return WebinarsScreen(classId: selectedId ?? '');
      case 7:
        return JournalScreen(
          classId: selectedId ?? '',
          studentId: repo.uid,
        );
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

class JoinClassEmptyState extends StatelessWidget {
  const JoinClassEmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.school_outlined,
      title: AppLocalizations.of(context)!.joinYourFirstClass,
      subtitle:
          AppLocalizations.of(context)!.enterTheTeacherInvitationCode,
      actionLabel: AppLocalizations.of(context)!.enterInvitationCode,
      action: () => showDialog(
        context: context,
        builder: (_) =>
            JoinClassDialog(repository: AppScope.of(context).repository),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                selected ? selectedIcon : icon,
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
    );
  }
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet({required this.onSelect, required this.l10n});
  final ValueChanged<int> onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (icon: Icons.campaign_rounded, label: l10n.feed, color: SchoolColors.secondary, index: 1),
      (icon: Icons.library_books_rounded, label: l10n.library, color: SchoolColors.accent, index: 5),
      (icon: Icons.ondemand_video_rounded, label: l10n.webinars, color: SchoolColors.primary, index: 6),
      (icon: Icons.book_rounded, label: l10n.magazine, color: SchoolColors.orange, index: 7),
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
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
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
              children: items.map((item) => _MoreItem(
                icon: item.icon,
                label: item.label,
                color: item.color,
                isDark: isDark,
                onTap: () => onSelect(item.index),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
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
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.joinTheClass),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.invitationCode,
                errorText: _error,
                prefixIcon: const Icon(Icons.key_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.or,
              style: TextStyle(
                fontSize: 10,
                color: SchoolColors.muted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.theCameraWillBeAvailable),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(AppLocalizations.of(context)!.scanQrCode),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: SchoolColors.primary),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.unknownKey),
        ),
        FilledButton(
          onPressed: _loading ? null : _join,
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppLocalizations.of(context)!.join),
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

class _MobileTabBar extends StatelessWidget {
  const _MobileTabBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
    required this.onMoreTap,
    this.moreSelected = false,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavDest> items;
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
                    child: _NavTabItem(
                      icon: item.icon,
                      selectedIcon: item.selectedIcon,
                      selected: selected,
                      isDark: isDark,
                      onTap: () => onSelect(index),
                    ),
                  );
                }),
                Expanded(
                  child: _NavTabItem(
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view_rounded,
                    selected: moreSelected,
                    isDark: isDark,
                    onTap: onMoreTap,
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
