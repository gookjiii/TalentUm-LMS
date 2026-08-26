import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/widgets/shimmer_widgets.dart';
import '../../../../screens/homework_detail_screen.dart';
import '../../../../firebase/safe_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:collection/collection.dart';

class StudentHomework extends ConsumerStatefulWidget {
  const StudentHomework({super.key, required this.classId});
  final String classId;

  @override
  ConsumerState<StudentHomework> createState() => _StudentHomeworkState();
}

class _StudentHomeworkState extends ConsumerState<StudentHomework> {
  String _filter = 'All'; // 'All', 'Pending', 'Submitted', 'Graded'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Stream<QuerySnapshot<Map<String, dynamic>>>? _assignmentsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _submissionsStream;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedAssignments = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedSubmissions = [];
  int _limit = 20;

  String? _activeClassId;

  void _updateStreamsIfNeeded(String effectiveClassId) {
    if (_activeClassId != effectiveClassId) {
      _activeClassId = effectiveClassId;
      _limit = 20;
      _cachedAssignments.clear();
      _cachedSubmissions.clear();
      final repo = AppScope.of(context).repository;
      if (effectiveClassId.isEmpty) {
        final classesAsync = ref.read(studentClassesStreamProvider);
        final classIds =
            classesAsync.value?.map((c) => c['id'] as String).toList() ?? [];
        _assignmentsStream = repo.assignmentsForClasses(
          classIds,
          limit: _limit,
        );
      } else {
        _assignmentsStream = repo.assignmentsForClass(
          effectiveClassId,
          limit: _limit,
        );
      }
      _submissionsStream = repo.firestore
          .collection('submissions')
          .where('studentId', isEqualTo: repo.uid)
          .safeSnapshots();
    }
  }

  void _loadMore(int currentCount) {
    if (currentCount < _limit || _activeClassId == null) return;
    setState(() {
      _limit += 20;
      final repo = AppScope.of(context).repository;
      if (_activeClassId!.isEmpty) {
        final classesAsync = ref.read(studentClassesStreamProvider);
        final classIds =
            classesAsync.value?.map((c) => c['id'] as String).toList() ?? [];
        _assignmentsStream = repo.assignmentsForClasses(
          classIds,
          limit: _limit,
        );
      } else {
        _assignmentsStream = repo.assignmentsForClass(
          _activeClassId!,
          limit: _limit,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final selectedId = ref.watch(
      schoolAppStateProvider.select((s) => s.selectedClassId),
    );
    final effectiveClassId = (selectedId != null && selectedId.isNotEmpty)
        ? selectedId
        : widget.classId;
    _updateStreamsIfNeeded(effectiveClassId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: effectiveClassId.isNotEmpty
          ? repo.firestore
                .collection('classes')
                .doc(effectiveClassId)
                .snapshots()
          : const Stream.empty(),
      builder: (context, classSnap) {
        final className = classSnap.data?.data()?['name']?.toString();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _assignmentsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _cachedAssignments = snapshot.data!.docs;
            }
            final allAssignments = snapshot.hasData
                ? snapshot.data!.docs
                : _cachedAssignments;
            final isAssignmentsLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                _cachedAssignments.isEmpty;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _submissionsStream,
              builder: (context, subSnap) {
                if (subSnap.hasData) {
                  _cachedSubmissions = subSnap.data!.docs;
                }
                final submissions = subSnap.hasData
                    ? subSnap.data!.docs
                    : _cachedSubmissions;
                final isSubmissionsLoading =
                    subSnap.connectionState == ConnectionState.waiting &&
                    _cachedSubmissions.isEmpty;

                final isInitialLoading =
                    isAssignmentsLoading || isSubmissionsLoading;

                final submissionMap = {
                  for (var s in submissions) s.data()['assignmentId']: s.data(),
                };

                // Filter assignments
                var filteredAssignments = allAssignments.where((doc) {
                  final data = doc.data();
                  final title = (data['title']?.toString() ?? '').toLowerCase();
                  final description = (data['description']?.toString() ?? '')
                      .toLowerCase();
                  final matchesSearch =
                      title.contains(_searchQuery.toLowerCase()) ||
                      description.contains(_searchQuery.toLowerCase());

                  if (!matchesSearch) return false;

                  final submission = submissionMap[doc.id];
                  final grade = submission?['grade'];
                  final submitted = submission != null;

                  if (_filter == 'Pending') return !submitted;
                  if (_filter == 'Submitted') return submitted && grade == null;
                  if (_filter == 'Graded') return grade != null;
                  return true;
                }).toList();

                // Sort: Urgent first
                try {
                  filteredAssignments.sort((a, b) {
                    final aDue = toDate(a.data()['dueDate']);
                    final bDue = toDate(b.data()['dueDate']);
                    if (aDue == null) return 1;
                    if (bDue == null) return -1;
                    return aDue.compareTo(bDue);
                  });
                } catch (e) {
                  debugPrint('Error sorting assignments: $e');
                }

                // Find most urgent pending assignment for Focus Mode
                final urgentAssignment = allAssignments
                    .where((doc) => !submissionMap.containsKey(doc.id))
                    .firstOrNull;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                          _loadMore(allAssignments.length);
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: repo.studentClassesCached(),
                              builder: (context, allClassSnap) {
                                final allVisibleClasses =
                                    allClassSnap.data ?? [];
                                return PageHeader(
                                  title: AppLocalizations.of(context)!.myTasks,
                                  subtitle: AppLocalizations.of(
                                    context,
                                  )!.studyHomework,
                                  classContext: className,
                                  onClassContextTap:
                                      allVisibleClasses.length > 1
                                      ? () {
                                          showClassSwitcher(
                                            context: context,
                                            classes: allVisibleClasses,
                                            currentClassId: effectiveClassId,
                                            onSelect: (id) {
                                              ref
                                                  .read(schoolAppStateProvider)
                                                  .selectClass(id);
                                            },
                                          );
                                        }
                                      : null,
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    32,
                                    24,
                                    16,
                                  ),
                                );
                              },
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _searchController,
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(
                                        context,
                                      )!.searchForTasks,
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? SchoolColors.darkSurface
                                          : Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                  if (urgentAssignment != null &&
                                      _filter == 'All' &&
                                      _searchQuery.isEmpty) ...[
                                    const SizedBox(height: 32),
                                    SectionHeader(
                                      title: AppLocalizations.of(
                                        context,
                                      )!.focusMode,
                                    ),
                                    const SizedBox(height: 12),
                                    FocusAssignmentCard(doc: urgentAssignment),
                                  ],
                                  const SizedBox(height: 32),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        FilterChipItem(
                                          label: AppLocalizations.of(
                                            context,
                                          )!.all,
                                          active: _filter == 'All',
                                          onTap: () =>
                                              setState(() => _filter = 'All'),
                                        ),
                                        FilterChipItem(
                                          label: AppLocalizations.of(
                                            context,
                                          )!.waiting,
                                          active: _filter == 'Pending',
                                          onTap: () => setState(
                                            () => _filter = 'Pending',
                                          ),
                                        ),
                                        FilterChipItem(
                                          label: AppLocalizations.of(
                                            context,
                                          )!.delivered,
                                          active: _filter == 'Submitted',
                                          onTap: () => setState(
                                            () => _filter = 'Submitted',
                                          ),
                                        ),
                                        FilterChipItem(
                                          label: AppLocalizations.of(
                                            context,
                                          )!.rated,
                                          active: _filter == 'Graded',
                                          onTap: () => setState(
                                            () => _filter = 'Graded',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                          if (isInitialLoading)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: ShimmerHomeworkList(count: 5),
                              ),
                            )
                          else if (filteredAssignments.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: NoHomeworkEmptyState(),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              sliver: SliverList.builder(
                                itemCount: filteredAssignments.length,
                                itemBuilder: (context, index) {
                                  final doc = filteredAssignments[index];
                                  return HomeworkCard(
                                    doc: doc,
                                    submission: submissionMap[doc.id],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class NoHomeworkEmptyState extends StatelessWidget {
  const NoHomeworkEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: SchoolColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.youHaveNoTasksYet,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SchoolColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeworkCard extends StatelessWidget {
  const HomeworkCard({super.key, required this.doc, this.submission});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Map<String, dynamic>? submission;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title']?.toString() ?? 'Assignment';
    final desc = data['description']?.toString() ?? '';
    final due = toDate(data['dueDate']);
    final isOverdue = due != null && due.isBefore(DateTime.now());
    final submitted = submission != null;
    final grade = submission?['grade'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SchoolCard(
        padding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomeworkDetailScreen(
                repository: AppScope.of(context).repository,
                appState: AppScope.of(context).appState,
                assignmentId: doc.id,
              ),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    (submitted
                            ? SchoolColors.green
                            : (isOverdue
                                  ? SchoolColors.red
                                  : SchoolColors.primary))
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                submitted
                    ? Icons.task_alt_rounded
                    : (isOverdue
                          ? Icons.running_with_errors_rounded
                          : Icons.assignment_outlined),
                color: submitted
                    ? SchoolColors.green
                    : (isOverdue ? SchoolColors.red : SchoolColors.primary),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SchoolColors.muted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (due != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: isOverdue
                                  ? SchoolColors.red
                                  : SchoolColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getHumanFriendlyDate(context, due),
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue
                                    ? SchoolColors.red
                                    : SchoolColors.muted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      if (grade != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: SchoolColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$grade%',
                            style: const TextStyle(
                              color: SchoolColors.green,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else if (submitted && grade == null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: SchoolColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.delivered,
                          style: TextStyle(
                            fontSize: 12,
                            color: SchoolColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!submitted) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showQuickSubmit(context),
                            icon: const Icon(Icons.bolt_rounded, size: 18),
                            label: Text(
                              AppLocalizations.of(context)!.quickSubmit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              side: BorderSide(
                                color: SchoolColors.primary.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HomeworkDetailScreen(
                                    repository: AppScope.of(context).repository,
                                    appState: AppScope.of(context).appState,
                                    assignmentId: doc.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.viewMore,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showQuickSubmit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickSubmitBottomSheet(
        assignmentId: doc.id,
        title: doc.data()['title']?.toString() ?? 'Assignment',
      ),
    );
  }
}

class _QuickSubmitBottomSheet extends StatefulWidget {
  const _QuickSubmitBottomSheet({
    required this.assignmentId,
    required this.title,
  });
  final String assignmentId;
  final String title;

  @override
  State<_QuickSubmitBottomSheet> createState() =>
      _QuickSubmitBottomSheetState();
}

class _QuickSubmitBottomSheetState extends State<_QuickSubmitBottomSheet> {
  final _contentController = TextEditingController();
  List<PlatformFile> _files = [];
  bool _loading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null) {
      setState(() => _files = [..._files, ...result.files]);
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty && _files.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = AppScope.of(context).repository;
      final submissionId = await repo.createSubmission(
        assignmentId: widget.assignmentId,
        studentId: repo.uid ?? '',
        content: _contentController.text.trim(),
      );

      if (_files.isNotEmpty) {
        final List<Map<String, dynamic>> attachments = [];
        for (final file in _files) {
          final path =
              'submissions/$submissionId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final result = file.bytes != null
              ? await repo.uploadFileWeb(path, file.bytes!)
              : await repo.uploadFile(path, File(file.path!));

          if (result != null) {
            attachments.add({
              'type': 'file',
              ...result,
              'name': file.name,
              'size': file.size,
            });
          }
        }
        await repo.updateSubmissionAttachments(
          submissionId: submissionId,
          attachments: attachments,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.submittedSuccessfully),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SchoolColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SchoolColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SchoolColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: SchoolColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quickSubmit,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SchoolColors.primary,
                      ),
                    ),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _contentController,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.writeYourAnswerHere,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: isDark ? SchoolColors.darkBg : SchoolColors.bg,
            ),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _files.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _files[i].bytes != null
                            ? Image.memory(
                                _files[i].bytes!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_files[i].path!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _files.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickImage,
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: Text(l10n.attachPhoto),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(l10n.submit),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FocusAssignmentCard extends StatelessWidget {
  const FocusAssignmentCard({super.key, required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title']?.toString() ?? 'Assignment';
    final due = toDate(data['dueDate']);
    final l10n = AppLocalizations.of(context)!;

    return SchoolCard(
      padding: const EdgeInsets.all(20),
      color: SchoolColors.primary.withValues(alpha: 0.05),
      borderColor: SchoolColors.primary.withValues(alpha: 0.2),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeworkDetailScreen(
              repository: AppScope.of(context).repository,
              appState: AppScope.of(context).appState,
              assignmentId: doc.id,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: SchoolColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.upcomingAssignment,
                      style: const TextStyle(
                        color: SchoolColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (due != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.deadline}: ${_getHumanFriendlyDate(context, due)}',
                    style: const TextStyle(
                      color: SchoolColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: SchoolColors.primary,
          ),
        ],
      ),
    );
  }
}

class FilterChipItem extends StatelessWidget {
  const FilterChipItem({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

String _getHumanFriendlyDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final diff = date.difference(now);
  final locale = AppLocalizations.of(context)!.localeName;
  if (diff.inDays == 0) return AppLocalizations.of(context)!.today;
  if (diff.inDays == 1) return AppLocalizations.of(context)!.tomorrow;
  if (diff.inDays < 7) return DateFormat('EEEE', locale).format(date);
  return DateFormat('d MMM', locale).format(date);
}
