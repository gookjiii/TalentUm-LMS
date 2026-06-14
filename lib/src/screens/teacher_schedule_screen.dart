import 'package:school_world/src/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/providers/app_providers.dart';

import '../../main.dart';
import '../models/schedule.dart' hide colorFromHex;
import '../theme.dart';

/// Google-Calendar style weekly schedule editor for teachers.
class TeacherScheduleScreen extends ConsumerStatefulWidget {
  const TeacherScheduleScreen({
    super.key,
    this.readOnly = false,
    this.studentClassIds,
    this.studentClasses,
  });

  final bool readOnly;
  final List<String>? studentClassIds;
  final List<Map<String, dynamic>>? studentClasses;


  @override
  ConsumerState<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends ConsumerState<TeacherScheduleScreen> {
  /// Monday of the currently shown week (local date, midnight).
  late DateTime _weekStart;
  static const _startHour = 6;
  static const _endHour = 22;

  String? _selectedClassId; // null means My Schedule

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) {
      return Scaffold(body: Center(child: Text(l10n.errorGeneric)));
    }

    final appState = ref.watch(schoolAppStateProvider);
    final classesAsync = ref.watch(teacherClassesStreamProvider);

    final Stream<List<ScheduleEntry>> schedulesStream;
    final Stream<List<ScheduleOverride>> overridesStream;
    final List<dynamic> streamKeys;

    if (_selectedClassId == null) {
      if (widget.readOnly) {
        final ids = widget.studentClassIds ?? const [];
        schedulesStream = repo.studentSchedulesStream(ids);
        overridesStream = repo.studentScheduleOverridesStream(ids);
        streamKeys = ['student_all', ...ids];
      } else {
        schedulesStream = repo.teacherSchedulesStream(uid);
        overridesStream = repo.teacherScheduleOverridesStream(uid);
        streamKeys = [uid];
      }
    } else {
      schedulesStream = repo.studentSchedulesStream([_selectedClassId!]);
      overridesStream = repo.studentScheduleOverridesStream([_selectedClassId!]);
      streamKeys = [_selectedClassId!];
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          DateFormat('MMMM yyyy', l10n.localeName).format(_weekStart),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: l10n.previousWeek,
            onPressed: () => setState(
              () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
          ),
          IconButton(
            tooltip: l10n.nextWeek,
            onPressed: () => setState(
              () => _weekStart = _weekStart.add(const Duration(days: 7)),
            ),
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.today,
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _weekStart = DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).subtract(Duration(days: now.weekday - 1));
              });
            },
            icon: const Icon(Icons.today_outlined, size: 22),
          ),
          if (!widget.readOnly) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SchoolColors.primary, SchoolColors.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: () => showScheduleEditor(
                  context,
                  prefillDate: DateTime.now(),
                  prefillClassId: _selectedClassId,
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: l10n.addALesson,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (appState.isTeacher || (widget.readOnly && widget.studentClasses != null && widget.studentClasses!.length > 1))
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    if (appState.isTeacher)
                      Expanded(
                        child: classesAsync.when(
                          data: (classes) {
                            final classIds = classes.map((c) => c['id'] as String).toList();
                            if (_selectedClassId != null && !classIds.contains(_selectedClassId)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _selectedClassId = null);
                              });
                            }
                            final safeSelectedId = classIds.contains(_selectedClassId) ? _selectedClassId : null;
  
                            return Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? SchoolColors.darkSurfaceElevated
                                    : Colors.grey.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? SchoolColors.darkBorder
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: safeSelectedId,
                                  isExpanded: true,
                                  dropdownColor: isDark ? SchoolColors.darkSurface : null,
                                  hint: Text(
                                    AppLocalizations.of(context)!.mySchedule,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? SchoolColors.darkText : SchoolColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: TextStyle(
                                    color: isDark ? SchoolColors.darkText : SchoolColors.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline_rounded,
                                            size: 16,
                                            color: SchoolColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              AppLocalizations.of(context)!.mySchedule,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    for (final c in classes)
                                      DropdownMenuItem<String?>(
                                        value: c['id'] as String,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: parseHexColor(c['coverColor']),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                c['name']?.toString() ?? AppLocalizations.of(context)!.classText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedClassId = val;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 38,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    if (widget.readOnly && widget.studentClasses != null && widget.studentClasses!.length > 1) ...[
                      if (appState.isTeacher) const SizedBox(width: 16),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final classes = widget.studentClasses!;
                            final classIds = classes.map((c) => c['id'] as String).toList();
                            final safeSelectedId = (_selectedClassId != null && classIds.contains(_selectedClassId))
                                ? _selectedClassId
                                : null;
  
                            return Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? SchoolColors.darkSurfaceElevated
                                    : Colors.grey.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? SchoolColors.darkBorder
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: safeSelectedId,
                                  isExpanded: true,
                                  dropdownColor: isDark ? SchoolColors.darkSurface : null,
                                  hint: Text(
                                    l10n.allClasses,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? SchoolColors.darkText : SchoolColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: TextStyle(
                                    color: isDark ? SchoolColors.darkText : SchoolColors.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.dashboard_rounded,
                                            size: 16,
                                            color: SchoolColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.allClasses,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    for (final c in classes)
                                      DropdownMenuItem<String?>(
                                        value: c['id'] as String,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: parseHexColor(c['coverColor']),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                c['name']?.toString() ?? l10n.classText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedClassId = val;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: CachedStreamBuilder<List<ScheduleEntry>>(
        streamFactory: () => schedulesStream,
        keys: streamKeys,
        builder: (context, scheduleSnap) {
          return CachedStreamBuilder<List<ScheduleOverride>>(
            streamFactory: () => overridesStream,
            keys: streamKeys,
            builder: (context, overrideSnap) {
              final schedules = scheduleSnap.data ?? const <ScheduleEntry>[];
              final overrides = overrideSnap.data ?? const <ScheduleOverride>[];
              return _TimelineGrid(
                weekStart: _weekStart,
                startHour: _startHour,
                endHour: _endHour,
                schedules: schedules,
                overrides: overrides,
                classes: appState.isTeacher ? (classesAsync.valueOrNull ?? []) : (widget.studentClasses ?? []),
                readOnly: widget.readOnly,
                onItemTap: widget.readOnly ? (sched, date) {} : (sched, date) => showScheduleEditor(
                  context,
                  existing: sched,
                  prefillDate: date,
                  prefillClassId: _selectedClassId,
                ),
              );
            },
          );
        },
      ),

            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showScheduleEditor(
  BuildContext context, {
  DateTime? prefillDate,
  int? prefillStartMinute,
  ScheduleEntry? existing,
  String? prefillClassId,
}) async {
  final isMobile = MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _ScheduleEditorSheet(
          prefillDate: prefillDate ?? DateTime.now(),
          prefillStartMinute: prefillStartMinute,
          existing: existing,
          prefillClassId: prefillClassId,
        ),
      ),
    );
  } else {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _ScheduleEditorSheet(
            prefillDate: prefillDate ?? DateTime.now(),
            prefillStartMinute: prefillStartMinute,
            existing: existing,
            prefillClassId: prefillClassId,
          ),
        ),
      ),
    );
  }
}

class _TimelineGrid extends StatefulWidget {
  const _TimelineGrid({
    required this.weekStart,
    required this.startHour,
    required this.endHour,
    required this.schedules,
    required this.overrides,
    required this.classes,
    required this.onItemTap,
    required this.readOnly,
  });

  final DateTime weekStart;
  final int startHour;
  final int endHour;
  final List<ScheduleEntry> schedules;
  final List<ScheduleOverride> overrides;
  final List<Map<String, dynamic>> classes;
  final void Function(ScheduleEntry sched, DateTime date) onItemTap;
  final bool readOnly;

  @override
  State<_TimelineGrid> createState() => _TimelineGridState();
}

class _TimelineGridState extends State<_TimelineGrid> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _initSelectedDate();
  }

  @override
  void didUpdateWidget(covariant _TimelineGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) {
      _initSelectedDate();
    }
  }

  void _initSelectedDate() {
    final today = DateTime.now();
    if (today.isAfter(widget.weekStart.subtract(const Duration(days: 1))) && 
        today.isBefore(widget.weekStart.add(const Duration(days: 7)))) {
      _selectedDate = DateTime(today.year, today.month, today.day);
    } else {
      _selectedDate = widget.weekStart;
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _fmt(int min) {
    final h = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildDateSelector(context),
        const SizedBox(height: 24),
        _buildTimeline(context),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = widget.weekStart.add(Duration(days: index));
          final isSelected = _sameDay(date, _selectedDate);
          final isToday = _sameDay(date, DateTime.now());
          final l10n = AppLocalizations.of(context)!;
          final wkd = DateFormat('E', l10n.localeName).format(date).toUpperCase();
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary])
                    : null,
                color: isSelected ? null : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    wkd,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : SchoolColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : SchoolColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final items = resolveDay(
      date: _selectedDate,
      schedules: widget.schedules,
      overrides: widget.overrides,
    );
    
    if (items.isEmpty) {
      return Expanded(
        child: Center(
          child: EmptyState(
            icon: Icons.event_available_rounded,
            title: 'No classes today',
            subtitle: 'Enjoy your free time!',
          ),
        ),
      );
    }
    
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final it = items[index];
          final sched = widget.schedules.where((s) => s.id == it.scheduleId).firstOrNull;
          return _buildTimelineItem(context, it, sched, index == items.length - 1);
        },
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, ResolvedScheduleItem it, ScheduleEntry? sched, bool isLast) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final isActive = _sameDay(_selectedDate, now) && nowMin >= it.startMinute && nowMin <= it.endMinute;
    
    final clsData = widget.classes.firstWhere((c) => c['id'] == it.classId, orElse: () => <String, dynamic>{});
    final clsName = clsData['name']?.toString() ?? it.classId;
    final clsSubject = clsData['subject']?.toString() ?? '—';
    final color = colorFromHex(it.color, SchoolColors.primary);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 14),
                Text(
                  _fmt(it.startMinute),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isActive ? color : null),
                ),
                Text(
                  _fmt(it.endMinute),
                  style: const TextStyle(color: SchoolColors.muted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Timeline Line
          Column(
            children: [
              const SizedBox(height: 18),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? color.withValues(alpha: 0.5) : color.withValues(alpha: 0.3), width: isActive ? 4 : 2),
                  boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)] : [],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.15),
                  ),
                ),
              if (isLast)
                const SizedBox(height: 16),
            ],
          ),
          const SizedBox(width: 16),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: (widget.readOnly || sched == null) ? null : () => widget.onItemTap(sched, it.date),
                child: NestedBezelCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              it.note?.isNotEmpty == true ? it.note! : clsSubject,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                decoration: it.cancelled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (it.cancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: SchoolColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Text('CANCELLED', style: TextStyle(color: SchoolColors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.room_rounded, size: 14, color: SchoolColors.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${it.room ?? clsName}${it.room != null ? ' · $clsName' : ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: SchoolColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isActive && !it.cancelled) ...[
                        const SizedBox(height: 12),
                        _PulsingJoinButton(color: color),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingJoinButton extends StatefulWidget {
  const _PulsingJoinButton({required this.color});
  final Color color;

  @override
  State<_PulsingJoinButton> createState() => _PulsingJoinButtonState();
}

class _PulsingJoinButtonState extends State<_PulsingJoinButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35 * _ctrl.value),
                blurRadius: 16 * _ctrl.value,
                spreadRadius: 2 * _ctrl.value,
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: widget.color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.video_camera_front_rounded, size: 18),
            label: const Text(
              'Join Virtual Class',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

// ── Editor bottom sheet ─────────────────────────────────────────────────

/// Public wrapper for the editor form to be used in the sidebar
class ScheduleEditorForm extends StatelessWidget {
  const ScheduleEditorForm({
    super.key,
    required this.prefillDate,
    this.prefillStartMinute,
    this.existing,
    this.prefillClassId,
  });

  final DateTime prefillDate;
  final int? prefillStartMinute;
  final ScheduleEntry? existing;
  final String? prefillClassId;

  @override
  Widget build(BuildContext context) {
    return _ScheduleEditorSheet(
      prefillDate: prefillDate,
      prefillStartMinute: prefillStartMinute,
      existing: existing,
      prefillClassId: prefillClassId,
    );
  }
}

class _ScheduleEditorSheet extends StatefulWidget {
  const _ScheduleEditorSheet({
    required this.prefillDate,
    this.prefillStartMinute,
    this.existing,
    this.prefillClassId,
  });

  final DateTime prefillDate;
  final int? prefillStartMinute;
  final ScheduleEntry? existing;
  final String? prefillClassId;

  @override
  State<_ScheduleEditorSheet> createState() => _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends State<_ScheduleEditorSheet> {
  String? _classId;
  bool _recurring = true;
  int? _dayOfWeek;
  DateTime? _oneOffDate;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 0);
  final _room = TextEditingController();
  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;
  String? _colorOverride;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _classId = e.classId;
      _recurring = e.isRecurring;
      _dayOfWeek = e.dayOfWeek;
      _oneOffDate = e.oneOffDate;
      _start = TimeOfDay(hour: e.startMinute ~/ 60, minute: e.startMinute % 60);
      _end = TimeOfDay(hour: e.endMinute ~/ 60, minute: e.endMinute % 60);
      _room.text = e.room ?? '';
      _effectiveFrom = e.effectiveFrom;
      _effectiveTo = e.effectiveTo;
      _colorOverride = e.color;
    } else {
      _classId = widget.prefillClassId;
      _dayOfWeek = widget.prefillDate.weekday;
      _oneOffDate = widget.prefillDate;
      if (widget.prefillStartMinute != null) {
        _start = TimeOfDay(
          hour: widget.prefillStartMinute! ~/ 60,
          minute: widget.prefillStartMinute! % 60,
        );
        final endMin = widget.prefillStartMinute! + 60;
        _end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
      }
    }
  }

  @override
  void dispose() {
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: context.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? l10n.createClass : l10n.settings,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, _) {
                  final allClassAsync = ref.watch(teacherClassesStreamProvider);
                  
                  return allClassAsync.when(
                    data: (docs) {
                      if (docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            l10n.noClassesTeacherDesc,
                            style: const TextStyle(
                              color: SchoolColors.muted,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      
                      final docIds = docs.map((d) => d['id'] as String).toList();
                      if (_classId == null || !docIds.contains(_classId)) {
                        _classId = docs.first['id'] as String;
                      }
                      
                      return DropdownButtonFormField<String>(
                        value: _classId,
                        decoration: InputDecoration(
                          labelText: l10n.className,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final d in docs)
                            DropdownMenuItem(
                              value: d['id'] as String,
                              child: Text(d['name']?.toString() ?? d['id'] as String),
                            ),
                        ],
                        onChanged: (v) => setState(() => _classId = v),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        l10n.errorLoadingClasses(err.toString()),
                        style: const TextStyle(
                          color: SchoolColors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l10n.recurring)),
                  ButtonSegment(value: false, label: Text(l10n.oneOff)),
                ],
                selected: {_recurring},
                onSelectionChanged: (s) => setState(() => _recurring = s.first),
              ),
              const SizedBox(height: 12),
              if (_recurring)
                DropdownButtonFormField<int>(
                  value: _dayOfWeek,
                  decoration: InputDecoration(
                    labelText: l10n.dayOfTheWeek,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 1, child: Text(l10n.monday)),
                    DropdownMenuItem(value: 2, child: Text(l10n.tuesday)),
                    DropdownMenuItem(value: 3, child: Text(l10n.wednesday)),
                    DropdownMenuItem(value: 4, child: Text(l10n.thursday)),
                    DropdownMenuItem(value: 5, child: Text(l10n.friday)),
                    DropdownMenuItem(value: 6, child: Text(l10n.saturday)),
                    DropdownMenuItem(value: 7, child: Text(l10n.sunday)),
                  ],
                  onChanged: (v) => setState(() => _dayOfWeek = v),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _oneOffDate == null
                        ? l10n.selectDate
                        : DateFormat('EEE, d MMM', l10n.localeName).format(_oneOffDate!),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _oneOffDate ?? widget.prefillDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _oneOffDate = picked);
                    }
                  },
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: l10n.start,
                      value: _start,
                      onChanged: (t) => setState(() => _start = t),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: l10n.end,
                      value: _end,
                      onChanged: (t) => setState(() => _end = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _room,
                decoration: InputDecoration(
                  labelText: l10n.officenote,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_recurring) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.start_rounded, size: 18),
                        label: Text(
                          _effectiveFrom == null
                              ? l10n.effectiveFrom
                              : DateFormat('d MMM', l10n.localeName).format(_effectiveFrom!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _effectiveFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _effectiveFrom = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_busy_rounded, size: 18),
                        label: Text(
                          _effectiveTo == null
                              ? l10n.untilDate
                              : DateFormat('d MMM', l10n.localeName).format(_effectiveTo!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _effectiveTo ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _effectiveTo = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(l10n.colorOverride, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  for (final hex in ['7C3AED', '059669', 'F97316', 'DC2626'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _colorOverride = '#$hex'),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(int.parse('FF$hex', radix: 16)),
                            shape: BoxShape.circle,
                            border: _colorOverride == '#$hex'
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: [
                              if (_colorOverride == '#$hex')
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => setState(() => _colorOverride = null),
                    icon: const Icon(Icons.block_rounded, size: 18),
                    tooltip: "Default",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (widget.existing != null)
                    TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: SchoolColors.red,
                      ),
                      label: Text(
                        l10n.delete,
                        style: const TextStyle(color: SchoolColors.red),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 52),
                    ),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(_saving ? '...' : l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_classId == null || _classId!.isEmpty) {
      _showErr(l10n.firstSelectAClass);
      return;
    }
    if (_toMin(_end) <= _toMin(_start)) {
      _showErr(l10n.theEndMustBeLater);
      return;
    }
    if (_recurring && _dayOfWeek == null) {
      _showErr(l10n.selectDayOfWeek);
      return;
    }
    if (!_recurring && _oneOffDate == null) {
      _showErr(l10n.selectDate);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = AppScope.of(context).repository;
      final fmt = DateFormat('yyyy-MM-dd');
      
      if (widget.existing == null) {
        final draft = ScheduleEntry(
          id: '',
          teacherId: repo.uid ?? '',
          classId: _classId!,
          dayOfWeek: _recurring ? _dayOfWeek : null,
          startMinute: _toMin(_start),
          endMinute: _toMin(_end),
          room: _room.text.trim().isEmpty ? null : _room.text.trim(),
          oneOffDate: _recurring ? null : _oneOffDate,
          effectiveFrom: _recurring ? _effectiveFrom : null,
          effectiveTo: _recurring ? _effectiveTo : null,
          color: _colorOverride,
        );
        await repo.createSchedule(draft);
      } else {
        await repo.updateSchedule(widget.existing!.id, {
          'classId': _classId,
          'dayOfWeek': _recurring ? _dayOfWeek : null,
          'startMinute': _toMin(_start),
          'endMinute': _toMin(_end),
          'room': _room.text.trim(),
          'oneOffDate': _recurring
              ? null
              : (_oneOffDate == null
                    ? null
                    : fmt.format(_oneOffDate!)),
          'effectiveFrom': _recurring && _effectiveFrom != null ? fmt.format(_effectiveFrom!) : null,
          'effectiveTo': _recurring && _effectiveTo != null ? fmt.format(_effectiveTo!) : null,
          'color': _colorOverride,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.savedSchedule)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErr(l10n.errorPrefix(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  Future<void> _delete() async {
    final repo = AppScope.of(context).repository;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteSchedule),
        content: Text(l10n.deleteScheduleDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await repo.deleteSchedule(widget.existing!.id);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.deletedSchedule)));
    } catch (e) {
      _showErr(l10n.errorPrefix(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErr(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.format(context),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
