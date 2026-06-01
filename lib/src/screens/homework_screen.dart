import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../firebase/school_repository.dart';
import 'homework_detail_screen.dart';

class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({
    super.key,
    required this.repository,
    required this.appState,
    required this.classId,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;
  final String classId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: MediaQuery.sizeOf(context).width < 720
          ? null
          : AppBar(
              title: Text(l10n.homework),
              actions: [
                if (appState.isTeacher)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () => _createAssignment(context),
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: AppLocalizations.of(context)!.newTask,
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
      body: CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        streamFactory: () => repository.assignmentsForClass(classId),
        keys: [classId],
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                l10n.noAssignmentsYet,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final dueDate = data['dueDate'] != null
                  ? (data['dueDate'] as Timestamp).toDate()
                  : null;
              final overdue =
                  dueDate != null && dueDate.isBefore(DateTime.now());

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: .5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: overdue
                          ? Colors.red.withOpacity(.1)
                          : Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: overdue
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    data['title'] as String? ?? l10n.assignment,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: dueDate != null
                      ? Text(
                          l10n.due(_formatDate(context, dueDate)),
                          style: TextStyle(
                            fontSize: 12,
                            color: overdue ? Colors.red : Colors.grey,
                          ),
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeworkDetailScreen(
                        repository: repository,
                        appState: appState,
                        assignmentId: docs[i].id,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime d) {
    final months = [
      AppLocalizations.of(context)!.jan,
      AppLocalizations.of(context)!.feb,
      AppLocalizations.of(context)!.mar,
      AppLocalizations.of(context)!.apr,
      AppLocalizations.of(context)!.may1,
      AppLocalizations.of(context)!.jun,
      AppLocalizations.of(context)!.jul,
      AppLocalizations.of(context)!.aug,
      AppLocalizations.of(context)!.sep,
      AppLocalizations.of(context)!.oct,
      AppLocalizations.of(context)!.nov,
      AppLocalizations.of(context)!.dec,
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _createAssignment(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.newTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    dueDate != null
                        ? 'Срок: ${_formatDate(context, dueDate!)}'
                        : AppLocalizations.of(context)!.setADeadline,
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => dueDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.unknownKey),
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || dueDate == null) return;
                await repository.createAssignment(
                  classId: classId,
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  dueDate: dueDate!,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(context)!.create),
            ),
          ],
        ),
      ),
    );
  }
}
