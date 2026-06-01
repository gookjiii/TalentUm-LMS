import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';


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
          PageHeader(
            title: AppLocalizations.of(context)!.coolMagazine,
            subtitle: widget.studentId != null
                ? AppLocalizations.of(context)!.myGradesAndSubjects
                : AppLocalizations.of(context)!.academicPerformanceAndSubjects,
            trailing: ref.watch(schoolAppStateProvider).isTeacher
                ? SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () => _showAddLessonDialog(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(AppLocalizations.of(context)!.addALesson),
                      style: FilledButton.styleFrom(
                        backgroundColor: SchoolColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
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
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.ratings),
                  Tab(text: AppLocalizations.of(context)!.items),
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
              title: Text(AppLocalizations.of(context)!.addALesson),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.date,
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
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.item,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: homeworkController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.homework,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(AppLocalizations.of(context)!.unknownKey),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(AppLocalizations.of(context)!.save),
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

