import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/widgets/file_preview.dart';
import 'package:school_world/src/screens/settings_screen.dart';
import 'package:school_world/src/models/schedule.dart';

class TeacherToday extends StatefulWidget {
  const TeacherToday({
    super.key,
    required this.classes,
    required this.selectedClassId,
    required this.onTabSelect,
    required this.onSelectClass,
    required this.onDeleteClass,
    required this.onCopyGuestLink,
    required this.onCreateClass,
    required this.onProfileTap,
    this.showSidebar = false,
  });

  final List<Map<String, dynamic>> classes;
  final String selectedClassId;
  final ValueChanged<int> onTabSelect;
  final ValueChanged<String> onSelectClass;
  final void Function(String classId, String className) onDeleteClass;
  final void Function(String classId, String inviteCode) onCopyGuestLink;
  final VoidCallback onCreateClass;
  final VoidCallback onProfileTap;
  final bool showSidebar;

  @override
  State<TeacherToday> createState() => _TeacherTodayState();
}

class _TeacherTodayState extends State<TeacherToday> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _userStream = repo.userDocStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final user = repo.auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat(
      'EEEE, MMMM d',
      l10n.localeName,
    ).format(DateTime.now());

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, profileSnap) {
        final profile = profileSnap.data?.data() ?? const <String, dynamic>{};
        final name = (profile['name']?.toString().trim().isNotEmpty ?? false)
            ? profile['name'].toString().trim()
            : (user?.displayName ?? 'Учитель');
        final avatarUrl = profile['avatarUrl']?.toString();
        final firstName = name.split(RegExp(r'\s+')).first;

        final now = DateTime.now();
        final hour = now.hour;
        final greeting = hour < 12
            ? l10n.goodMorning
            : hour < 18
            ? l10n.goodAfternoon
            : l10n.goodEvening;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          color: SchoolColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$greeting, $firstName 👋',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
                SchoolAvatar(
                  name: name,
                  avatarUrl: avatarUrl,
                  radius: 23,
                  onTap: widget.onProfileTap,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _TeacherKpiRow(repo: repo, classes: widget.classes),
            const SizedBox(height: 24),
            SectionHeader(
              title: l10n.todaysClasses.toUpperCase(),
              action: l10n.viewAll,
              onActionTap: () => widget.onTabSelect(8),
            ),
            const SizedBox(height: 12),
            _TeacherTodaySchedule(
              repo: repo,
              now: now,
              classes: widget.classes,
              onSelectClass: widget.onSelectClass,
              onCopyGuestLink: widget.onCopyGuestLink,
              onDeleteClass: widget.onDeleteClass,
              onOpenSchedule: () => widget.onTabSelect(8),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'БЫСТРЫЕ ССЫЛКИ',
              action: "",
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                QuickTile(
                  onTap: () => widget.onTabSelect(5),
                  icon: Icons.library_books_outlined,
                  label: 'Библиотека',
                  color: SchoolColors.primary,
                ),
                QuickTile(
                  onTap: () => widget.onTabSelect(6),
                  icon: Icons.ondemand_video_outlined,
                  label: 'Вебинары',
                  color: SchoolColors.accent,
                ),
                // Journal is at index 7. For regular teachers it's in nav bar, but we can put it here as well.
                QuickTile(
                  onTap: () => widget.onTabSelect(7),
                  icon: Icons.book_outlined,
                  label: 'Журнал',
                  color: SchoolColors.green,
                ),
                QuickTile(
                  onTap: () => widget.onTabSelect(9),
                  icon: Icons.people_outline,
                  label: 'Участники',
                  color: SchoolColors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: l10n.needsReviewToday.toUpperCase(),
              action: "",
            ),
            const SizedBox(height: 12),
            const _NeedsAttentionCard(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _TeacherKpiRow extends StatefulWidget {
  const _TeacherKpiRow({required this.repo, required this.classes});
  final SchoolRepository repo;
  final List<Map<String, dynamic>> classes;

  @override
  State<_TeacherKpiRow> createState() => _TeacherKpiRowState();
}

class _TeacherKpiRowState extends State<_TeacherKpiRow> {
  Stream<QuerySnapshot>? _submissionsStream;
  Future<QuerySnapshot>? _gradedFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _submissionsStream = widget.repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'submitted')
          .snapshots();
      _gradedFuture = widget.repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'graded')
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentCount = widget.classes.fold<int>(
      0,
      (acc, c) => acc + ((c['studentIds'] as List?)?.length ?? 0),
    );
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _submissionsStream,
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return _KpiCard(
                  label: l10n.ungraded.toUpperCase(),
                  value: count.toString(),
                  delta: "+$count ${l10n.today.toLowerCase()}",
                  color: SchoolColors.red,
                  icon: Icons.assignment_turned_in_outlined,
                );
              },
            ),
            _KpiCard(
              label: l10n.totalStudents.toUpperCase(),
              value: studentCount.toString(),
              delta: l10n.studentsCount(studentCount),
              color: SchoolColors.primary,
              icon: Icons.people_outline_rounded,
            ),
            _KpiCard(
              label: l10n.chooseYourClasses.split(' ')[1].toUpperCase(),
              value: widget.classes.length.toString(),
              delta:
                  "${widget.classes.length} ${l10n.chooseYourClasses.split(' ')[1].toLowerCase()}",
              color: SchoolColors.green,
              icon: Icons.school_outlined,
            ),
            FutureBuilder<QuerySnapshot>(
              future: _gradedFuture,
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                double avg = 0;
                if (docs.isNotEmpty) {
                  final sum = docs.fold<double>(0, (acc, d) {
                    final g = d.data() as Map<String, dynamic>;
                    return acc +
                        (double.tryParse(g['grade']?.toString() ?? '0') ?? 0);
                  });
                  avg = sum / docs.length;
                }
                return _KpiCard(
                  label: l10n.avgGrade.toUpperCase(),
                  value: avg == 0 ? "—" : avg.toStringAsFixed(1),
                  delta: docs.isEmpty
                      ? l10n.noGradesYet
                      : "${docs.length} ${l10n.grade.toLowerCase()}",
                  color: SchoolColors.yellow,
                  icon: Icons.star_outline_rounded,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
    required this.icon,
  });
  final String label, value, delta;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SchoolCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: isDark ? 0.15 : 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: isDark ? 0.2 : 0.15),
                      color.withValues(alpha: isDark ? 0.08 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsAttentionCard extends StatefulWidget {
  const _NeedsAttentionCard({super.key});

  @override
  State<_NeedsAttentionCard> createState() => _NeedsAttentionCardState();
}

class _NeedsAttentionCardState extends State<_NeedsAttentionCard> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _attentionStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _attentionStream = repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'submitted')
          .limit(3)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _attentionStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty &&
            snapshot.connectionState != ConnectionState.waiting) {
          return SchoolCard(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.done_all_rounded,
                    color: SchoolColors.green,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.allChecked,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SchoolColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SchoolCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < docs.length; i++) ...[
                _AttentionSubmissionRow(
                  doc: docs[i],
                  isLast: i == docs.length - 1,
                ),
                if (i < docs.length - 1) const Divider(height: 1, indent: 64),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AttentionSubmissionRow extends StatelessWidget {
  const _AttentionSubmissionRow({required this.doc, required this.isLast});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isLast;

  void _reviewSubmission(
    BuildContext context,
    SchoolRepository repo,
    String studentName,
  ) async {
    final data = doc.data();
    final gradeCtrl = TextEditingController(
      text: data['grade']?.toString() ?? '',
    );
    final feedbackCtrl = TextEditingController(
      text: data['feedback']?.toString() ?? '',
    );
    final attachments = List<Map<String, dynamic>>.from(
      data['attachments'] ?? [],
    );
    bool saving = false;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Проверка работы: $studentName'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if ((data['content']?.toString() ?? '').isNotEmpty) ...[
                    const Text(
                      'Ответ ученика:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        data['content'].toString(),
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (attachments.isNotEmpty) ...[
                    const Text(
                      'Прикрепленные файлы:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...attachments.map(
                      (file) => FilePreviewWidget(remoteFile: file),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gradeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Оценка (в % или баллах)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feedbackCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Отзыв учителя',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final gradeVal = double.tryParse(gradeCtrl.text.trim());
                      if (gradeVal == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Пожалуйста, введите корректную оценку (число)',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await repo.gradeSubmission(
                          submissionId: doc.id,
                          grade: gradeVal,
                          feedback: feedbackCtrl.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка сохранения: $e')),
                          );
                        }
                      } finally {
                        setState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Поставить оценку'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final repo = AppScope.of(context).repository;
    final studentId = data['studentId']?.toString() ?? '';
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, dynamic>?>(
      future: repo.getUserData(studentId),
      builder: (context, userSnap) {
        final name = userSnap.data?['name']?.toString() ?? l10n.student;
        final title = data['assignmentTitle'] ?? l10n.assignment;

        return _AttentionRow(
          icon: Icons.assignment_outlined,
          color: SchoolColors.red,
          title: l10n.work,
          subtitle: "$name · $title",
          onTap: () => _reviewSubmission(context, repo, name),
          isLast: isLast,
        );
      },
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Уведомление: $title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SchoolColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: SchoolColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherTodaySchedule extends StatefulWidget {
  const _TeacherTodaySchedule({
    required this.repo,
    required this.now,
    required this.classes,
    required this.onSelectClass,
    required this.onCopyGuestLink,
    required this.onDeleteClass,
    required this.onOpenSchedule,
  });
  final SchoolRepository repo;
  final DateTime now;
  final List<Map<String, dynamic>> classes;
  final ValueChanged<String> onSelectClass;
  final void Function(String, String) onCopyGuestLink;
  final void Function(String, String) onDeleteClass;
  final VoidCallback onOpenSchedule;

  @override
  State<_TeacherTodaySchedule> createState() => _TeacherTodayScheduleState();
}

class _TeacherTodayScheduleState extends State<_TeacherTodaySchedule> {
  Stream<List<ScheduleEntry>>? _schedulesStream;
  Stream<List<ScheduleOverride>>? _overridesStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final uid = widget.repo.uid ?? '';
      _schedulesStream = widget.repo.teacherSchedulesStream(uid);
      _overridesStream = widget.repo.teacherScheduleOverridesStream(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScheduleEntry>>(
      stream: _schedulesStream,
      builder: (context, schedSnap) {
        return StreamBuilder<List<ScheduleOverride>>(
          stream: _overridesStream,
          builder: (context, ovSnap) {
            final schedules = schedSnap.data ?? [];
            final overrides = ovSnap.data ?? [];
            final todayItems = resolveDay(
              date: widget.now,
              schedules: schedules,
              overrides: overrides,
            );

            if (todayItems.isEmpty) {
              return _NoClassesEmptyState(
                onOpenSchedule: widget.onOpenSchedule,
              );
            }

            return Column(
              children: [
                for (final it in todayItems) ...[
                  _buildClassItem(context, it),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildClassItem(BuildContext context, ResolvedScheduleItem it) {
    final clsData = widget.classes.firstWhere(
      (c) => c['id'] == it.classId,
      orElse: () => <String, dynamic>{},
    );
    final clsName = clsData['name']?.toString() ?? it.classId;
    final clsSubject = clsData['subject']?.toString() ?? '—';
    final studentCount = (clsData['studentIds'] as List?)?.length ?? 0;

    final nowMin = widget.now.hour * 60 + widget.now.minute;
    final isLive = nowMin >= it.startMinute && nowMin < it.endMinute;
    final isDone = nowMin >= it.endMinute;

    return TeacherTodayClassRow(
      name: clsName,
      subject: clsSubject,
      timeLabel: '${_fmt(it.startMinute)} – ${_fmt(it.endMinute)}',
      roomLabel: it.room,
      color: colorFromHex(it.color, SchoolColors.primary),
      isLive: isLive,
      isDone: isDone,
      isCancelled: it.cancelled,
      students: studentCount,
      onTap: () => widget.onSelectClass(it.classId),
      onAction: () => widget.onSelectClass(it.classId), // Navigation for now
      repo: widget.repo,
      classId: it.classId,
    );
  }

  String _fmt(int min) {
    final h = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class TeacherTodayClassRow extends StatefulWidget {
  const TeacherTodayClassRow({
    super.key,
    required this.name,
    required this.subject,
    required this.timeLabel,
    required this.roomLabel,
    required this.color,
    required this.isLive,
    required this.isDone,
    required this.isCancelled,
    required this.students,
    required this.onTap,
    required this.onAction,
    required this.repo,
    required this.classId,
  });

  final String name, subject, timeLabel;
  final String? roomLabel;
  final Color color;
  final bool isLive, isDone, isCancelled;
  final int students;
  final VoidCallback onTap, onAction;
  final SchoolRepository repo;
  final String classId;

  @override
  State<TeacherTodayClassRow> createState() => _TeacherTodayClassRowState();
}

class _TeacherTodayClassRowState extends State<TeacherTodayClassRow> {
  Stream<QuerySnapshot>? _submissionsStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _submissionsStream = widget.repo.firestore
          .collection('submissions')
          .where('classId', isEqualTo: widget.classId)
          .where('status', isEqualTo: 'submitted')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SchoolCard(
      padding: EdgeInsets.zero,
      onTap: widget.onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (widget.isLive)
              Container(
                width: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClassBadge(
                      name: widget.name,
                      color: widget.color,
                      size: 44,
                      radius: 11,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.timeLabel} · ${l10n.studentsCount(widget.students)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SchoolColors.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: SchoolColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _submissionsStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: SchoolColors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count ${l10n.ungraded.toUpperCase()}',
                            style: const TextStyle(
                              color: SchoolColors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.isLive)
                      SizedBox(
                        height: 36,
                        child: FilledButton(
                          onPressed: widget.onAction,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            l10n.signIn,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: widget.onAction,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            l10n.previewClassAction.split(' ')[0],
                            style: const TextStyle(fontSize: 13),
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
    );
  }
}

class _NoClassesEmptyState extends StatelessWidget {
  const _NoClassesEmptyState({required this.onOpenSchedule});
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SchoolCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: SchoolColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noClassesScheduled,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: SchoolColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onOpenSchedule,
            child: Text(l10n.openWeeklySchedule),
          ),
        ],
      ),
    );
  }
}
