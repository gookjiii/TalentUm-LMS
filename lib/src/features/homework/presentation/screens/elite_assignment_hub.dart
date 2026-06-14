import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:school_world/main.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';

class EliteAssignmentHub extends HookWidget {
  const EliteAssignmentHub({super.key, required this.classId, required this.classes, this.onClassSelect});
  final String classId;
  final List<Map<String, dynamic>> classes;
  final ValueChanged<String>? onClassSelect;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final selectedId = useState<String?>(null);
    final isDesktop = MediaQuery.sizeOf(context).width > 900;

    final assignmentsSnap = useStream(useMemoized(() => repo.assignmentsForClass(classId), [classId]));

    // Auto-select first assignment
    useEffect(() {
      if (selectedId.value == null && assignmentsSnap.hasData && assignmentsSnap.data!.docs.isNotEmpty) {
        selectedId.value = assignmentsSnap.data!.docs.first.id;
      }
      return null;
    }, [assignmentsSnap.hasData]);

    final activeAssignmentDoc = (assignmentsSnap.hasData && assignmentsSnap.data!.docs.isNotEmpty)
        ? assignmentsSnap.data!.docs.firstWhere(
            (doc) => doc.id == selectedId.value,
            orElse: () => assignmentsSnap.data!.docs.first,
          )
        : null;
    final activeAssignment = activeAssignmentDoc?.data();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Assignment List
          Expanded(
            flex: isDesktop ? 6 : 1,
            child: EliteNestedBezel(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Row(
                      children: [
                        const BackButton(color: Colors.white),
                        Expanded(
                          child: Text(
                            'Assignments',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        if (classes.length > 1)
                          EliteTactileButton(
                            onTap: () => showClassSwitcher(
                              context: context,
                              classes: classes,
                              currentClassId: classId,
                              onSelect: onClassSelect ?? (_) {},
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(color: SchoolColors.darkBorder, height: 1),
                  Expanded(
                    child: !assignmentsSnap.hasData
                        ? const Center(child: BrandedLoader())
                        : assignmentsSnap.data!.docs.isEmpty
                            ? const EmptyStateWidget(
                                icon: Icons.assignment_turned_in_rounded,
                                title: 'No assignments',
                                subtitle: 'You are all caught up!',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(40),
                                itemCount: assignmentsSnap.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final doc = assignmentsSnap.data!.docs[index];
                                  final item = doc.data();
                                  return FadeInUp(
                                    delay: Duration(milliseconds: 100 * index),
                                    child: _AssignmentCard(
                                      item: item,
                                      isActive: selectedId.value == doc.id,
                                      onTap: () => selectedId.value = doc.id,
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          if (isDesktop) const SizedBox(width: 12),
          // Submission Detail
          if (isDesktop)
            Expanded(
              flex: 4,
              child: EliteNestedBezel(
                padding: EdgeInsets.zero,
                child: activeAssignment != null 
                    ? _SubmissionPanel(assignmentId: activeAssignmentDoc!.id, assignment: activeAssignment)
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.item, required this.isActive, required this.onTap});
  final Map<String, dynamic> item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final due = (item['dueDate'] as Timestamp?)?.toDate();
    final dueStr = due != null ? DateFormat('dd/MM/yyyy').format(due) : 'No date';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(24),
        color: isActive ? SchoolColors.primary.withOpacity(0.08) : Colors.white.withOpacity(0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusTag(dueDate: due),
                Text(
                  'Hạn: $dueStr',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SchoolColors.darkMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item['title']?.toString() ?? 'Untitled',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['courseName']?.toString() ?? 'General',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SchoolColors.darkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({this.dueDate});
  final DateTime? dueDate;

  @override
  Widget build(BuildContext context) {
    Color color = SchoolColors.primary;
    String label = 'Đang làm';

    if (dueDate != null) {
      if (dueDate!.isBefore(DateTime.now())) {
        color = SchoolColors.red;
        label = 'Quá hạn';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SubmissionPanel extends HookWidget {
  const _SubmissionPanel({required this.assignmentId, required this.assignment});
  final String assignmentId;
  final Map<String, dynamic> assignment;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final isUploading = useState(false);
    final progress = useState(0.0);
    
    // Check for submission
    final submissionSnap = useStream(useMemoized(() => repo.firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: repo.uid)
        .snapshots(), [assignmentId, repo.uid]));

    final hasSubmitted = submissionSnap.hasData && submissionSnap.data!.docs.isNotEmpty;
    final submissionData = hasSubmitted ? submissionSnap.data!.docs.first.data() : null;

    void simulateUpload() {
      isUploading.value = true;
      progress.value = 0.0;
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        progress.value += 0.1;
        if (progress.value >= 1.0) {
          // Create actual submission
          await repo.createSubmission(
            assignmentId: assignmentId,
            studentId: repo.uid!,
            content: 'Submitted via Elite Hub',
          );
          isUploading.value = false;
          return false;
        }
        return true;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: Border(bottom: BorderSide(color: SchoolColors.darkBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ASSIGNMENT DETAIL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: SchoolColors.primaryLight,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                assignment['title']?.toString() ?? 'Assignment',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(40),
            children: [
              Text(
                assignment['description']?.toString() ?? 'No description provided.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: SchoolColors.darkBorder),
              const SizedBox(height: 32),
              const Text(
                'Submission Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (hasSubmitted)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: SchoolColors.success.withOpacity(0.05),
                    border: Border.all(color: SchoolColors.success.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: SchoolColors.success, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assignment Submitted',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                                Text(
                                  'Completed on ${DateFormat('MMMM d, yyyy').format((submissionData!['createdAt'] as Timestamp).toDate())}',
                                  style: const TextStyle(fontSize: 13, color: SchoolColors.darkMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (submissionData['grade'] != null) ...[
                        const SizedBox(height: 24),
                        const Divider(color: SchoolColors.darkBorder),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grade Received:', style: TextStyle(color: SchoolColors.darkMuted, fontWeight: FontWeight.w600)),
                            Text(
                              '${submissionData['grade']}/100',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: SchoolColors.success),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                )
              else
                EliteTactileButton(
                  onTap: simulateUpload,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isUploading.value ? 0.04 : 0.02),
                      border: Border.all(
                        color: isUploading.value ? SchoolColors.primary : SchoolColors.darkBorderBright,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: SchoolColors.primary,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tải bài làm của bạn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kéo thả hoặc click để chọn tệp',
                          style: TextStyle(
                            fontSize: 13,
                            color: SchoolColors.darkMuted,
                          ),
                        ),
                        if (isUploading.value) ...[
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.value,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(SchoolColors.primary),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploading... ${(progress.value * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(40),
          child: GradientButton(
            text: hasSubmitted ? 'Đã nộp thành công' : 'Nộp bài ngay',
            onTap: hasSubmitted ? null : simulateUpload,
          ),
        ),
      ],
    );
  }
}
