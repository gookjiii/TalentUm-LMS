import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class StudentRightSidebar extends StatelessWidget {
  const StudentRightSidebar({super.key, required this.classes});
  final List<Map<String, dynamic>> classes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(title: 'ПРЕДСТОЯЩЕЕ РАСПИСАНИЕ'),
          const SizedBox(height: 16),
          ...classes.take(3).map((c) => UpcomingScheduleCard(data: c)),
          const SizedBox(height: 32),
          const SectionHeader(title: 'БЛИЖАЙШИЕ ЗАДАНИЯ'),
          const SizedBox(height: 16),
          _UpcomingAssignmentsList(classes: classes),
          const SizedBox(height: 32),
          const SectionHeader(title: 'УСПЕХИ В КЛАССЕ'),
          const SizedBox(height: 16),
          const SuccessProgressCard(),
        ],
      ),
    );
  }
}

class UpcomingScheduleCard extends StatelessWidget {
  const UpcomingScheduleCard({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(data['coverColor']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              data['name']?[0] ?? '?',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
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
                  data['startTimeLabel'] ?? '09:00 - 10:30',
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

class _UpcomingAssignmentsList extends StatefulWidget {
  const _UpcomingAssignmentsList({required this.classes});
  final List<Map<String, dynamic>> classes;

  @override
  State<_UpcomingAssignmentsList> createState() => _UpcomingAssignmentsListState();
}

class _UpcomingAssignmentsListState extends State<_UpcomingAssignmentsList> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _UpcomingAssignmentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Note: To be totally safe, you can compare oldWidget.classes with widget.classes,
    // but in this side-bar list, re-init is mostly needed if the length changes.
    if (oldWidget.classes.length != widget.classes.length) {
      _initStream();
    }
  }

  void _initStream() {
    if (widget.classes.isEmpty) return;
    final ids = widget.classes.map((c) => c['id'] as String).take(10).toList();
    final repo = AppScope.of(context).repository;
    _stream = repo.firestore
        .collection('assignments')
        .where('classId', whereIn: ids)
        .limit(3)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.classes.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return Text(
            l10n.noAssignmentsYet,
            style: const TextStyle(color: SchoolColors.muted, fontSize: 13),
          );
        return Column(
          children: docs.map((d) => UpcomingAssignmentCard(doc: d)).toList(),
        );
      },
    );
  }
}

class UpcomingAssignmentCard extends StatelessWidget {
  const UpcomingAssignmentCard({super.key, required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final due = data['dueDate'] as Timestamp?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 12,
                  color: SchoolColors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  due != null
                      ? DateFormat('d MMM', 'ru').format(due.toDate())
                      : '—',
                  style: const TextStyle(
                    fontSize: 11,
                    color: SchoolColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessProgressCard extends StatelessWidget {
  const SuccessProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SchoolCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: SchoolColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.avgGrade,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '4.8',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.85,
              backgroundColor: theme.colorScheme.surfaceVariant,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
