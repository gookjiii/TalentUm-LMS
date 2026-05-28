import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_world/l10n/app_localizations.dart';
import '../app_state.dart';
import '../firebase/school_repository.dart';
import '../widgets/school_widgets.dart';
import '../theme.dart';
import 'settings_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({
    super.key,
    required this.repository,
    required this.appState,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _classesStream;

  @override
  void initState() {
    super.initState();
    _classesStream = widget.repository.parentClasses();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: MediaQuery.sizeOf(context).width < 720
          ? null
          : AppBar(
              title: Text(l10n.parentDashboard),
              actions: [
                IconButton(
                  tooltip: l10n.settings,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          repository: widget.repository,
                          appState: widget.appState,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                ),
                IconButton(
                  tooltip: l10n.signOut,
                  onPressed: widget.repository.signOut,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _classesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = snapshot.data?.docs ?? [];
          if (classes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_outline,
                      size: 64,
                      color: SchoolColors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noClassesLinked,
                      style: const TextStyle(
                        color: SchoolColors.muted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classData = classes[index].data();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SchoolCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _ParentClassDetailScreen(
                          repository: widget.repository,
                          classId: classes[index].id,
                          className: classData['name']?.toString() ?? '',
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      ClassBadge(
                        name: classData['name']?.toString() ?? '',
                        color: parseHexColor(classData['coverColor']),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classData['name']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              l10n.teacherLabel(
                                classData['teacherName']?.toString() ??
                                    'Учитель',
                              ),
                              style: const TextStyle(color: SchoolColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: SchoolColors.muted,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ParentClassDetailScreen extends StatelessWidget {
  const _ParentClassDetailScreen({
    required this.repository,
    required this.classId,
    required this.className,
  });

  final SchoolRepository repository;
  final String classId;
  final String className;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: MediaQuery.sizeOf(context).width < 720
          ? null
          : AppBar(title: Text(className)),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: repository.firestore
            .collection('users')
            .doc(repository.uid)
            .get(),
        builder: (context, userSnapshot) {
          final linkedStudentId =
              userSnapshot.data?.data()?['linkedStudentId'] as String?;

          return CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            streamFactory: () => repository.assignmentsForClass(classId),
            keys: [classId],
            builder: (context, snapshot) {
              final assignments = snapshot.data?.docs ?? [];
              if (assignments.isEmpty) {
                return Center(child: Text(l10n.noAssignmentsYet));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index].data();
                  final assignmentId = assignments[index].id;

                  return CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    streamFactory: () => repository.firestore
                        .collection('submissions')
                        .where('assignmentId', isEqualTo: assignmentId)
                        .where('studentId', isEqualTo: linkedStudentId)
                        .snapshots(),
                    keys: [assignmentId, linkedStudentId],
                    builder: (context, subSnapshot) {
                      final submissionDoc = subSnapshot.data?.docs.firstOrNull;
                      final submission = submissionDoc?.data();
                      final grade = submission?['grade'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SchoolCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment['title']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (grade != null)
                                    StatusChip(
                                      label: '${l10n.grade}: $grade',
                                      color: SchoolColors.green,
                                    )
                                  else if (submission != null)
                                    StatusChip(
                                      label: l10n.submitted,
                                      color: SchoolColors.primary,
                                    )
                                  else
                                    StatusChip(
                                      label: l10n.notSubmitted,
                                      color: SchoolColors.muted,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
