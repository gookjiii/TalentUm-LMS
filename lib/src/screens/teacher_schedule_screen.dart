import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/providers/app_providers.dart';

import '../../main.dart';
import '../models/schedule.dart';
import '../theme.dart';

/// Google-Calendar style weekly schedule editor for teachers.
class TeacherScheduleScreen extends ConsumerStatefulWidget {
  const TeacherScheduleScreen({
    super.key,
    this.readOnly = false,
    this.studentClassIds,
  });

  final bool readOnly;
  final List<String>? studentClassIds;


  @override
  ConsumerState<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends ConsumerState<TeacherScheduleScreen> {
  /// Monday of the currently shown week (local date, midnight).
  late DateTime _weekStart;
  static const _startHour = 6;
  static const _endHour = 22;
  static const _hourHeight = 56.0;
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
    final isLeadTeacher = appState.isLeadTeacher;
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

    return Scaffold(
      backgroundColor: SchoolColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: SchoolColors.text,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              DateFormat('MMMM yyyy', l10n.localeName).format(_weekStart),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            if (isLeadTeacher) ...[
              const SizedBox(width: 16),
              classesAsync.when(
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
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: safeSelectedId,
                        hint: Text(
                          AppLocalizations.of(context)!.mySchedule,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: SchoolColors.text,
                          ),
                        ),
                        style: const TextStyle(
                          color: SchoolColors.text,
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
                                SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.mySchedule),
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
                                  Text(c['name']?.toString() ?? AppLocalizations.of(context)!.classText),
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
        actions: [
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
          IconButton(
            onPressed: () => setState(
              () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
            ),
            icon: const Icon(Icons.chevron_left, size: 28),
          ),
          IconButton(
            onPressed: () => setState(
              () => _weekStart = _weekStart.add(const Duration(days: 7)),
            ),
            icon: const Icon(Icons.chevron_right, size: 28),
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
                tooltip: AppLocalizations.of(context)!.addALesson,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
      body: CachedStreamBuilder<List<ScheduleEntry>>(
        streamFactory: () => schedulesStream,
        keys: streamKeys,
        builder: (context, scheduleSnap) {
          return CachedStreamBuilder<List<ScheduleOverride>>(
            streamFactory: () => overridesStream,
            keys: streamKeys,
            builder: (context, overrideSnap) {
              final schedules = scheduleSnap.data ?? const <ScheduleEntry>[];
              final overrides = overrideSnap.data ?? const <ScheduleOverride>[];
              return _WeekGrid(
                weekStart: _weekStart,
                startHour: _startHour,
                endHour: _endHour,
                hourHeight: _hourHeight,
                schedules: schedules,
                overrides: overrides,
                onCellTap: widget.readOnly ? (date, minute) {} : (date, minute) => showScheduleEditor(
                  context,
                  prefillDate: date,
                  prefillStartMinute: minute,
                  prefillClassId: _selectedClassId,
                ),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    required this.onCellTap,
    required this.onItemTap,
  });

  final DateTime weekStart;
  final int startHour;
  final int endHour;
  final double hourHeight;
  final List<ScheduleEntry> schedules;
  final List<ScheduleOverride> overrides;
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
              _buildTimeGutter(endHour - startHour),

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

  Widget _buildTimeGutter(int hours) {
    return Column(
      children: [
        const SizedBox(height: _headerH),
        for (int i = 0; i < hours; i++)
          SizedBox(
            width: _gutter,
            height: hourHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 0),
              child: Text(
                '${(startHour + i).toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11,
                  color: SchoolColors.muted,
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

  Widget _buildBody(int hours, double bodyH, double dayWidth) {
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
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: SchoolColors.border)),
                  ),
                ),
              );
            }),
          ),
          // Day columns + events
          Row(
            children: List.generate(7, (dayIndex) {
              final date = weekStart.add(Duration(days: dayIndex));
              final items = resolveDay(
                date: date,
                schedules: schedules,
                overrides: overrides,
              );
              return SizedBox(
                width: dayWidth,
                child: Stack(
                  children: [
                    // Vertical separator
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: SchoolColors.border),
                          ),
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
                    ...items.map((it) => _eventCard(it)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(ResolvedScheduleItem it) {
    final topMin = it.startMinute - startHour * 60;
    final top = (topMin / 60) * hourHeight;
    final height = ((it.endMinute - it.startMinute) / 60) * hourHeight;
    if (top < 0 || top > (endHour - startHour) * hourHeight) {
      return const SizedBox.shrink();
    }
    final color = colorFromHex(it.color, SchoolColors.primary);
    final sched = _schedById[it.scheduleId];
    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height.clamp(28, 9999),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: sched == null ? null : () => onItemTap(sched, it.date),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: it.cancelled ? .12 : .18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: .55)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fmt(it.startMinute)} – ${_fmt(it.endMinute)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    decoration: it.cancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (sched != null)
                  Flexible(
                    child: Text(
                      sched.room ?? sched.classId,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SchoolColors.text,
                        decoration: it.cancelled
                            ? TextDecoration.lineThrough
                            : null,
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

  static String _fmt(int min) {
    final h = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.isToday});
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wkd = DateFormat('E', l10n.localeName).format(date).toUpperCase();
    final dd = DateFormat('d', l10n.localeName).format(date);
    final color = isToday ? SchoolColors.primary : SchoolColors.text;
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
              color: isToday ? SchoolColors.primary : SchoolColors.muted,
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
                color: color,
              ),
            ),
          ),
        ],
      ),
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
    final repo = AppScope.of(context).repository;
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: SchoolColors.text,
                ),
              ),
              const SizedBox(height: 16),
              CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                streamFactory: () => repo.teacherClasses(),
                builder: (context, classSnap) {
                  if (!classSnap.hasData) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Ошибка загрузки классов: ${classSnap.error}',
                        style: const TextStyle(
                          color: SchoolColors.red,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  if (classSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final docs = classSnap.data!.docs;
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'У вас еще нет созданных классов. Создайте класс во вкладке AppLocalizations.of(context)!.unknownKey14 перед составлением расписания.',
                        style: TextStyle(
                          color: SchoolColors.muted,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final docIds = docs.map((d) => d.id).toList();
                  if (_classId == null || !docIds.contains(_classId)) {
                    _classId = docs.first.id;
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
                          value: d.id,
                          child: Text(d.data()['name']?.toString() ?? d.id),
                        ),
                    ],
                    onChanged: (v) => setState(() => _classId = v),
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
                    labelText: AppLocalizations.of(context)!.dayOfTheWeek,
                    border: OutlineInputBorder(),
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
                        ? AppLocalizations.of(context)!.selectDate
                        : DateFormat('EEE, d MMM', 'ru').format(_oneOffDate!),
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
                      label: AppLocalizations.of(context)!.start,
                      value: _start,
                      onChanged: (t) => setState(() => _start = t),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: AppLocalizations.of(context)!.end,
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
                  labelText: AppLocalizations.of(context)!.officenote,
                  border: OutlineInputBorder(),
                ),
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
                        l10n.cancel,
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
    if (_classId == null || _classId!.isEmpty) {
      _showErr(AppLocalizations.of(context)!.firstSelectAClass);
      return;
    }
    if (_toMin(_end) <= _toMin(_start)) {
      _showErr(AppLocalizations.of(context)!.theEndMustBeLater);
      return;
    }
    if (_recurring && _dayOfWeek == null) {
      _showErr(AppLocalizations.of(context)!.selectDayOfWeek);
      return;
    }
    if (!_recurring && _oneOffDate == null) {
      _showErr(AppLocalizations.of(context)!.selectDate);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = AppScope.of(context).repository;
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
                    : DateFormat('yyyy-MM-dd').format(_oneOffDate!)),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.savedSchedule)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErr('Ошибка: $e');
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
            child: Text(AppLocalizations.of(context)!.delete),
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
      _showErr('Ошибка: $e');
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
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
