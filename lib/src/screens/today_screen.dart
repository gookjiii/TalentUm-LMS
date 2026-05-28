import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../firebase/school_repository.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.repository,
    required this.appState,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: MediaQuery.sizeOf(context).width < 720
          ? null
          : AppBar(title: Text(l10n.today)),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: repository.firestore
            .collection('users')
            .doc(repository.uid)
            .get(),
        builder: (context, userSnapshot) {
          final classIds = List<String>.from(
            userSnapshot.data?.data()?['classIds'] ?? [],
          );

          return CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            streamFactory: () => repository.allStudentAssignments(classIds),
            keys: [classIds.join(',')],
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final assignments = snapshot.data!.docs;
              if (assignments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: SchoolColors.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: SchoolColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noHomeworkAssigned,
                        style: const TextStyle(
                          color: SchoolColors.muted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index].data();
                  final dueDateRaw = assignment['dueDate'];
                  final DateTime? dueDate = dueDateRaw is Timestamp
                      ? dueDateRaw.toDate()
                      : null;
                  final isOverdue =
                      dueDate != null && dueDate.isBefore(DateTime.now());

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SchoolCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? SchoolColors.redContainer
                                  : SchoolColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.assignment_rounded,
                              color: isOverdue
                                  ? SchoolColors.red
                                  : SchoolColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignment['title']?.toString() ??
                                      l10n.assignment,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isOverdue
                                        ? SchoolColors.red
                                        : SchoolColors.text,
                                  ),
                                ),
                                if (dueDate != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 12,
                                        color: isOverdue
                                            ? SchoolColors.red
                                            : SchoolColors.muted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat.yMMMd(
                                          Localizations.localeOf(
                                            context,
                                          ).languageCode,
                                        ).add_Hm().format(dueDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isOverdue
                                              ? SchoolColors.red
                                              : SchoolColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isOverdue)
                            StatusChip(
                              label: l10n.overdue,
                              color: SchoolColors.red,
                              icon: Icons.warning_rounded,
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
