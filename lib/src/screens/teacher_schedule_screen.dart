import 'package:cloud_firestore/cloud_firestore.dart';
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
    this.initialClassId,
  });

  final bool readOnly;
  final List<String>? studentClassIds;
  final List<Map<String, dynamic>>? studentClasses;
  final String? initialClassId;

  @override
  ConsumerState<TeacherScheduleScreen> createState() =>
      _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends ConsumerState<TeacherScheduleScreen> {
  /// Monday of the currently shown week (local date, midnight).
  late DateTime _weekStart;
  late DateTime _selectedDay;
  bool _isAgendaView = true;
  static const _startHour = 6;
  static const _endHour = 22;
  static const _hourHeight = 64.0;
  String? _selectedClassId; // null means My Schedule

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
    _selectedDay = today;
  }

  @override
  void didUpdateWidget(covariant TeacherScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialClassId != widget.initialClassId &&
        _selectedClassId != widget.initialClassId) {
      setState(() => _selectedClassId = widget.initialClassId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) {
      return Scaffold(body: Center(child: Text(l10n.errorGeneric)));
    }

    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final appState = ref.watch(schoolAppStateProvider);
    final classesAsync = ref.watch(teacherClassesStreamProvider);
    final visibleClassIds =
        (classesAsync.valueOrNull ?? const <Map<String, dynamic>>[])
            .map((item) => item['id']?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList();

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
        schedulesStream = repo.teacherSchedulesStream(
          uid,
          classIds: visibleClassIds,
        );
        overridesStream = repo.teacherScheduleOverridesStream(
          uid,
          classIds: visibleClassIds,
        );
        streamKeys = [uid, ...visibleClassIds];
      }
    } else {
      schedulesStream = repo.studentSchedulesStream([_selectedClassId!]);
      overridesStream = repo.studentScheduleOverridesStream([
        _selectedClassId!,
      ]);
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
          _formatWeekTitle(_weekStart, l10n.localeName),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: l10n.previousWeek,
            onPressed: () {
              setState(() {
                _weekStart = _weekStart.subtract(const Duration(days: 7));
                _selectedDay = _selectedDay.subtract(const Duration(days: 7));
              });
            },
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
          ),
          IconButton(
            tooltip: l10n.nextWeek,
            onPressed: () {
              setState(() {
                _weekStart = _weekStart.add(const Duration(days: 7));
                _selectedDay = _selectedDay.add(const Duration(days: 7));
              });
            },
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.today,
            onPressed: () {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              setState(() {
                _weekStart = today.subtract(Duration(days: today.weekday - 1));
                _selectedDay = today;
              });
            },
            icon: const Icon(Icons.today_outlined, size: 22),
          ),
          if (isMobile)
            IconButton(
              tooltip: _isAgendaView ? l10n.openWeeklySchedule : l10n.schedule,
              onPressed: () => setState(() => _isAgendaView = !_isAgendaView),
              icon: Icon(
                _isAgendaView
                    ? Icons.calendar_view_week_rounded
                    : Icons.view_agenda_rounded,
                size: 22,
                color: _isAgendaView ? null : SchoolColors.primary,
              ),
            ),
          if (!widget.readOnly) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SchoolAddButton(
                onPressed: () => showScheduleEditor(
                  context,
                  prefillDate: _selectedDay,
                  prefillClassId: _selectedClassId,
                ),
                tooltip: l10n.addALesson,
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (appState.isTeacher ||
                (widget.readOnly &&
                    widget.studentClasses != null &&
                    widget.studentClasses!.length > 1))
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    if (appState.isTeacher)
                      Expanded(
                        child: classesAsync.when(
                          data: (classes) {
                            final classIds = classes
                                .map((c) => c['id'] as String)
                                .toList();
                            if (_selectedClassId != null &&
                                !classIds.contains(_selectedClassId)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted)
                                  setState(() => _selectedClassId = null);
                              });
                            }
                            final safeSelectedId =
                                classIds.contains(_selectedClassId)
                                ? _selectedClassId
                                : null;

                            return Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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
                                  dropdownColor: isDark
                                      ? SchoolColors.darkSurface
                                      : null,
                                  hint: Text(
                                    AppLocalizations.of(context)!.mySchedule,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? SchoolColors.darkText
                                          : SchoolColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: TextStyle(
                                    color: isDark
                                        ? SchoolColors.darkText
                                        : SchoolColors.text,
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
                                              AppLocalizations.of(
                                                context,
                                              )!.mySchedule,
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
                                                color: parseHexColor(
                                                  c['coverColor'],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                c['name']?.toString() ??
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.classText,
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
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    if (widget.readOnly &&
                        widget.studentClasses != null &&
                        widget.studentClasses!.length > 1) ...[
                      if (appState.isTeacher) const SizedBox(width: 16),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final classes = widget.studentClasses!;
                            final classIds = classes
                                .map((c) => c['id'] as String)
                                .toList();
                            final safeSelectedId =
                                (_selectedClassId != null &&
                                    classIds.contains(_selectedClassId))
                                ? _selectedClassId
                                : null;

                            return Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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
                                  dropdownColor: isDark
                                      ? SchoolColors.darkSurface
                                      : null,
                                  hint: Text(
                                    l10n.allClasses,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? SchoolColors.darkText
                                          : SchoolColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: TextStyle(
                                    color: isDark
                                        ? SchoolColors.darkText
                                        : SchoolColors.text,
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
                                                color: parseHexColor(
                                                  c['coverColor'],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                c['name']?.toString() ??
                                                    l10n.classText,
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
                      final schedules =
                          scheduleSnap.data ?? const <ScheduleEntry>[];
                      final overrides =
                          overrideSnap.data ?? const <ScheduleOverride>[];
                      final classes = appState.isTeacher
                          ? (classesAsync.valueOrNull ?? [])
                          : (widget.studentClasses ?? []);

                      if (isMobile) {
                        return Column(
                          children: [
                            _MobileWeekStrip(
                              weekStart: _weekStart,
                              selectedDay: _selectedDay,
                              schedules: schedules,
                              overrides: overrides,
                              onSelectDay: (day) =>
                                  setState(() => _selectedDay = day),
                            ),
                            Expanded(
                              child: _isAgendaView
                                  ? _MobileDayAgendaView(
                                      selectedDate: _selectedDay,
                                      items:
                                          resolveDay(
                                            date: _selectedDay,
                                            schedules: schedules,
                                            overrides: overrides,
                                          )..sort(
                                            (a, b) => a.startMinute.compareTo(
                                              b.startMinute,
                                            ),
                                          ),
                                      schedules: schedules,
                                      classes: classes,
                                      readOnly: widget.readOnly,
                                      onItemTap: widget.readOnly
                                          ? null
                                          : (sched, date) => showScheduleEditor(
                                              context,
                                              existing: sched,
                                              prefillDate: date,
                                              prefillClassId: _selectedClassId,
                                            ),
                                    )
                                  : _WeekGrid(
                                      weekStart: _weekStart,
                                      startHour: _startHour,
                                      endHour: _endHour,
                                      hourHeight: _hourHeight,
                                      schedules: schedules,
                                      overrides: overrides,
                                      classes: classes,
                                      onCellTap: widget.readOnly
                                          ? (date, minute) {}
                                          : (date, minute) =>
                                                showScheduleEditor(
                                                  context,
                                                  prefillDate: date,
                                                  prefillStartMinute: minute,
                                                  prefillClassId:
                                                      _selectedClassId,
                                                ),
                                      onItemTap: widget.readOnly
                                          ? (sched, date) {}
                                          : (sched, date) => showScheduleEditor(
                                              context,
                                              existing: sched,
                                              prefillDate: date,
                                              prefillClassId: _selectedClassId,
                                            ),
                                    ),
                            ),
                          ],
                        );
                      }

                      return _WeekGrid(
                        weekStart: _weekStart,
                        startHour: _startHour,
                        endHour: _endHour,
                        hourHeight: _hourHeight,
                        schedules: schedules,
                        overrides: overrides,
                        classes: classes,
                        onCellTap: widget.readOnly
                            ? (date, minute) {}
                            : (date, minute) => showScheduleEditor(
                                context,
                                prefillDate: date,
                                prefillStartMinute: minute,
                                prefillClassId: _selectedClassId,
                              ),
                        onItemTap: widget.readOnly
                            ? (sched, date) {}
                            : (sched, date) => showScheduleEditor(
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

String _formatWeekTitle(DateTime weekStart, String localeName) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  final startMonth = DateFormat('MMMM', localeName).format(weekStart);
  final endMonth = DateFormat('MMMM', localeName).format(weekEnd);

  if (weekStart.year == weekEnd.year && weekStart.month == weekEnd.month) {
    return DateFormat('MMMM yyyy', localeName).format(weekStart);
  }
  if (weekStart.year == weekEnd.year) {
    return '$startMonth — $endMonth ${weekStart.year}';
  }
  return '${DateFormat('MMMM yyyy', localeName).format(weekStart)} — '
      '${DateFormat('MMMM yyyy', localeName).format(weekEnd)}';
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
        child: SizedBox(
          width: 400,
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

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.weekStart,
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.schedules,
    required this.overrides,
    required this.classes,
    required this.onCellTap,
    required this.onItemTap,
  });

  final DateTime weekStart;
  final int startHour;
  final int endHour;
  final double hourHeight;
  final List<ScheduleEntry> schedules;
  final List<ScheduleOverride> overrides;
  final List<Map<String, dynamic>> classes;
  final void Function(DateTime date, int minute) onCellTap;
  final void Function(ScheduleEntry sched, DateTime date) onItemTap;

  static const _gutter = 56.0;
  static const _headerH = 68.0;

  Map<String, ScheduleEntry> get _schedById => {
    for (final s in schedules) s.id: s,
  };

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < 700;
        final dayWidth = isMobile ? 120.0 : (c.maxWidth - _gutter) / 7;
        final totalBodyWidth = dayWidth * 7;

        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Fixed Time Gutter
              _buildTimeGutter(endHour - startHour, isDark),

              // 2. Horizontally Scrollable Days
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: totalBodyWidth,
                    child: Column(
                      children: [
                        _buildHeaderRow(today, dayWidth),
                        _buildBody(
                          endHour - startHour,
                          hourHeight * (endHour - startHour),
                          dayWidth,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeGutter(int hours, bool isDark) {
    final borderColor = isDark ? SchoolColors.darkBorder : SchoolColors.border;
    return Column(
      children: [
        SizedBox(
          height: _headerH,
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
          ),
        ),
        for (int i = 0; i < hours; i++)
          SizedBox(
            width: _gutter,
            height: hourHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 0),
              child: Text(
                '${(startHour + i).toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderRow(DateTime today, double dayWidth) {
    return SizedBox(
      height: _headerH,
      child: Row(
        children: [
          for (int i = 0; i < 7; i++)
            SizedBox(
              width: dayWidth,
              child: _DayHeader(
                date: weekStart.add(Duration(days: i)),
                isToday: _sameDay(weekStart.add(Duration(days: i)), today),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(int hours, double bodyH, double dayWidth, bool isDark) {
    final borderColor = isDark ? SchoolColors.darkBorder : SchoolColors.border;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final isCurrentWeek =
        now.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        now.isBefore(weekStart.add(const Duration(days: 7)));

    return SizedBox(
      height: bodyH,
      child: Stack(
        children: [
          // Grid lines (Horizontal)
          Column(
            children: List.generate(hours, (i) {
              return SizedBox(
                height: hourHeight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                ),
              );
            }),
          ),
          // Day columns + events
          Row(
            children: List.generate(7, (dayIndex) {
              final date = weekStart.add(Duration(days: dayIndex));
              final isToday = _sameDay(date, now);
              final items = resolveDay(
                date: date,
                schedules: schedules,
                overrides: overrides,
              );
              return SizedBox(
                width: dayWidth,
                child: Stack(
                  children: [
                    // Today highlight background
                    if (isToday)
                      Positioned.fill(
                        child: Container(
                          color: SchoolColors.primary.withValues(alpha: 0.03),
                        ),
                      ),
                    // Vertical separator
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: borderColor)),
                        ),
                      ),
                    ),
                    // Tap targets per hour
                    Column(
                      children: List.generate(hours, (i) {
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => onCellTap(date, (startHour + i) * 60),
                          child: SizedBox(
                            width: double.infinity,
                            height: hourHeight,
                          ),
                        );
                      }),
                    ),
                    // Events
                    ...items.map((it) => _eventCard(it, isDark)),
                  ],
                ),
              );
            }),
          ),
          // "Now" indicator line
          if (isCurrentWeek && now.hour >= startHour && now.hour < endHour)
            Positioned(
              top: ((nowMin - startHour * 60) / 60) * hourHeight,
              left: 0,
              right: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(height: 2, color: SchoolColors.primary),
                  Positioned(
                    left: (now.weekday - 1) * dayWidth - 4,
                    top: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: SchoolColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _eventCard(ResolvedScheduleItem it, bool isDark) {
    final topMin = it.startMinute - startHour * 60;
    final top = (topMin / 60) * hourHeight;
    final height = ((it.endMinute - it.startMinute) / 60) * hourHeight;
    final visibleHeight = height.clamp(28.0, 9999.0).toDouble();
    if (top < 0 || top > (endHour - startHour) * hourHeight) {
      return const SizedBox.shrink();
    }
    final color = colorFromHex(it.color, SchoolColors.primary);
    final sched = _schedById[it.scheduleId];

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: visibleHeight,
      child: _EventCardContent(
        it: it,
        sched: sched,
        classes: classes,
        isDark: isDark,
        color: color,
        height: visibleHeight,
        onItemTap: onItemTap,
      ),
    );
  }
}

class _EventCardContent extends StatelessWidget {
  const _EventCardContent({
    required this.it,
    required this.sched,
    required this.classes,
    required this.isDark,
    required this.color,
    required this.height,
    required this.onItemTap,
  });

  final ResolvedScheduleItem it;
  final ScheduleEntry? sched;
  final List<Map<String, dynamic>> classes;
  final bool isDark;
  final Color color;
  final double height;
  final void Function(ScheduleEntry sched, DateTime date)? onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).repository;

    final clsData = classes.firstWhere(
      (c) => c['id'] == it.classId,
      orElse: () => <String, dynamic>{},
    );

    final String? existingName = clsData['name']?.toString();
    if (existingName != null && existingName.isNotEmpty) {
      return _buildCardUI(
        context,
        l10n: l10n,
        className: existingName,
        subject: clsData['subject']?.toString() ?? '—',
      );
    }

    if (it.classId.isEmpty) {
      return _buildCardUI(
        context,
        l10n: l10n,
        className: l10n.classText,
        subject: '—',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.firestore.collection('classes').doc(it.classId).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final rawName = data?['name']?.toString();
        final className = (rawName != null && rawName.isNotEmpty)
            ? rawName
            : l10n.classText;
        final subject = data?['subject']?.toString() ?? '—';

        return _buildCardUI(
          context,
          l10n: l10n,
          className: className,
          subject: subject,
        );
      },
    );
  }

  Widget _buildCardUI(
    BuildContext context, {
    required AppLocalizations l10n,
    required String className,
    required String subject,
  }) {
    final classLabel = (subject != '—' && subject.isNotEmpty)
        ? subject
        : className;
    final lessonSubject = it.subject?.isNotEmpty == true
        ? it.subject!
        : (it.note?.isNotEmpty == true
              ? it.note!
              : (classLabel != className ? className : ''));
    final roomText = it.room;

    final showClassLabel = height >= 28;
    final showSubject = height >= 28 && lessonSubject.isNotEmpty;
    final showRoom = height >= 64 && roomText != null && roomText.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: sched == null ? null : () => onItemTap?.call(sched!, it.date),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color.withValues(alpha: it.cancelled ? .12 : .18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: .55)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_fmt(it.startMinute)} – ${_fmt(it.endMinute)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: color,
                  decoration: it.cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              if (showClassLabel) ...[
                const SizedBox(height: 1),
                Text(
                  classLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? SchoolColors.darkTextSecondary
                        : SchoolColors.textSecondary,
                    decoration: it.cancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
              if (showSubject) ...[
                const SizedBox(height: 1),
                Text(
                  lessonSubject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: isDark ? SchoolColors.darkText : SchoolColors.text,
                    decoration: it.cancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
              if (showRoom) ...[
                const SizedBox(height: 1),
                Text(
                  roomText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? SchoolColors.darkTextSecondary
                        : SchoolColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(int min) {
    final h = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

String _fmt(int min) {
  final h = (min ~/ 60).toString().padLeft(2, '0');
  final m = (min % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.isToday});
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wkd = DateFormat('E', l10n.localeName).format(date).toUpperCase();
    final dd = DateFormat('d', l10n.localeName).format(date);
    final textColor = isToday
        ? SchoolColors.primary
        : (isDark ? SchoolColors.darkText : SchoolColors.text);
    final mutedColor = isDark ? SchoolColors.darkMuted : SchoolColors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            wkd,
            style: TextStyle(
              fontSize: 10,
              height: 1.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: isToday ? SchoolColors.primary : mutedColor,
            ),
          ),
          const SizedBox(height: 1),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday
                  ? SchoolColors.primary.withValues(alpha: .15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              dd,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Schedule Components ───────────────────────────────────────────

class _MobileWeekStrip extends StatelessWidget {
  const _MobileWeekStrip({
    required this.weekStart,
    required this.selectedDay,
    required this.schedules,
    required this.overrides,
    required this.onSelectDay,
  });

  final DateTime weekStart;
  final DateTime selectedDay;
  final List<ScheduleEntry> schedules;
  final List<ScheduleOverride> overrides;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final d in days)
            Expanded(
              child: _DayStripTile(
                date: d,
                isToday: _sameDay(d, today),
                isSelected: _sameDay(d, selectedDay),
                schedules: schedules,
                overrides: overrides,
                isDark: isDark,
                localeName: l10n.localeName,
                onTap: () => onSelectDay(d),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayStripTile extends StatelessWidget {
  const _DayStripTile({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.schedules,
    required this.overrides,
    required this.isDark,
    required this.localeName,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final List<ScheduleEntry> schedules;
  final List<ScheduleOverride> overrides;
  final bool isDark;
  final String localeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wkd = DateFormat('E', localeName).format(date).toUpperCase();
    final dayNum = DateFormat('d', localeName).format(date);
    final dayItems = resolveDay(
      date: date,
      schedules: schedules,
      overrides: overrides,
    );

    // Active lesson colors for dot indicator
    final dotColors = dayItems
        .take(3)
        .map((it) => colorFromHex(it.color, SchoolColors.primary))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? SchoolColors.primary
                  : (isToday
                        ? SchoolColors.primary.withValues(
                            alpha: isDark ? 0.2 : 0.1,
                          )
                        : (isDark
                              ? SchoolColors.darkSurfaceElevated
                              : Colors.grey.withValues(alpha: 0.06))),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? SchoolColors.primary
                    : (isToday
                          ? SchoolColors.primary.withValues(alpha: 0.5)
                          : (isDark
                                ? SchoolColors.darkBorder
                                : Colors.grey.withValues(alpha: 0.15))),
                width: isToday && !isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: SchoolColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wkd,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : (isToday
                              ? SchoolColors.primary
                              : (isDark
                                    ? SchoolColors.darkMuted
                                    : SchoolColors.muted)),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dayNum,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? SchoolColors.darkText : SchoolColors.text),
                  ),
                ),
                const SizedBox(height: 4),
                // Dots row
                SizedBox(
                  height: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (dotColors.isEmpty)
                        const SizedBox(width: 4)
                      else
                        for (final c in dotColors)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : c,
                              shape: BoxShape.circle,
                            ),
                          ),
                    ],
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

class _MobileDayAgendaView extends StatelessWidget {
  const _MobileDayAgendaView({
    required this.selectedDate,
    required this.items,
    required this.schedules,
    required this.classes,
    required this.readOnly,
    required this.onItemTap,
  });

  final DateTime selectedDate;
  final List<ResolvedScheduleItem> items;
  final List<ScheduleEntry> schedules;
  final List<Map<String, dynamic>> classes;
  final bool readOnly;
  final void Function(ScheduleEntry sched, DateTime date)? onItemTap;

  Map<String, ScheduleEntry> get _schedById => {
    for (final s in schedules) s.id: s,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday = _sameDay(selectedDate, now);

    final dayTitle = DateFormat(
      'EEEE, d MMMM',
      l10n.localeName,
    ).format(selectedDate);
    final capitalizedDayTitle = dayTitle.isNotEmpty
        ? '${dayTitle[0].toUpperCase()}${dayTitle.substring(1)}'
        : dayTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            capitalizedDayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: SchoolColors.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.today.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: SchoolColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items.isEmpty
                          ? l10n.noClassesScheduled
                          : '${items.length} ${l10n.classText.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? SchoolColors.darkMuted
                            : SchoolColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items List or Empty State
        Expanded(
          child: items.isEmpty
              ? _MobileEmptyAgendaView(
                  selectedDate: selectedDate,
                  readOnly: readOnly,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final sched = _schedById[item.scheduleId];
                    return _MobileLessonCard(
                      item: item,
                      sched: sched,
                      classes: classes,
                      readOnly: readOnly,
                      onTap: sched == null
                          ? null
                          : () => onItemTap?.call(sched, item.date),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MobileLessonCard extends StatelessWidget {
  const _MobileLessonCard({
    required this.item,
    required this.sched,
    required this.classes,
    required this.readOnly,
    required this.onTap,
  });

  final ResolvedScheduleItem item;
  final ScheduleEntry? sched;
  final List<Map<String, dynamic>> classes;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final isSameDayAsNow = _sameDay(item.date, now);

    final isLive =
        isSameDayAsNow &&
        nowMin >= item.startMinute &&
        nowMin < item.endMinute &&
        !item.cancelled;
    final isDone = isSameDayAsNow && nowMin >= item.endMinute;
    final isUpcoming = isSameDayAsNow && nowMin < item.startMinute;

    final clsData = classes.firstWhere(
      (c) => c['id'] == item.classId,
      orElse: () => <String, dynamic>{},
    );

    final rawClsName = clsData['name']?.toString();
    final clsName = (rawClsName != null && rawClsName.isNotEmpty)
        ? rawClsName
        : (item.classId.length > 15 ? l10n.classText : item.classId);
    final clsSubject = clsData['subject']?.toString() ?? '—';
    final lessonSubject = item.subject?.isNotEmpty == true
        ? item.subject!
        : clsSubject;
    final primaryTitle = lessonSubject.isNotEmpty && lessonSubject != '—'
        ? lessonSubject
        : clsName;
    final subtitle = primaryTitle != clsName ? clsName : '';
    final studentCount = (clsData['studentIds'] as List?)?.length ?? 0;
    final room = item.room?.trim();
    final color = colorFromHex(item.color, SchoolColors.primary);
    final durationMin = item.endMinute - item.startMinute;

    return SchoolCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Accent Strip
            Container(
              width: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: item.cancelled ? Colors.grey : color,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(5),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Time + Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: isDark ? 0.18 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_fmt(item.startMinute)} – ${_fmt(item.endMinute)} ($durationMin ${l10n.inMin(0).replaceAll(RegExp(r'[^a-zA-Zа-яА-Я]'), '').trim()})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? color.withValues(alpha: 0.9)
                                  : color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (item.cancelled)
                          StatusChip(
                            label: l10n.cancelled.toUpperCase(),
                            color: SchoolColors.red,
                          )
                        else if (isLive)
                          const StatusChip(
                            label: 'LIVE',
                            color: SchoolColors.primary,
                            pulseDot: true,
                          )
                        else if (isDone)
                          StatusChip(
                            label: l10n.done.toUpperCase(),
                            color: SchoolColors.muted,
                            icon: Icons.check_circle_outline_rounded,
                          )
                        else if (isUpcoming)
                          StatusChip(
                            label: l10n.upcoming.toUpperCase(),
                            color: SchoolColors.secondary,
                            icon: Icons.access_time_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title & Class Info
                    Row(
                      children: [
                        ClassBadge(
                          name: primaryTitle,
                          color: color,
                          size: 40,
                          radius: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                primaryTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  decoration: item.cancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (subtitle.isNotEmpty) ...[
                                    Flexible(
                                      child: Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? SchoolColors.darkTextSecondary
                                              : SchoolColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' · ',
                                      style: TextStyle(
                                        color: SchoolColors.muted.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (studentCount > 0)
                                    Text(
                                      l10n.studentsCount(studentCount),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? SchoolColors.darkMuted
                                            : SchoolColors.muted,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!readOnly && onTap != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? SchoolColors.darkMuted
                                : SchoolColors.muted,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    // Room & Note (if available)
                    if ((room != null && room.isNotEmpty) ||
                        (item.note != null &&
                            item.note!.trim().isNotEmpty)) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (room != null && room.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? SchoolColors.darkSurfaceElevated
                                    : Colors.grey.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? SchoolColors.darkBorder
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 13,
                                    color: isDark
                                        ? SchoolColors.darkMuted
                                        : SchoolColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.cabinetWithNumber(room),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? SchoolColors.darkTextSecondary
                                          : SchoolColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.note != null && item.note!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                item.note!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileEmptyAgendaView extends StatelessWidget {
  const _MobileEmptyAgendaView({
    required this.selectedDate,
    required this.readOnly,
  });

  final DateTime selectedDate;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: SchoolColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 34,
                color: SchoolColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noClassesScheduled,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('d MMMM yyyy', l10n.localeName).format(selectedDate),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Editor bottom sheet ─────────────────────────────────────────────────

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
  final _subject = TextEditingController();
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
      _subject.text = e.subject ?? '';
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
    _subject.dispose();
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
          padding: const EdgeInsets.all(24),
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

                      final docIds = docs
                          .map((d) => d['id'] as String)
                          .toList();
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
                              child: Text(
                                d['name']?.toString() ?? d['id'] as String,
                              ),
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
                        : DateFormat(
                            'EEE, d MMM',
                            l10n.localeName,
                          ).format(_oneOffDate!),
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
                controller: _subject,
                decoration: InputDecoration(
                  labelText: l10n.subject,
                  hintText: 'Например: Математика',
                  border: const OutlineInputBorder(),
                ),
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
                              : DateFormat(
                                  'd MMM',
                                  l10n.localeName,
                                ).format(_effectiveFrom!),
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
                              : DateFormat(
                                  'd MMM',
                                  l10n.localeName,
                                ).format(_effectiveTo!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _effectiveTo ??
                                DateTime.now().add(const Duration(days: 30)),
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
                  Text(
                    l10n.colorOverride,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          subject: _subject.text.trim().isEmpty ? null : _subject.text.trim(),
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
          'subject': _subject.text.trim(),
          'room': _room.text.trim(),
          'oneOffDate': _recurring
              ? null
              : (_oneOffDate == null ? null : fmt.format(_oneOffDate!)),
          'effectiveFrom': _recurring && _effectiveFrom != null
              ? fmt.format(_effectiveFrom!)
              : null,
          'effectiveTo': _recurring && _effectiveTo != null
              ? fmt.format(_effectiveTo!)
              : null,
          'color': _colorOverride,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.savedSchedule)));
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
      if (mounted) Navigator.of(context).pop();
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
