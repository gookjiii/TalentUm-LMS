import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class RosterGradesScreen extends StatelessWidget {
  const RosterGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MediaQuery.sizeOf(context).width < 720
          ? null
          : AppBar(title: Text(l10n.myGrades)),
      body: CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        streamFactory: () => repo.firestore
            .collection('submissions')
            .where('studentId', isEqualTo: repo.uid)
            .snapshots(),
        keys: [repo.uid],
        builder: (context, snapshot) {
          final submissions = snapshot.data?.docs ?? [];
          if (submissions.isEmpty) {
            return Center(child: Text(l10n.noSubmissionsYet));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final data = submissions[index].data();
              final assignmentId = data['assignmentId']?.toString() ?? '';
              final grade = data['grade'];

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: repo.firestore
                    .collection('assignments')
                    .doc(assignmentId)
                    .get(),
                builder: (context, assignSnapshot) {
                  final assignData = assignSnapshot.data?.data();
                  final title =
                      assignData?['title']?.toString() ?? l10n.assignment;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SchoolCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (data['submittedAt'] != null)
                                  Text(
                                    DateFormat.yMMMd().format(
                                      (data['submittedAt'] as Timestamp)
                                          .toDate(),
                                    ),
                                    style: const TextStyle(
                                      color: SchoolColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _StatusPill(
                            label: grade != null ? '$grade%' : l10n.ungraded,
                            color: grade != null
                                ? SchoolColors.green
                                : SchoolColors.orange,
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
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
