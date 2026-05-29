import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import '../../../../screens/homework_detail_screen.dart';
import '../../../../firebase/safe_firestore.dart';

class StudentHomework extends StatefulWidget {
  const StudentHomework({super.key, required this.classId});
  final String classId;

  @override
  State<StudentHomework> createState() => _StudentHomeworkState();
}

class _StudentHomeworkState extends State<StudentHomework> {
  String _filter = 'All'; // 'All', 'Pending', 'Submitted', 'Graded'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Stream<QuerySnapshot<Map<String, dynamic>>>? _assignmentsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _submissionsStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initStreams();
    }
  }

  @override
  void didUpdateWidget(covariant StudentHomework oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _initStreams();
    }
  }

  void _initStreams() {
    final repo = AppScope.of(context).repository;
    setState(() {
      _assignmentsStream = repo.assignmentsForClass(widget.classId);
      _submissionsStream = repo.firestore
          .collection('submissions')
          .where('studentId', isEqualTo: repo.uid)
          .safeSnapshots();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _assignmentsStream,
      builder: (context, snapshot) {
        final allAssignments = snapshot.data?.docs ?? [];
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _submissionsStream,
          builder: (context, subSnap) {
            final submissions = subSnap.data?.docs ?? [];
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusChip(
                                  label: AppLocalizations.of(context)!.studyHomework,
                                  color: SchoolColors.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context)!.myTasks,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.searchForTasks,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? SchoolColors.darkSurface
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (urgentAssignment != null &&
                          _filter == 'All' &&
                          _searchQuery.isEmpty) ...[
                        const SizedBox(height: 32),
                        SectionHeader(title: AppLocalizations.of(context)!.focusMode),
                        const SizedBox(height: 12),
                        FocusAssignmentCard(doc: urgentAssignment),
                      ],
                      const SizedBox(height: 32),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChipItem(
                              label: AppLocalizations.of(context)!.all,
                              active: _filter == 'All',
                              onTap: () => setState(() => _filter = 'All'),
                            ),
                            FilterChipItem(
                              label: AppLocalizations.of(context)!.waiting,
                              active: _filter == 'Pending',
                              onTap: () => setState(() => _filter = 'Pending'),
                            ),
                            FilterChipItem(
                              label: AppLocalizations.of(context)!.delivered,
                              active: _filter == 'Submitted',
                              onTap: () =>
                                  setState(() => _filter = 'Submitted'),
                            ),
                            FilterChipItem(
                              label: AppLocalizations.of(context)!.rated,
                              active: _filter == 'Graded',
                              onTap: () => setState(() => _filter = 'Graded'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (loading)
                        const Center(child: CircularProgressIndicator())
                      else if (filteredAssignments.isEmpty)
                        const NoHomeworkEmptyState()
                      else
                        ...filteredAssignments.map(
                          (doc) => HomeworkCard(
                            doc: doc,
                            submission: submissionMap[doc.id],
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
  }
}

class FocusAssignmentCard extends StatelessWidget {
  const FocusAssignmentCard({super.key, required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title']?.toString() ?? AppLocalizations.of(context)!.unknownKey13;
    final due = toDate(data['dueDate']);
    final colorScheme = Theme.of(context).colorScheme;

    return SchoolCard(
      padding: const EdgeInsets.all(24),
      color: colorScheme.primary,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppLocalizations.of(context)!.urgently,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.bolt, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                due != null ? _getHumanFriendlyDate(context, due) : AppLocalizations.of(context)!.noDeadline,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context)!.startNow,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
    final title = data['title']?.toString() ?? AppLocalizations.of(context)!.unknownKey13;
    final due = toDate(data['dueDate']);
    final attachments = List<Map<String, dynamic>>.from(
      data['attachments'] ?? [],
    );
    final grade = submission?['grade'];
    final submitted = submission != null;
    final isOverdue = due != null && due.isBefore(DateTime.now()) && !submitted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SchoolCard(
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
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SchoolAvatar(name: AppLocalizations.of(context)!.teacher, radius: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (grade != null)
                        Text(
                          '$grade%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: SchoolColors.green,
                          ),
                        )
                      else if (isOverdue)
                        Text(
                          AppLocalizations.of(context)!.expired,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: SchoolColors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.subjectGeneral,
                    style: TextStyle(color: SchoolColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
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
                        due != null ? _getHumanFriendlyDate(context, due) : AppLocalizations.of(context)!.noDeadline,
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue
                              ? SchoolColors.red
                              : SchoolColors.muted,
                          fontWeight: isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (attachments.isNotEmpty) ...[
                        const Icon(
                          Icons.attach_file,
                          size: 14,
                          color: SchoolColors.muted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${attachments.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SchoolColors.muted,
                          ),
                        ),
                      ],
                      if (submission?['attachments'] != null &&
                          (submission!['attachments'] as List).isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.file_present_rounded,
                          size: 14,
                          color: SchoolColors.green,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${(submission!['attachments'] as List).length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SchoolColors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (submitted && grade == null) ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoHomeworkEmptyState extends StatelessWidget {
  const NoHomeworkEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.celebration_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.everythingIsDone,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.thereAreNoTasksYet,
            style: TextStyle(color: SchoolColors.muted),
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
  if (diff.inDays == 0) return AppLocalizations.of(context)!.today;
  if (diff.inDays == 1) return AppLocalizations.of(context)!.tomorrow;
  if (diff.inDays < 7) return DateFormat('EEEE', 'ru').format(date);
  return DateFormat('d MMM', 'ru').format(date);
}
