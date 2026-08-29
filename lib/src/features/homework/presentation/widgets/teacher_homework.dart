import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/widgets/file_preview.dart';
import '../../domain/submission_filter.dart';
import 'package:school_world/src/firebase/school_repository_assignments.dart';

class TeacherAssignments extends ConsumerStatefulWidget {
  const TeacherAssignments({super.key, required this.classId, this.className});
  final String classId;
  final String? className;

  @override
  ConsumerState<TeacherAssignments> createState() => _TeacherAssignmentsState();
}

class _TeacherAssignmentsState extends ConsumerState<TeacherAssignments> {
  String? _selectedId;
  SubmissionFilter _submissionFilter = SubmissionFilter.all;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _assignmentsStream;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedAssignments = [];
  String? _activeClassId;
  int _limit = 20;

  void _updateStreamIfNeeded(String effectiveClassId) {
    if (_activeClassId != effectiveClassId) {
      _activeClassId = effectiveClassId;
      _limit = 20;
      _cachedAssignments.clear();
      final repo = AppScope.of(context).repository;
      if (effectiveClassId == 'all') {
        _assignmentsStream = repo.firestore
            .collection('assignments')
            .orderBy('createdAt', descending: true)
            .limit(_limit)
            .snapshots();
      } else {
        _assignmentsStream = repo.assignmentsForClass(
          effectiveClassId,
          limit: _limit,
        );
      }
    }
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
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.title,
                  ),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.description,
                  ),
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
        content: Text(AppLocalizations.of(context)!.allSubmittedWorkForThis),
        actions: [
          SchoolButton.ghost(
            label: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
          ),
          SchoolButton.destructive(
            label: AppLocalizations.of(context)!.delete,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (!context.mounted) return;
      final repo = AppScope.of(context).repository;
      await repo.deleteAssignment(doc.id);
      setState(() => _selectedId = null); // Go back to list
    }
  }

  @override
  void didUpdateWidget(covariant TeacherAssignments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      setState(() {
        _limit = 20;
        _cachedAssignments.clear();
        _activeClassId = null;
        _selectedId = null;
      });
    }
  }

  void _loadMore(int currentCount) {
    if (currentCount < _limit || _activeClassId == null) return;
    setState(() {
      _limit += 20;
      final repo = AppScope.of(context).repository;
      if (_activeClassId == 'all') {
        _assignmentsStream = repo.firestore
            .collection('assignments')
            .orderBy('createdAt', descending: true)
            .limit(_limit)
            .snapshots();
      } else {
        _assignmentsStream = repo.assignmentsForClass(
          _activeClassId!,
          limit: _limit,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final selectedId = ref.watch(
      schoolAppStateProvider.select((s) => s.selectedClassId),
    );
    final effectiveClassId = (selectedId != null && selectedId.isNotEmpty)
        ? selectedId
        : widget.classId;
    _updateStreamIfNeeded(effectiveClassId);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (_selectedId == null &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMore(_cachedAssignments.length);
        }
        return false;
      },
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _assignmentsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _cachedAssignments = snapshot.data!.docs;
          }
          final docs = snapshot.hasData
              ? snapshot.data!.docs
              : _cachedAssignments;
          final isInitialLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              _cachedAssignments.isEmpty;

          if (isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (docs.isEmpty) {
            return _NoAssignmentsState(
              classId: effectiveClassId,
              onCreate: () => _createAssignment(context, effectiveClassId),
            );
          }

          if (_selectedId == null) {
            return _AssignmentSummaryView(
              classId: effectiveClassId,
              docs: docs,
              onSelect: (id) => setState(() => _selectedId = id),
              onCreate: () => _createAssignment(context, effectiveClassId),
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
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 32,
                    isMobile ? 16 : 24,
                    isMobile ? 16 : 32,
                    40,
                  ),
                  children: [
                    _HomeworkHeader(doc: selectedDoc),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: AppLocalizations.of(context)!.completedWorks,
                      action:
                          '${AppLocalizations.of(context)!.filter}: ${_submissionFilterLabel(context)}',
                      onActionTap: () => _showSubmissionFilter(context),
                    ),
                    const SizedBox(height: 12),
                    _SubmissionsList(
                      doc: selectedDoc,
                      filter: _submissionFilter,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _submissionFilterLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_submissionFilter) {
      case SubmissionFilter.all:
        return l10n.all;
      case SubmissionFilter.needsReview:
        return l10n.underCheck;
      case SubmissionFilter.graded:
        return l10n.rated1;
    }
  }

  Future<void> _showSubmissionFilter(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<SubmissionFilter>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.filter,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final filter in SubmissionFilter.values)
                RadioListTile<SubmissionFilter>(
                  value: filter,
                  groupValue: _submissionFilter,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_submissionFilterOptionLabel(l10n, filter)),
                  onChanged: (value) {
                    if (value != null) Navigator.pop(sheetContext, value);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _submissionFilter = selected);
    }
  }

  String _submissionFilterOptionLabel(
    AppLocalizations l10n,
    SubmissionFilter filter,
  ) {
    switch (filter) {
      case SubmissionFilter.all:
        return l10n.all;
      case SubmissionFilter.needsReview:
        return l10n.underCheck;
      case SubmissionFilter.graded:
        return l10n.rated1;
    }
  }

  void _createAssignment(BuildContext context, [String? targetClassId]) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).repository;
    final activeClassId = targetClassId ?? widget.classId;
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
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.title,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.description,
                    ),
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
                              final res = await FilePicker.pickFiles(
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
                              AppLocalizations.of(
                                context,
                              )!.pleaseEnterATitleAnd,
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
                          classId: activeClassId,
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
    required this.classId,
    required this.docs,
    required this.onSelect,
    required this.onCreate,
  });
  final String classId;
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
    final isCompact = MediaQuery.sizeOf(context).width < 600;
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
        Consumer(
          builder: (context, ref, _) {
            final allClassAsync = ref.watch(teacherClassesStreamProvider);
            final allVisibleClasses = allClassAsync.value ?? [];
            final effectiveClassId =
                ref.watch(
                  schoolAppStateProvider.select((s) => s.selectedClassId),
                ) ??
                widget.classId;
            final currentClassName = allVisibleClasses
                .firstWhere(
                  (c) => c['id'] == effectiveClassId,
                  orElse: () => {},
                )['name']
                ?.toString();

            return PageHeader(
              title: AppLocalizations.of(context)!.quests,
              subtitle: AppLocalizations.of(
                context,
              )!.totalAssignmentsCount(widget.docs.length),
              classContext: currentClassName,
              onClassContextTap: allVisibleClasses.length > 1
                  ? () {
                      showClassSwitcher(
                        context: context,
                        classes: allVisibleClasses,
                        currentClassId: effectiveClassId,
                        onSelect: (id) {
                          ref.read(schoolAppStateProvider).selectClass(id);
                        },
                      );
                    }
                  : null,
              trailing: SchoolAddButton(
                onPressed: widget.onCreate,
                tooltip: AppLocalizations.of(context)!.createATask,
              ),
              trailingBelowTitle: isCompact,
              padding: EdgeInsets.fromLTRB(
                isCompact ? 20 : 32,
                isCompact ? 16 : 32,
                isCompact ? 20 : 32,
                0,
              ),
            );
          },
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 600 ? 2 : 1;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
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
    final title =
        data['title']?.toString() ?? AppLocalizations.of(context)!.unknownKey13;
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
                label: isOverdue
                    ? AppLocalizations.of(context)!.expired
                    : AppLocalizations.of(context)!.actively1,
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
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      height: isMobile ? 56 : 60,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32),
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
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          SizedBox(width: isMobile ? 6 : 12),
          const Icon(Icons.chevron_right, size: 14, color: SchoolColors.muted),
          SizedBox(width: isMobile ? 6 : 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isMobile ? 4 : 16),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.exportWillBeAvailableSoon,
                  ),
                ),
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
              PopupMenuItem(
                value: 'edit',
                child: Text(AppLocalizations.of(context)!.edit),
              ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final iconWidget = Container(
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
          );

          final metaWidget = Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: _classFuture,
                builder: (context, cSnap) {
                  final className =
                      cSnap.data?['name']?.toString() ??
                      AppLocalizations.of(context)!.classText;
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 2.5,
                          backgroundColor: SchoolColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            className,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SchoolColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
          );

          final detailsWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title'] ?? '',
                style: TextStyle(
                  fontSize: isMobile ? 28 : 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['description'] ?? '',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 14,
                  color: SchoolColors.muted,
                  height: 1.5,
                ),
                maxLines: isMobile ? 5 : 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.jobFiles,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...attachments.map(
                  (file) => FilePreviewWidget(remoteFile: file),
                ),
              ],
            ],
          );

          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [metaWidget, const SizedBox(height: 12), detailsWidget],
          );

          final statWidth = isMobile ? (constraints.maxWidth - 12) / 2 : 100.0;
          final statsWidget = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: statWidth,
                child: _StatBlock(
                  width: statWidth,
                  label: AppLocalizations.of(context)!.term,
                  big: dateStr,
                  sub: timeStr,
                  color: SchoolColors.red,
                ),
              ),
              SizedBox(
                width: statWidth,
                child: _StatBlock(
                  width: statWidth,
                  label: AppLocalizations.of(context)!.points,
                  big: '10',
                  sub: AppLocalizations.of(context)!.max,
                  color: SchoolColors.primary,
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _submissionsStream,
                builder: (context, snap) {
                  final total = snap.data?.docs.length ?? 0;
                  final graded =
                      snap.data?.docs
                          .where((d) => d.get('status') == 'graded')
                          .length ??
                      0;
                  return SizedBox(
                    width: statWidth,
                    child: _StatBlock(
                      width: statWidth,
                      label: AppLocalizations.of(context)!.status,
                      big: '$graded / $total',
                      sub: AppLocalizations.of(context)!.verified1,
                      color: SchoolColors.green,
                    ),
                  );
                },
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconWidget,
                    const SizedBox(width: 14),
                    Expanded(child: metaWidget),
                  ],
                ),
                const SizedBox(height: 20),
                detailsWidget,
                const SizedBox(height: 24),
                statsWidget,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconWidget,
              const SizedBox(width: 24),
              Expanded(child: titleWidget),
              const SizedBox(width: 24),
              statsWidget,
            ],
          );
        },
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
    this.width = 100,
  });
  final String label, big, sub;
  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
  const _SubmissionsList({required this.doc, required this.filter});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final SubmissionFilter filter;

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
        final submissions = (snapshot.data?.docs ?? [])
            .where((doc) => matchesSubmissionFilter(doc.data(), widget.filter))
            .toList();
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
  const _SubmissionRow({required this.doc, required this.isLast});
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
                      if (gradeVal == null ||
                          !isValidSubmissionGrade(gradeVal)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.pleaseEnterAValidRating,
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
  const _NoAssignmentsState({required this.classId, required this.onCreate});
  final String classId;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final isTeacher = AppScope.of(context).appState.isTeacher;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final appState = ref.watch(schoolAppStateProvider);
            final isTeacher = appState.isTeacher;
            final allClassAsync = ref.watch(
              isTeacher
                  ? teacherClassesStreamProvider
                  : studentClassesStreamProvider,
            );
            final allVisibleClasses = allClassAsync.value ?? [];
            final effectiveClassId = appState.selectedClassId ?? classId;
            final currentClassName = allVisibleClasses
                .firstWhere(
                  (c) => c['id'] == effectiveClassId,
                  orElse: () => {},
                )['name']
                ?.toString();

            return PageHeader(
              title: AppLocalizations.of(context)!.quests,
              subtitle: AppLocalizations.of(context)!.totalAssignmentsCount(0),
              classContext: currentClassName,
              onClassContextTap: allVisibleClasses.length > 1
                  ? () {
                      showClassSwitcher(
                        context: context,
                        classes: allVisibleClasses,
                        currentClassId: effectiveClassId,
                        onSelect: (id) {
                          ref.read(schoolAppStateProvider).selectClass(id);
                        },
                      );
                    }
                  : null,
              trailing: isTeacher && !isCompact
                  ? SchoolAddButton(
                      onPressed: onCreate,
                      tooltip: AppLocalizations.of(context)!.createATask,
                    )
                  : null,
              trailingBelowTitle: isCompact,
              padding: EdgeInsets.fromLTRB(
                isCompact ? 20 : 32,
                isCompact ? 16 : 32,
                isCompact ? 20 : 32,
                0,
              ),
            );
          },
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: SchoolColors.muted.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noTasks,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: SchoolColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.createYourFirstAssignmentFor,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: SchoolColors.muted),
                    ),
                    const SizedBox(height: 24),
                    if (isTeacher && isCompact)
                      SchoolAddButton(
                        onPressed: onCreate,
                        tooltip: AppLocalizations.of(context)!.createATask,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
