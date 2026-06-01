import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/widgets/file_preview.dart';

class TeacherAssignments extends StatefulWidget {
  const TeacherAssignments({super.key, required this.classId, this.className});
  final String classId;
  final String? className;

  @override
  State<TeacherAssignments> createState() => _TeacherAssignmentsState();
}

class _TeacherAssignmentsState extends State<TeacherAssignments> {
  String? _selectedId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _assignmentsStream;
  bool _initialized = false;

  void _editAssignment(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final repo = AppScope.of(context).repository;
    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['description']);
    DateTime? dueDate = (data['dueDate'] as Timestamp?)?.toDate();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.editTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text(
                    dueDate == null
                        ? AppLocalizations.of(context)!.selectDueDate
                        : 'Срок: ${DateFormat.yMMMd('ru').format(dueDate!)}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          dueDate ??
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
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
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.unknownKey),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && dueDate != null)
                  Navigator.pop(context, true);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );

    if (result == true && dueDate != null) {
      await repo.firestore.collection('assignments').doc(doc.id).update({
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'dueDate': Timestamp.fromDate(dueDate!),
      });
    }
  }

  void _confirmDelete(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTask),
        content: Text(
          AppLocalizations.of(context)!.allSubmittedWorkForThis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.unknownKey),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: SchoolColors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (!context.mounted) return;
      final repo = AppScope.of(context).repository;
      await repo.firestore.collection('assignments').doc(doc.id).delete();
      setState(() => _selectedId = null); // Go back to list
    }
  }

  int _limit = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _assignmentsStream = repo.assignmentsForClass(widget.classId, limit: _limit);
    }
  }

  @override
  void didUpdateWidget(covariant TeacherAssignments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      final repo = AppScope.of(context).repository;
      setState(() {
        _limit = 20;
        _assignmentsStream = repo.assignmentsForClass(widget.classId, limit: _limit);
        _selectedId = null;
      });
    }
  }

  void _loadMore() {
    setState(() {
      _limit += 20;
      final repo = AppScope.of(context).repository;
      _assignmentsStream = repo.assignmentsForClass(widget.classId, limit: _limit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (_selectedId == null &&
                scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              _loadMore();
            }
            return false;
          },
          child: SizedBox.expand(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _assignmentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _NoAssignmentsState(
                    onCreate: () => _createAssignment(context),
                  );
                }
  
                if (_selectedId == null) {
                  return _AssignmentSummaryView(
                    docs: docs,
                    onSelect: (id) => setState(() => _selectedId = id),
                    onCreate: () => _createAssignment(context),
                  );
                }
  
                QueryDocumentSnapshot<Map<String, dynamic>>? selectedDoc;
                try {
                  selectedDoc = docs.firstWhere((d) => d.id == _selectedId);
                } catch (_) {
                  selectedDoc = docs.first;
                }
  
                return Column(
                  children: [
                    _HomeworkTopBar(
                      classId: widget.classId,
                      className: widget.className,
                      title: selectedDoc.data()['title'] ?? '',
                      doc: selectedDoc,
                      onBack: () => setState(() => _selectedId = null),
                      onEdit: (doc) => _editAssignment(context, doc),
                      onDelete: (doc) => _confirmDelete(context, doc),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(32, 24, 32, 40),
                        children: [
                          _HomeworkHeader(doc: selectedDoc),
                          SizedBox(height: 24),
                          SectionHeader(
                            title: AppLocalizations.of(context)!.completedWorks,
                            action: AppLocalizations.of(context)!.filter,
                          ),
                          const SizedBox(height: 12),
                          _SubmissionsList(doc: selectedDoc),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _createAssignment(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).repository;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate;
    List<PlatformFile> files = [];
    bool uploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.createATask),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      dueDate == null
                          ? AppLocalizations.of(context)!.selectDueDate
                          : 'Срок: ${DateFormat.yMMMd(l10n.localeName).format(dueDate!)}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => dueDate = picked);
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.jobFiles,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  if (files.isEmpty)
                    Text(
                      AppLocalizations.of(context)!.noAttachments,
                      style: TextStyle(
                        color: SchoolColors.muted.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    )
                  else
                    ...files.map(
                      (file) => FilePreviewWidget(
                        localFile: file,
                        onRemove: uploading
                            ? null
                            : () => setState(() => files.remove(file)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: uploading
                          ? null
                          : () async {
                              final res = await FilePicker.platform.pickFiles(
                                allowMultiple: true,
                                withData: true,
                              );
                              if (res != null) {
                                setState(() => files.addAll(res.files));
                              }
                            },
                      icon: Icon(Icons.attach_file, size: 16),
                      label: Text(AppLocalizations.of(context)!.attachFiles),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: uploading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.unknownKey),
            ),
            FilledButton(
              onPressed: uploading
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty || dueDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.pleaseEnterATitleAnd,
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => uploading = true);
                      try {
                        final List<Map<String, dynamic>> attachments = [];
                        for (final file in files) {
                          final path =
                              'assignments/temp/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                          Map<String, dynamic>? uploadResult;
                          if (file.bytes != null) {
                            uploadResult = await repo.uploadFileWeb(
                              path,
                              file.bytes!,
                            );
                          } else if (file.path != null) {
                            uploadResult = await repo.uploadFile(
                              path,
                              File(file.path!),
                            );
                          }
                          if (uploadResult != null) {
                            attachments.add({
                              'type': 'file',
                              ...uploadResult,
                              'name': file.name,
                              'size': file.size,
                            });
                          }
                        }

                        await repo.createAssignment(
                          classId: widget.classId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          dueDate: dueDate!,
                          attachments: attachments,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка создания: $e')),
                          );
                        }
                      } finally {
                        setState(() => uploading = false);
                      }
                    },
              child: uploading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.create),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentSummaryView extends StatefulWidget {
  const _AssignmentSummaryView({
    required this.docs,
    required this.onSelect,
    required this.onCreate,
  });
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;

  @override
  State<_AssignmentSummaryView> createState() => _AssignmentSummaryViewState();
}

class _AssignmentSummaryViewState extends State<_AssignmentSummaryView> {
  String _filter = 'all'; // 'all' | 'active' | 'overdue'

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = widget.docs.where((doc) {
      if (_filter == 'all') return true;
      final due = (doc.data()['dueDate'] as Timestamp?)?.toDate();
      if (due == null) return _filter == 'active';
      return _filter == 'active' ? due.isAfter(now) : due.isBefore(now);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: AppLocalizations.of(context)!.quests,
          subtitle: AppLocalizations.of(context)!
              .totalAssignmentsCount(widget.docs.length),
          trailing: FilledButton.icon(
            onPressed: widget.onCreate,
            style: FilledButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.createATask),
          ),
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: AppLocalizations.of(context)!.all,
                selected: _filter == 'all',
                onSelected: (v) => setState(() => _filter = 'all'),
              ),
              _FilterChip(
                label: AppLocalizations.of(context)!.active1,
                selected: _filter == 'active',
                onSelected: (v) => setState(() => _filter = 'active'),
              ),
              _FilterChip(
                label: AppLocalizations.of(context)!.overdue,
                selected: _filter == 'overdue',
                onSelected: (v) => setState(() => _filter = 'overdue'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 600 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 210,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _AssignmentCard(
                      doc: filtered[index],
                      onTap: () => widget.onSelect(filtered[index].id),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: SchoolColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : SchoolColors.muted,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? SchoolColors.primary : SchoolColors.border,
        ),
      ),
      showCheckmark: false,
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.doc, required this.onTap});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title']?.toString() ?? AppLocalizations.of(context)!.unknownKey13;
    final desc = data['description']?.toString() ?? '';
    final due = (data['dueDate'] as Timestamp?)?.toDate();
    final isOverdue = due != null && due.isBefore(DateTime.now());

    return SchoolCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SchoolColors.primary, SchoolColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (due != null) _DueDateBadge(due: due, isOverdue: isOverdue),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(fontSize: 13, color: SchoolColors.muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Spacer(),
          SizedBox(height: 12),
          Row(
            children: [
              StatusChip(
                label: isOverdue ? AppLocalizations.of(context)!.expired : AppLocalizations.of(context)!.actively1,
                color: isOverdue ? SchoolColors.red : SchoolColors.green,
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                color: SchoolColors.muted,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DueDateBadge extends StatelessWidget {
  const _DueDateBadge({required this.due, required this.isOverdue});
  final DateTime due;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue
            ? SchoolColors.red.withValues(alpha: 0.1)
            : SchoolColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'до ${DateFormat('d MMM', 'ru').format(due)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOverdue ? SchoolColors.red : SchoolColors.muted,
        ),
      ),
    );
  }
}

class _HomeworkTopBar extends StatelessWidget {
  const _HomeworkTopBar({
    required this.classId,
    this.className,
    required this.title,
    required this.doc,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });
  final String classId, title;
  final String? className;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onBack;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onEdit;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: SchoolColors.border)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(className ?? classId),
            style: TextButton.styleFrom(
              foregroundColor: SchoolColors.text,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, size: 14, color: SchoolColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 16),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.exportWillBeAvailableSoon)),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 20),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              if (val == 'edit') {
                onEdit(doc);
              } else if (val == 'delete') {
                onDelete(doc);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  AppLocalizations.of(context)!.deleteTask1,
                  style: TextStyle(color: SchoolColors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editAssignment(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final repo = AppScope.of(context).repository;
    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['description']);
    DateTime? dueDate = (data['dueDate'] as Timestamp?)?.toDate();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.editTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text(
                    dueDate == null
                        ? AppLocalizations.of(context)!.selectDueDate
                        : 'Срок: ${DateFormat.yMMMd('ru').format(dueDate!)}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          dueDate ??
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
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
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.unknownKey),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && dueDate != null)
                  Navigator.pop(context, true);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );

    if (result == true && dueDate != null) {
      await repo.firestore.collection('assignments').doc(doc.id).update({
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'dueDate': Timestamp.fromDate(dueDate!),
      });
    }
  }

  void _confirmDelete(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTask),
        content: Text(
          AppLocalizations.of(context)!.allSubmittedWorkForThis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.unknownKey),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: SchoolColors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (!context.mounted) return;
      final repo = AppScope.of(context).repository;
      await repo.firestore.collection('assignments').doc(doc.id).delete();
      onBack(); // Go back to list
    }
  }
}

class _HomeworkHeader extends StatefulWidget {
  const _HomeworkHeader({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  State<_HomeworkHeader> createState() => _HomeworkHeaderState();
}

class _HomeworkHeaderState extends State<_HomeworkHeader> {
  Stream<QuerySnapshot>? _submissionsStream;
  Future<Map<String, dynamic>?>? _classFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _submissionsStream = repo.firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: widget.doc.id)
          .snapshots();
      _classFuture = repo.getClassData(
        widget.doc.data()['classId']?.toString() ?? '',
      );
    }
  }

  @override
  void didUpdateWidget(covariant _HomeworkHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.id != widget.doc.id) {
      final repo = AppScope.of(context).repository;
      _submissionsStream = repo.firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: widget.doc.id)
          .snapshots();
      _classFuture = repo.getClassData(
        widget.doc.data()['classId']?.toString() ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final dueDate = data['dueDate'] as Timestamp?;
    final dateStr = dueDate != null
        ? DateFormat('d MMM', 'ru').format(dueDate.toDate())
        : '—';
    final timeStr = dueDate != null
        ? DateFormat('HH:mm').format(dueDate.toDate())
        : '';
    final attachments = List<Map<String, dynamic>>.from(
      data['attachments'] ?? [],
    );

    return SchoolCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SchoolColors.primary, SchoolColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: SchoolColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _classFuture,
                      builder: (context, cSnap) {
                        final className =
                            cSnap.data?['name']?.toString() ?? AppLocalizations.of(context)!.classText;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: SchoolColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 2.5,
                                backgroundColor: SchoolColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                className,
                                style: const TextStyle(
                                  color: SchoolColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 12),
                    Text(
                      data['createdAt'] != null
                          ? 'Опубликовано: ${DateFormat('d MMM, HH:mm', 'ru').format((data['createdAt'] as Timestamp).toDate())}'
                          : AppLocalizations.of(context)!.published,
                      style: TextStyle(
                        color: SchoolColors.muted.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: SchoolColors.muted,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachments.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.jobFiles,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ...attachments.map(
                    (file) => FilePreviewWidget(remoteFile: file),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 24),
          Row(
            children: [
              _StatBlock(
                label: AppLocalizations.of(context)!.term,
                big: dateStr,
                sub: timeStr,
                color: SchoolColors.red,
              ),
              SizedBox(width: 12),
              _StatBlock(
                label: AppLocalizations.of(context)!.points,
                big: "10",
                sub: AppLocalizations.of(context)!.max,
                color: SchoolColors.primary,
              ),
              const SizedBox(width: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _submissionsStream,
                builder: (context, snap) {
                  final total = snap.data?.docs.length ?? 0;
                  final graded =
                      snap.data?.docs
                          .where((d) => d.get('status') == 'graded')
                          .length ??
                      0;
                  return _StatBlock(
                    label: AppLocalizations.of(context)!.status,
                    big: "$graded / $total",
                    sub: AppLocalizations.of(context)!.verified1,
                    color: SchoolColors.green,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.big,
    required this.sub,
    required this.color,
  });
  final String label, big, sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            big,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: SchoolColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionsList extends StatefulWidget {
  const _SubmissionsList({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  State<_SubmissionsList> createState() => _SubmissionsListState();
}

class _SubmissionsListState extends State<_SubmissionsList> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _submissionsStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _submissionsStream = repo.firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: widget.doc.id)
          .snapshots();
    }
  }

  @override
  void didUpdateWidget(covariant _SubmissionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.id != widget.doc.id) {
      final repo = AppScope.of(context).repository;
      _submissionsStream = repo.firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: widget.doc.id)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _submissionsStream,
      builder: (context, snapshot) {
        final submissions = snapshot.data?.docs ?? [];
        if (submissions.isEmpty) {
          return SchoolCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noWorkYet,
                  style: TextStyle(color: SchoolColors.muted),
                ),
              ),
            ),
          );
        }

        return SchoolCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < submissions.length; i++) ...[
                _SubmissionRow(
                  doc: submissions[i],
                  isLast: i == submissions.length - 1,
                ),
                if (i < submissions.length - 1)
                  const Divider(height: 1, indent: 72),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SubmissionRow extends StatefulWidget {
  const _SubmissionRow({super.key, required this.doc, required this.isLast});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isLast;

  @override
  State<_SubmissionRow> createState() => _SubmissionRowState();
}

class _SubmissionRowState extends State<_SubmissionRow> {
  Future<Map<String, dynamic>?>? _userFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _userFuture = repo.getUserData(widget.doc.data()['studentId'] ?? '');
    }
  }

  void _reviewSubmission(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> subDoc,
  ) async {
    final data = subDoc.data();
    final repo = AppScope.of(context).repository;
    final l10n = AppLocalizations.of(context)!;
    final studentId = data['studentId'] ?? '';
    final studentName = await repo
        .getUserData(studentId)
        .then((m) => m?['name'] ?? l10n.student);
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
                    Text(
                      AppLocalizations.of(context)!.studentAnswer,
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
                        style: TextStyle(height: 1.4),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  if (attachments.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.attachedFiles,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...attachments.map(
                      (file) => FilePreviewWidget(remoteFile: file),
                    ),
                    SizedBox(height: 16),
                  ],
                  Divider(),
                  SizedBox(height: 12),
                  TextField(
                    controller: gradeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.scoreInOrPoints,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: feedbackCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.teachersReview,
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
              child: Text(AppLocalizations.of(context)!.unknownKey),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final gradeVal = double.tryParse(gradeCtrl.text.trim());
                      if (gradeVal == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.pleaseEnterAValidRating,
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await repo.gradeSubmission(
                          submissionId: subDoc.id,
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
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.giveARating),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final status = data['status'] ?? 'submitted';
    final score = data['grade']?.toString();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, uSnap) {
        final name = uSnap.data?['name'] ?? '...';

        return InkWell(
          onTap: () => _reviewSubmission(context, widget.doc),
          borderRadius: widget.isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(20))
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                SchoolAvatar(name: name, radius: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final submittedAt =
                              (data['submittedAt'] as Timestamp?)?.toDate();
                          final timeStr = submittedAt != null
                              ? DateFormat(
                                  'd MMM · HH:mm',
                                  'ru',
                                ).format(submittedAt)
                              : '—';
                          return Text(
                            'Сдано: $timeStr',
                            style: TextStyle(
                              fontSize: 11,
                              color: SchoolColors.muted.withValues(alpha: 0.7),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (score != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      score,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                _StatusPill(status: status),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: SchoolColors.muted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'graded') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: SchoolColors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          AppLocalizations.of(context)!.rated1,
          style: TextStyle(
            color: SchoolColors.green,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SchoolColors.yellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppLocalizations.of(context)!.underCheck,
        style: TextStyle(
          color: SchoolColors.orange,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NoAssignmentsState extends StatelessWidget {
  const _NoAssignmentsState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: SchoolColors.muted.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noTasks,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SchoolColors.muted,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createYourFirstAssignmentFor,
            style: TextStyle(color: SchoolColors.muted),
          ),
          SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.createATask),
          ),
        ],
      ),
    );
  }
}
