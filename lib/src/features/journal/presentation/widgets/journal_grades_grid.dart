import 'package:school_world/src/utils/responsive_utils.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

import '../../journal_providers.dart';

class JournalGradesGrid extends ConsumerStatefulWidget {
  const JournalGradesGrid({
    super.key,
    required this.classId,
    this.studentIdFilter,
  });
  final String classId;

  /// When non-null, only this student's row is shown (read-only student view).
  final String? studentIdFilter;

  @override
  ConsumerState<JournalGradesGrid> createState() => _JournalGradesGridState();
}

class _JournalGradesGridState extends ConsumerState<JournalGradesGrid> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalHeaderController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();
  int _visibleStudentsCount = 20;

  @override
  void initState() {
    super.initState();
    _verticalBodyController.addListener(() {
      if (_verticalHeaderController.hasClients &&
          _verticalBodyController.hasClients) {
        if (_verticalHeaderController.offset != _verticalBodyController.offset) {
          _verticalHeaderController.jumpTo(_verticalBodyController.offset);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant JournalGradesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _visibleStudentsCount = 20;
    }
  }

  void _loadMoreStudents() {
    setState(() {
      _visibleStudentsCount += 20;
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalHeaderController.dispose();
    _verticalBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columnsAsync = ref.watch(journalColumnsProvider(widget.classId));
    final marksAsync = widget.studentIdFilter != null
        ? ref.watch(
            journalStudentMarksProvider(
              (widget.classId, widget.studentIdFilter!),
            ),
          )
        : ref.watch(journalMarksProvider(widget.classId));

    final repo = ref.watch(repositoryProvider);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          repo.firestore.collection('classes').doc(widget.classId).snapshots(),
      builder: (context, classSnap) {
        if (!classSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final classData = classSnap.data?.data() ?? {};
        final allStudentIds = List<String>.from(classData['studentIds'] ?? []);

        final studentIds = widget.studentIdFilter != null
            ? allStudentIds.where((id) => id == widget.studentIdFilter).toList()
            : allStudentIds;

        final paginatedStudentIds = widget.studentIdFilter != null
            ? studentIds
            : studentIds.take(_visibleStudentsCount).toList();

        return columnsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Ошибка: $e')),
          data: (columns) {
            return marksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Ошибка: $e')),
              data: (marksDocs) {
                if (columns.isEmpty) {
                  return Center(
                    child: Text(
                      widget.studentIdFilter != null
                          ? AppLocalizations.of(context)!.youDontHaveRatingsYet
                          : AppLocalizations.of(context)!.theMagazineIsEmptyAdd,
                      style: const TextStyle(
                        color: SchoolColors.muted,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final marksMap = <String, Map<String, String>>{};
                for (final doc in marksDocs) {
                  final data = doc.data()!;
                  final m = data['marks'] as Map<String, dynamic>? ?? {};
                  marksMap[doc.id] = m.map((k, v) => MapEntry(k, v.toString()));
                }

                if (widget.studentIdFilter != null) {
                  return _buildStudentGradesList(
                    context,
                    columns,
                    widget.studentIdFilter!,
                    marksMap,
                  );
                }

                return _buildCustomGrid(
                  context,
                  columns,
                  paginatedStudentIds,
                  marksMap,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCustomGrid(
    BuildContext context,
    List<DocumentSnapshot<Map<String, dynamic>>> columns,
    List<String> studentIds,
    Map<String, Map<String, String>> marksMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double studentColWidth = 220.0;
    const double cellWidth = 60.0;
    const double cellHeight = 52.0;
    const double headerHeight = 72.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withOpacity(0.7)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // HEADER ROW — Gradient
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.primary.withOpacity(0.18),
                            AppColors.secondary.withOpacity(0.08),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.07),
                            AppColors.secondary.withOpacity(0.03),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: studentColWidth,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.student.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white60 : SchoolColors.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          children: columns.map((col) {
                            final data = col.data()!;
                            final date = (data['date'] as Timestamp).toDate();
                            final topic = data['topic']?.toString() ?? '';
                            final homework = data['homework']?.toString() ?? '';
                            final formattedDate =
                                '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

                            String tooltipMsg = formattedDate;
                            if (topic.isNotEmpty) {
                              tooltipMsg +=
                                  '\n${AppLocalizations.of(context)!.item}: $topic';
                            }
                            if (homework.isNotEmpty) {
                              tooltipMsg +=
                                  '\n${AppLocalizations.of(context)!.homework}: $homework';
                            }

                            return Tooltip(
                              message: tooltipMsg,
                              preferBelow: true,
                              child: SizedBox(
                                width: cellWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      date.day.toString().padLeft(2, '0'),
                                      style: AppTextStyle.mono(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ).copyWith(height: 1.1),
                                    ),
                                    Text(
                                      date.month.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : SchoolColors.muted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // BODY
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.axis == Axis.vertical &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      _loadMoreStudents();
                    }
                    return false;
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: studentColWidth,
                        child: ListView.builder(
                          controller: _verticalHeaderController,
                          physics: const ClampingScrollPhysics(),
                          itemCount: studentIds.length,
                          itemBuilder: (context, index) {
                            final isLast = index == studentIds.length - 1;
                            return RepaintBoundary(
                              child: _StudentNameCell(
                                studentId: studentIds[index],
                                height: cellHeight,
                                isDark: isDark,
                                isLast: isLast,
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalController,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: columns.length * cellWidth,
                            child: ListView.builder(
                              controller: _verticalBodyController,
                              physics: const ClampingScrollPhysics(),
                              itemCount: studentIds.length,
                              itemBuilder: (context, index) {
                                final studentId = studentIds[index];
                                final isLast = index == studentIds.length - 1;

                                return RepaintBoundary(
                                  child: Container(
                                    height: cellHeight,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: isLast
                                            ? BorderSide.none
                                            : BorderSide(
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.04,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.03,
                                                      ),
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: columns.map((col) {
                                        final colId = col.id;
                                        final mark =
                                            marksMap[studentId]?[colId] ?? '';
                                        final colData = col.data()!;
                                        final date =
                                            (colData['date'] as Timestamp)
                                                .toDate();
                                        final topic =
                                            colData['topic']?.toString() ?? '';

                                        final isTeacher = ref.watch(
                                          schoolAppStateProvider
                                              .select((s) => s.isTeacher),
                                        );
                                        return SizedBox(
                                          width: cellWidth,
                                          height: cellHeight,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 6,
                                            ),
                                            child: _MarkCell(
                                              initialValue: mark,
                                              isDark: isDark,
                                              onChanged: (val) =>
                                                  _updateMark(studentId, colId, val),
                                              enabled: isTeacher,
                                              studentId: studentId,
                                              date: date,
                                              topic: topic,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
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
    );
  }

  void _updateMark(String studentId, String columnId, String value) {
    final repo = ref.read(repositoryProvider);
    repo.updateStudentMark(
      classId: widget.classId,
      studentId: studentId,
      columnId: columnId,
      mark: value.trim(),
    );
  }

  String _monthName(BuildContext context, int month) {
    final months = [
      AppLocalizations.of(context)!.january,
      AppLocalizations.of(context)!.february,
      AppLocalizations.of(context)!.martha,
      AppLocalizations.of(context)!.april,
      AppLocalizations.of(context)!.may,
      AppLocalizations.of(context)!.june,
      AppLocalizations.of(context)!.july,
      AppLocalizations.of(context)!.august,
      AppLocalizations.of(context)!.september,
      AppLocalizations.of(context)!.october,
      AppLocalizations.of(context)!.november,
      AppLocalizations.of(context)!.december,
    ];
    return months[month - 1];
  }

  Widget _buildStudentGradesList(
    BuildContext context,
    List<DocumentSnapshot<Map<String, dynamic>>> columns,
    String studentId,
    Map<String, Map<String, String>> marksMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentMarks = marksMap[studentId] ?? {};

    // Sort columns by date descending (newest first)
    final sortedColumns = List<DocumentSnapshot<Map<String, dynamic>>>.from(columns)
      ..sort((a, b) {
        final dateA = (a.data()?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dateB = (b.data()?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: sortedColumns.length,
      itemBuilder: (context, index) {
        final col = sortedColumns[index];
        final colId = col.id;
        final data = col.data() ?? {};
        final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final topic = data['topic']?.toString() ?? '';
        final homework = data['homework']?.toString() ?? '';
        final mark = studentMarks[colId]?.toString() ?? '';

        return _buildStudentGradeCard(context, date, topic, homework, mark, isDark);
      },
    );
  }

  Widget _buildStudentGradeCard(
    BuildContext context,
    DateTime date,
    String topic,
    String homework,
    String mark,
    bool isDark,
  ) {
    final cleanMark = mark.trim();
    Color gradeColor;
    String gradeDesc = '';

    if (cleanMark == '5') {
      gradeColor = SchoolColors.green;
      gradeDesc = AppLocalizations.of(context)!.unknownKey2; // Отлично
    } else if (cleanMark == '4') {
      gradeColor = SchoolColors.primary;
      gradeDesc = AppLocalizations.of(context)!.unknownKey3; // Хорошо
    } else if (cleanMark == '3') {
      gradeColor = SchoolColors.orange;
      gradeDesc = AppLocalizations.of(context)!.unknownKey4; // Удовлетворительно
    } else if (cleanMark == '2') {
      gradeColor = SchoolColors.red;
      gradeDesc = AppLocalizations.of(context)!.unknownKey5; // Плохо
    } else if (cleanMark.toLowerCase() == AppLocalizations.of(context)!.n1.toLowerCase()) {
      gradeColor = SchoolColors.red;
      gradeDesc = AppLocalizations.of(context)!.absent; // Отсутствовал
    } else {
      gradeColor = isDark ? Colors.white38 : Colors.black26;
      gradeDesc = '';
    }

    final monthStr = _monthName(context, date.month);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? SchoolColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: context.screenPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Side: Beautiful Date Badge
            Container(
              width: 56,
              height: 60,
              decoration: BoxDecoration(
                color: SchoolColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SchoolColors.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: SchoolColors.primary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    monthStr.length > 4 ? monthStr.substring(0, 3).toUpperCase() : monthStr.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: SchoolColors.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Middle Side: Topic & Homework Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.isNotEmpty ? topic : AppLocalizations.of(context)!.noTheme,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (homework.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.home_work_rounded,
                          size: 14,
                          color: SchoolColors.orange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            homework,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : SchoolColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right Side: Beautiful Color-Coded Rating Badge with Fixed Width for perfect vertical alignment
            SizedBox(
              width: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cleanMark.isNotEmpty ? gradeColor.withValues(alpha: 0.12) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cleanMark.isNotEmpty ? gradeColor.withValues(alpha: 0.3) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cleanMark.isNotEmpty ? cleanMark : '-',
                      style: AppTextStyle.mono(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: cleanMark.isNotEmpty ? gradeColor : (isDark ? Colors.white30 : Colors.black26),
                      ),
                    ),
                  ),
                  if (gradeDesc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      gradeDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: gradeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentNameCell extends ConsumerWidget {
  const _StudentNameCell({
    required this.studentId,
    required this.height,
    required this.isDark,
    required this.isLast,
  });
  final String studentId;
  final double height;
  final bool isDark, isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider(studentId));

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                ),
        ),
      ),
      child: userAsync.when(
        data: (user) {
          final name = user?['name']?.toString() ?? '...';
          return Row(
            children: [
              SchoolAvatar(
                userId: studentId,
                name: name,
                radius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => const Icon(Icons.error_outline, size: 16),
      ),
    );
  }
}

class _MarkCell extends ConsumerWidget {
  const _MarkCell({
    super.key,
    required this.initialValue,
    required this.isDark,
    required this.onChanged,
    required this.enabled,
    required this.studentId,
    required this.date,
    required this.topic,
  });

  final String initialValue;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String studentId;
  final DateTime date;
  final String topic;

  Color _getMarkColor(BuildContext context, String mark) {
    if (mark == '5') return SchoolColors.green;
    if (mark == '4') return SchoolColors.primary;
    if (mark == '3') return SchoolColors.orange;
    if (mark == '2') return SchoolColors.red;
    if (mark.toLowerCase() == AppLocalizations.of(context)!.n1.toLowerCase()) {
      return SchoolColors.red;
    }
    return isDark ? Colors.white : Colors.black87;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mark = initialValue.trim();
    final color = _getMarkColor(context, mark);
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    final userAsync = ref.watch(userDataProvider(studentId));
    final studentName = userAsync.value?['name']?.toString() ?? '...';

    String tooltipMsg = '$studentName\n$formattedDate';
    if (topic.isNotEmpty) {
      tooltipMsg += '\n${AppLocalizations.of(context)!.item}: $topic';
    }
    if (mark.isNotEmpty) {
      String markDesc = '';
      if (mark == '5') {
        markDesc = AppLocalizations.of(context)!.unknownKey2;
      } else if (mark == '4') {
        markDesc = AppLocalizations.of(context)!.unknownKey3;
      } else if (mark == '3') {
        markDesc = AppLocalizations.of(context)!.unknownKey4;
      } else if (mark == '2') {
        markDesc = AppLocalizations.of(context)!.unknownKey5;
      } else if (mark.toLowerCase() ==
          AppLocalizations.of(context)!.n1.toLowerCase()) {
        markDesc = AppLocalizations.of(context)!.absent;
      }

      tooltipMsg +=
          '\n${AppLocalizations.of(context)!.ratings}: $mark ${markDesc.isNotEmpty ? "($markDesc)" : ""}';
    }


    final cellWidget = Tooltip(
      message: tooltipMsg,
      preferBelow: false,
      child: Container(
        decoration: BoxDecoration(
          color: mark.isNotEmpty
              ? color.withOpacity(isDark ? 0.18 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: mark.isNotEmpty
                ? color.withOpacity(isDark ? 0.4 : 0.25)
                : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06)),
            width: 1.2,
          ),
          boxShadow: mark.isNotEmpty
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 10,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          mark,
          style: AppTextStyle.mono(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: color,
          ),
        ),
      ),
    );

    if (!enabled) {
      return cellWidget;
    }

    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context)!.rate,
      onSelected: (val) {
        onChanged(val == 'clear' ? '' : val);
      },
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: SchoolColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 14,
                    color: isDark ? Colors.white54 : SchoolColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$formattedDate: ${topic.isNotEmpty ? topic : AppLocalizations.of(context)!.noTheme}",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : SchoolColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1),
            ],
          ),
        ),
        _buildPopupItem(
          context,
          '5',
          '5',
          AppLocalizations.of(context)!.unknownKey2,
          SchoolColors.green,
        ),
        _buildPopupItem(
          context,
          '4',
          '4',
          AppLocalizations.of(context)!.unknownKey3,
          SchoolColors.primary,
        ),
        _buildPopupItem(
          context,
          '3',
          '3',
          AppLocalizations.of(context)!.unknownKey4,
          SchoolColors.orange,
        ),
        _buildPopupItem(
          context,
          '2',
          '2',
          AppLocalizations.of(context)!.unknownKey5,
          SchoolColors.red,
        ),
        _buildPopupItem(
          context,
          AppLocalizations.of(context)!.n1,
          AppLocalizations.of(context)!.n1,
          AppLocalizations.of(context)!.absent,
          SchoolColors.red,
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: isDark ? Colors.white54 : SchoolColors.muted,
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.clearMark,
                style: TextStyle(
                  color: isDark ? Colors.white70 : SchoolColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
      child: cellWidget,
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    BuildContext context,
    String value,
    String displayMark,
    String description,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(
              displayMark,
              style: AppTextStyle.mono(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
