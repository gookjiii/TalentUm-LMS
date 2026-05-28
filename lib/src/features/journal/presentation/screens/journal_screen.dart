import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/theme.dart';


import '../widgets/journal_grades_grid.dart';
import '../widgets/journal_topics_list.dart';
import 'package:school_world/src/providers/app_providers.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key, required this.classId, this.studentId});
  final String classId;

  /// When non-null, the journal is rendered in student read-only mode
  /// and the grades grid is filtered to this student's own row only.
  final String? studentId;

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Классный журнал',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.studentId != null
                            ? 'Мои оценки и предметы'
                            : 'Успеваемость и предметы',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : SchoolColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ref.watch(schoolAppStateProvider).isTeacher)
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () => _showAddLessonDialog(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Добавить урок'),
                      style: FilledButton.styleFrom(
                        backgroundColor: SchoolColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicatorPadding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  color: isDark ? SchoolColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                labelColor: isDark ? Colors.white : SchoolColors.darkSurface,
                unselectedLabelColor: isDark ? Colors.white54 : SchoolColors.muted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Оценки'),
                  Tab(text: 'Предметы'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                JournalGradesGrid(
                  classId: widget.classId,
                  studentIdFilter: widget.studentId,
                ),
                JournalTopicsList(classId: widget.classId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddLessonDialog(BuildContext context, WidgetRef ref) async {
    final dateController = TextEditingController(text: _formatDate(DateTime.now()));
    final topicController = TextEditingController();
    final homeworkController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final repo = ref.read(repositoryProvider);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить урок'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Дата',
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                            dateController.text = _formatDate(date);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: topicController,
                      decoration: const InputDecoration(
                        labelText: 'Предмет',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: homeworkController,
                      decoration: const InputDecoration(
                        labelText: 'Домашнее задание',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        await repo.addJournalColumn(
          classId: widget.classId,
          date: selectedDate,
          topic: topicController.text,
          homework: homeworkController.text,
        );
      } catch (e) {
        debugPrint('Error adding lesson: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

