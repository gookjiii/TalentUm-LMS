import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class TeacherRightSidebar extends StatelessWidget {
  const TeacherRightSidebar({super.key, required this.classes});
  final List<Map<String, dynamic>> classes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionHeader(title: AppLocalizations.of(context)!.upcomingClasses),
          const SizedBox(height: 16),
          if (classes.isEmpty)
            Text(
              AppLocalizations.of(context)!.noClasses,
              style: TextStyle(color: SchoolColors.muted),
            )
          else
            ...classes.take(3).map((c) => _ScheduleCard(data: c)),
          const SizedBox(height: 32),
          SectionHeader(title: AppLocalizations.of(context)!.tasksForTesting),
          const SizedBox(height: 16),
          _PendingSubmissionsList(classes: classes),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(data['coverColor']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClassBadge(name: data['name'] ?? '?', color: color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  data['subject']?.toString() ?? AppLocalizations.of(context)!.unknownKey12,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SchoolColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSubmissionsList extends StatefulWidget {
  const _PendingSubmissionsList({required this.classes});
  final List<Map<String, dynamic>> classes;

  @override
  State<_PendingSubmissionsList> createState() => _PendingSubmissionsListState();
}

class _PendingSubmissionsListState extends State<_PendingSubmissionsList> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _PendingSubmissionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classes.length != widget.classes.length) {
      _initStream();
    }
  }

  void _initStream() {
    final repo = AppScope.of(context).repository;
    _stream = repo.firestore
        .collection('submissions')
        .where('status', isEqualTo: 'submitted')
        .limit(5)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Text(
            AppLocalizations.of(context)!.allTasksHaveBeenChecked,
            style: TextStyle(color: SchoolColors.muted, fontSize: 13),
          );
        }
        return Column(
          children: docs.map((d) => _SubmissionMiniCard(doc: d)).toList(),
        );
      },
    );
  }
}

class _SubmissionMiniCard extends StatelessWidget {
  const _SubmissionMiniCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final studentId = data['studentId']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SchoolAvatar(name: studentId, radius: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudentName(
                    studentId: studentId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.newJob,
                    style: TextStyle(fontSize: 10, color: SchoolColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: SchoolColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
