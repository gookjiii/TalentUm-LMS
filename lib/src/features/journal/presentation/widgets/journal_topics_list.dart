import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/theme.dart';

import '../../journal_providers.dart';
import 'package:school_world/src/providers/app_providers.dart';

class JournalTopicsList extends ConsumerWidget {
  const JournalTopicsList({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columnsAsync = ref.watch(journalColumnsProvider(classId));
    final appState = ref.watch(schoolAppStateProvider);

    return columnsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Ошибка: $e')),
      data: (columns) {
        if (columns.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noLessonsAddYourFirst,
              style: TextStyle(color: SchoolColors.muted, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          itemCount: columns.length,
          itemBuilder: (context, index) {
            final doc = columns[index];
            final data = doc.data()!;
            final date = (data['date'] as Timestamp).toDate();
            final topic = data['topic'] as String? ?? '';
            final homework = data['homework'] as String? ?? '';
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isLast = index == columns.length - 1;

            return Stack(
              children: [
                // The vertical line connecting to the next item
                if (!isLast)
                  Positioned(
                    top: 48, // height of the circle
                    bottom: 0,
                    left: 29, // Center of the 60px column
                    child: Container(
                      width: 2,
                      color: isDark
                          ? Colors.white10
                          : SchoolColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                // The main row content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline circle
                    SizedBox(
                      width: 60,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: SchoolColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SchoolColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          date.day.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: SchoolColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Content Card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? SchoolColors.darkSurface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.class_rounded,
                                    size: 18,
                                    color: SchoolColors.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _monthName(context, date.month),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: SchoolColors.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (appState.isTeacher)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                      ),
                                      color: SchoolColors.muted,
                                      onPressed: () => _editLesson(
                                        context,
                                        ref,
                                        doc.id,
                                        date,
                                        topic,
                                        homework,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  if (appState.isLeadTeacher) ...[
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        size: 18,
                                      ),
                                      color: SchoolColors.red.withValues(
                                        alpha: 0.7,
                                      ),
                                      onPressed: () =>
                                          _deleteLesson(context, ref, doc.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                topic.isNotEmpty ? topic : AppLocalizations.of(context)!.noTheme,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              if (homework.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.03)
                                        : SchoolColors.primary.withValues(
                                            alpha: 0.04,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.home_work_rounded,
                                        size: 16,
                                        color: SchoolColors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          homework,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
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

  Future<void> _editLesson(
    BuildContext context,
    WidgetRef ref,
    String columnId,
    DateTime initialDate,
    String initialTopic,
    String initialHomework,
  ) async {
    final dateController = TextEditingController(
      text: _formatDate(initialDate),
    );
    final topicController = TextEditingController(text: initialTopic);
    final homeworkController = TextEditingController(text: initialHomework);
    DateTime selectedDate = initialDate;

    final repo = ref.read(repositoryProvider);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.editLesson),
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
        await repo.updateJournalColumn(
          classId: classId,
          columnId: columnId,
          date: selectedDate,
          topic: topicController.text,
          homework: homeworkController.text,
        );
      } catch (e) {
        debugPrint('Error updating lesson: $e');
      }
    }
  }

  Future<void> _deleteLesson(
    BuildContext context,
    WidgetRef ref,
    String columnId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteLesson),
        content: Text(AppLocalizations.of(context)!.thisActionCannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.unknownKey),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: SchoolColors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref
            .read(repositoryProvider)
            .deleteJournalColumn(classId: classId, columnId: columnId);
      } catch (e) {
        debugPrint('Error deleting lesson: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
