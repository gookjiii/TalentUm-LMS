import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/providers/app_providers.dart';

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
  final Map<String, Map<String, dynamic>> _usersCache = {};
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalHeaderController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();

  @override
  void initState() {
    super.initState();
    _verticalBodyController.addListener(() {
      if (_verticalHeaderController.hasClients && _verticalBodyController.hasClients) {
        if (_verticalHeaderController.offset != _verticalBodyController.offset) {
          _verticalHeaderController.jumpTo(_verticalBodyController.offset);
        }
      }
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalHeaderController.dispose();
    _verticalBodyController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentNames(List<String> studentIds) async {
    final repo = ref.read(repositoryProvider);
    bool changed = false;
    for (final id in studentIds) {
      if (!_usersCache.containsKey(id)) {
        final data = await repo.getUserData(id);
        if (data != null) {
          _usersCache[id] = data;
          changed = true;
        }
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final columnsAsync = ref.watch(journalColumnsProvider(widget.classId));

    // Use a targeted single-doc read for students to satisfy Firestore rules.
    // For teachers, use the full collection query.
    final marksAsync = widget.studentIdFilter != null
        ? ref.watch(
            journalStudentMarksProvider(
              (widget.classId, widget.studentIdFilter!),
            ),
          )
        : ref.watch(journalMarksProvider(widget.classId));

    final repo = ref.watch(repositoryProvider);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.firestore.collection('classes').doc(widget.classId).snapshots(),
      builder: (context, classSnap) {
        if (!classSnap.hasData) return const Center(child: CircularProgressIndicator());

        final classData = classSnap.data?.data() ?? {};
        final allStudentIds = List<String>.from(classData['studentIds'] ?? []);

        // In student-filtered mode, show only the current student's row.
        final studentIds = widget.studentIdFilter != null
            ? allStudentIds.where((id) => id == widget.studentIdFilter).toList()
            : allStudentIds;

        _fetchStudentNames(studentIds);

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
                          ? 'У вас пока нет оценок.'
                          : 'Журнал пуст. Добавьте первый урок!',
                      style: const TextStyle(color: SchoolColors.muted, fontSize: 16),
                    ),
                  );
                }

                final marksMap = <String, Map<String, String>>{};
                for (final doc in marksDocs) {
                  final data = doc.data()!;
                  final m = data['marks'] as Map<String, dynamic>? ?? {};
                  marksMap[doc.id] = m.map((k, v) => MapEntry(k, v.toString()));
                }

                return _buildCustomGrid(context, columns, studentIds, marksMap);
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
    const double studentColWidth = 240.0;
    const double cellWidth = 64.0;
    const double cellHeight = 56.0;
    const double headerHeight = 72.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // HEADER ROW
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : SchoolColors.primary.withValues(alpha: 0.03),
                  border: Border(
                    bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  ),
                ),
                child: Row(
                  children: [
                    // Sticky Top-Left Corner
                    Container(
                      width: studentColWidth,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                      ),
                      child: Text(
                        widget.studentIdFilter != null ? 'Мои оценки' : 'Ученик',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white70 : SchoolColors.muted,
                        ),
                      ),
                    ),
                    // Scrollable Header Row
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          children: columns.map((col) {
                            final data = col.data()!;
                            final date = (data['date'] as Timestamp).toDate();
                            return SizedBox(
                              width: cellWidth,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    date.day.toString().padLeft(2, '0'),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  Text(
                                    date.month.toString().padLeft(2, '0'),
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : SchoolColors.muted, fontWeight: FontWeight.w600),
                                  ),
                                ],
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky Left Column (Students)
                    SizedBox(
                      width: studentColWidth,
                      child: ListView.builder(
                        controller: _verticalHeaderController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: studentIds.length,
                        itemBuilder: (context, index) {
                          final studentId = studentIds[index];
                          final user = _usersCache[studentId];
                          final name = user?['name']?.toString() ?? 'Загрузка...';
                          final isLast = index == studentIds.length - 1;

                          return Container(
                            height: cellHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                bottom: isLast ? BorderSide.none : BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: SchoolColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SchoolColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Scrollable Grid (Marks)
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

                              return Container(
                                height: cellHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: isLast ? BorderSide.none : BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
                                  ),
                                ),
                                child: Row(
                                  children: columns.map((col) {
                                    final colId = col.id;
                                    final mark = marksMap[studentId]?[colId] ?? '';

                                    final isTeacher = ref.watch(schoolAppStateProvider).isTeacher;
                                    return SizedBox(
                                      width: cellWidth,
                                      height: cellHeight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: _MarkCell(
                                          initialValue: mark,
                                          isDark: isDark,
                                          onChanged: (val) => _updateMark(studentId, colId, val),
                                          enabled: isTeacher,
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
}

class _MarkCell extends StatelessWidget {
  const _MarkCell({
    required this.initialValue,
    required this.isDark,
    required this.onChanged,
    required this.enabled,
  });

  final String initialValue;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final bool enabled;

  Color _getMarkColor(String mark) {
    if (mark == '5') return SchoolColors.green;
    if (mark == '4') return SchoolColors.primary;
    if (mark == '3') return SchoolColors.orange;
    if (mark == '2') return SchoolColors.red;
    if (mark.toLowerCase() == 'н') return SchoolColors.red;
    return isDark ? Colors.white : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final mark = initialValue.trim();
    final color = _getMarkColor(mark);
    
    final cellWidget = Container(
      decoration: BoxDecoration(
        color: mark.isNotEmpty 
          ? color.withValues(alpha: 0.1) 
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mark.isNotEmpty 
            ? color.withValues(alpha: 0.2) 
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        mark,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: color,
        ),
      ),
    );

    if (!enabled) {
      return cellWidget;
    }

    return PopupMenuButton<String>(
      tooltip: 'Оценить',
      onSelected: (val) {
        onChanged(val == 'clear' ? '' : val);
      },
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 180),
      itemBuilder: (context) => [
        _buildPopupItem('5', '5', 'Отлично', SchoolColors.green),
        _buildPopupItem('4', '4', 'Хорошо', SchoolColors.primary),
        _buildPopupItem('3', '3', 'Удовлетворительно', SchoolColors.orange),
        _buildPopupItem('2', '2', 'Плохо', SchoolColors.red),
        _buildPopupItem('Н', 'Н', 'Отсутствует', SchoolColors.red),
        const PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded, 
                size: 18, 
                color: isDark ? Colors.white54 : SchoolColors.muted
              ),
              const SizedBox(width: 10),
              Text(
                'Очистить отметку',
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
              style: TextStyle(
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
