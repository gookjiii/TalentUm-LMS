import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/src/models/schedule.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/utils/responsive_utils.dart';
import 'package:school_world/src/screens/settings_screen.dart';

class StudentToday extends ConsumerStatefulWidget {
  const StudentToday({
    super.key,
    required this.classes,
    required this.selectedClassId,
    required this.onTabSelect,
    required this.onHomeworkTap,
    this.showSidebar = false,
  });
  final List<Map<String, dynamic>> classes;
  final String? selectedClassId;
  final ValueChanged<int> onTabSelect;
  final VoidCallback onHomeworkTap;
  final bool showSidebar;

  @override
  ConsumerState<StudentToday> createState() => _StudentTodayState();
}

class _StudentTodayState extends ConsumerState<StudentToday> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    final userAsync = ref.watch(userDocumentProvider);
    final userData = userAsync.value ?? {};
    final rawName = userData['name']?.toString() ?? user?.displayName ?? l10n.student;
    final name = rawName.trim().isNotEmpty
        ? rawName.split(RegExp(r'\s+')).first
        : l10n.student;
    final avatarUrl = userData['avatarUrl']?.toString();

    final todaySchedules = ref.watch(studentTodaySchedulesProvider);
    final classInfo = {
      for (final c in widget.classes)
        c['id'].toString(): (
          name: c['name']?.toString() ?? 'Class',
          subject: c['subject']?.toString() ?? '',
        ),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : Theme.of(context).colorScheme.surface, // Deep Indigo background
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.horizontalPadding, 32, context.horizontalPadding, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : SchoolColors.text,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mock navigation tabs
                      Row(
                        children: [
                          _DashboardTab(title: 'All', isSelected: _selectedTabIndex == 0, onTap: () => setState(() => _selectedTabIndex = 0)),
                          const SizedBox(width: 24),
                          _DashboardTab(title: 'Schedule', isSelected: _selectedTabIndex == 1, onTap: () => setState(() => _selectedTabIndex = 1)),
                          const SizedBox(width: 24),
                          _DashboardTab(title: 'Grades', isSelected: _selectedTabIndex == 2, onTap: () => setState(() => _selectedTabIndex = 2)),
                        ],
                      ),
                    ],
                  ),
                  SchoolAvatar(
                    name: name,
                    avatarUrl: avatarUrl,
                    radius: 24,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => SettingsScreen(
                          repository: AppScope.of(ctx).repository,
                          appState: AppScope.of(ctx).appState,
                        ),
                      ),
                    ),
                    showBorder: true,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding, vertical: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildUpcomingClasses(todaySchedules, classInfo, isDark)),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: _buildRecentGrades(isDark)),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAnnouncements(isDark),
                              const SizedBox(height: 24),
                              _buildQuickActions(isDark, l10n),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else if (constraints.maxWidth > 600) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildUpcomingClasses(todaySchedules, classInfo, isDark)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildRecentGrades(isDark)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildAnnouncements(isDark)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildQuickActions(isDark, l10n)),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildUpcomingClasses(todaySchedules, classInfo, isDark),
                        const SizedBox(height: 24),
                        _buildRecentGrades(isDark),
                        const SizedBox(height: 24),
                        _buildAnnouncements(isDark),
                        const SizedBox(height: 24),
                        _buildQuickActions(isDark, l10n),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildUpcomingClasses(List<ResolvedScheduleItem> schedules, Map<String, dynamic> classInfo, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6), // Surface layer
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Classes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : SchoolColors.text),
                  ),
                  Icon(Icons.more_horiz, color: isDark ? Colors.white54 : SchoolColors.muted),
                ],
              ),
              const SizedBox(height: 4),
              Text('All', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : SchoolColors.muted)),
              const SizedBox(height: 16),
              Container(height: 3, decoration: BoxDecoration(color: SchoolColors.primary, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 24),
              if (schedules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No classes today', style: TextStyle(color: Colors.grey))),
                )
              else
                ...schedules.take(4).map((item) {
                  final info = classInfo[item.classId];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ClassItemCard(item: item, className: info?.name ?? 'Class', subject: info?.subject ?? '', isDark: isDark),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentGrades(bool isDark) {
    final mockGrades = [
      ('Assignment Analysis', 95, true),
      ('Assignment Title 1', 75, true),
      ('Assignment Test 1', 86, true),
      ('Assignment Title 2', 75, true),
      ('Assignment Title 3', 80, true),
      ('Assignment Title 4', 86, true),
      ('Assignment Title 5', 85, true),
      ('Assignment Title 6', 75, true),
    ];

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Grades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : SchoolColors.text),
              ),
              Icon(Icons.more_horiz, color: isDark ? Colors.white54 : SchoolColors.muted),
            ],
          ),
          const SizedBox(height: 24),
          ...mockGrades.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Course Name', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : SchoolColors.muted)),
                      Text(g.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : SchoolColors.text), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text('${g.$2}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SchoolColors.green)), // Emerald Growth
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_up_rounded, color: SchoolColors.green),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAnnouncements(bool isDark) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Announcements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : SchoolColors.text),
          ),
          const SizedBox(height: 24),
          _AnnouncementItem(
            title: 'Elite Digital Art Updates',
            body: 'Elite Digital Campus news to latest updates.',
            time: '4 days ago',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _AnnouncementItem(
            title: 'Announcements Update',
            body: 'The news sentation to most makers reading...',
            time: '2 hours ago',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, AppLocalizations l10n) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : SchoolColors.text),
          ),
          const SizedBox(height: 24),
          _ActionButton(label: 'Submit Assignment', primary: true, onTap: () => widget.onHomeworkTap()),
          const SizedBox(height: 12),
          _ActionButton(label: 'Contact Advisor', primary: false, onTap: () => widget.onTabSelect(2)),
          const SizedBox(height: 12),
          _ActionButton(label: 'Contact Assistant', primary: false, onTap: () => widget.onTabSelect(2)),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.title, required this.isSelected, required this.onTap});
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? SchoolColors.primary : (isDark ? Colors.white54 : SchoolColors.muted),
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              height: 3,
              width: 24,
              decoration: BoxDecoration(color: SchoolColors.primary, borderRadius: BorderRadius.circular(2)),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }
}

class _ClassItemCard extends StatelessWidget {
  const _ClassItemCard({required this.item, required this.className, required this.subject, required this.isDark});
  final ResolvedScheduleItem item;
  final String className;
  final String subject;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final startLabel = DateFormat('HH:mm a').format(item.start);
    final isNow = DateTime.now().isAfter(item.start) && DateTime.now().isBefore(item.end);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : SchoolColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: SchoolColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.person, size: 20, color: SchoolColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instructor', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : SchoolColors.muted)),
                    Text(
                      subject.isNotEmpty ? subject : className,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SchoolColors.text),
                    ),
                  ],
                ),
              ),
              if (isNow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: SchoolColors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('In Progress', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SchoolColors.green)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white54 : SchoolColors.muted),
                  const SizedBox(width: 4),
                  Text('Time - $startLabel', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : SchoolColors.textSecondary)),
                ],
              ),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: SchoolColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Join Class', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({required this.title, required this.body, required this.time, required this.isDark});
  final String title;
  final String body;
  final String time;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : SchoolColors.text)),
        const SizedBox(height: 4),
        Text(body, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : SchoolColors.textSecondary)),
        const SizedBox(height: 8),
        Text(time, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : SchoolColors.muted)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.primary, required this.onTap});
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (primary) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: SchoolColors.primary, // Vibrant Amethyst
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    } else {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: BorderSide(color: isDark ? Colors.white24 : SchoolColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: TextStyle(color: isDark ? Colors.white : SchoolColors.text, fontWeight: FontWeight.w600)),
      );
    }
  }
}
