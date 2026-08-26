import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class FamilyActivityFeed extends StatelessWidget {
  const FamilyActivityFeed({super.key, required this.childIds});
  final List<String> childIds;

  @override
  Widget build(BuildContext context) {
    if (childIds.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final repo = AppScope.of(context).repository;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.firestore
          .collection('submissions')
          .where('studentId', whereIn: childIds)
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  l10n.noActivityYet,
                  style: const TextStyle(color: SchoolColors.muted),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RepaintBoundary(
                    child: _ActivityItem(doc: docs[index], childIds: childIds),
                  ),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.doc, required this.childIds});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final List<String> childIds;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final l10n = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).repository;
    final studentId = data['studentId'] as String;
    final classId = data['classId'] as String?;
    final grade = data['grade'];
    final timestamp = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        repo.firestore.collection('users').doc(studentId).get(),
        if (classId != null)
          repo.firestore.collection('classes').doc(classId).get()
        else
          Future.value(null as DocumentSnapshot?),
      ].whereType<Future<DocumentSnapshot>>().toList()), // This was the trick!
      builder: (context, snaps) {
        // Fallback name/class
        String studentName = l10n.student;
        String className = '...';

        if (snaps.hasData && snaps.data != null && snaps.data!.isNotEmpty) {
          final sDoc = snaps.data![0];
          if (sDoc.exists) {
            studentName = (sDoc.data() as Map?)?['name']?.toString() ?? l10n.student;
          }
          
          if (snaps.data!.length > 1) {
            final cDoc = snaps.data![1];
            if (cDoc.exists) {
              className = (cDoc.data() as Map?)?['name']?.toString() ?? 'Class';
            }
          }
        }
        
        return SchoolCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (grade != null ? SchoolColors.green : SchoolColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  grade != null ? Icons.grade_rounded : Icons.assignment_turned_in_rounded,
                  color: grade != null ? SchoolColors.green : SchoolColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: studentName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: grade != null 
                              ? " ${l10n.receivedGrade} " 
                              : " ${l10n.submittedAssignment} ",
                          ),
                          if (grade != null)
                            TextSpan(
                              text: "$grade%",
                              style: const TextStyle(
                                color: SchoolColors.green,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      className,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM, HH:mm', l10n.localeName).format(timestamp),
                      style: const TextStyle(fontSize: 11, color: SchoolColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
