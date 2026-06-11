import 'package:school_world/src/utils/responsive_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/widgets/file_preview.dart';
import 'package:school_world/src/models/schedule.dart' hide colorFromHex;
import 'package:school_world/src/app_state.dart';

class TeacherToday extends StatefulHookConsumerWidget {
  const TeacherToday({
    super.key,
    required this.classes,
    required this.selectedClassId,
    required this.onTabSelect,
    required this.onSelectClass,
    required this.onDeleteClass,
    required this.onCopyGuestLink,
    required this.onCreateClass,
    required this.onProfileTap,
    this.showSidebar = false,
  });

  final List<Map<String, dynamic>> classes;
  final String selectedClassId;
  final ValueChanged<int> onTabSelect;
  final ValueChanged<String> onSelectClass;
  final void Function(String classId, String className) onDeleteClass;
  final void Function(String classId, String inviteCode) onCopyGuestLink;
  final VoidCallback onCreateClass;
  final VoidCallback onProfileTap;
  final bool showSidebar;

  @override
  ConsumerState<TeacherToday> createState() => _TeacherTodayState();
}

class _TeacherTodayState extends ConsumerState<TeacherToday> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _userStream = repo.userDocStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final user = repo.auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final appState = AppScope.of(context).appState;
    final isLeadTeacher = appState.isLeadTeacher;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, profileSnap) {
        final profile = profileSnap.data?.data() ?? const <String, dynamic>{};
        final name = (profile['name']?.toString().trim().isNotEmpty ?? false)
            ? profile['name'].toString().trim()
            : (user?.displayName ?? AppLocalizations.of(context)!.teacher);
        final avatarUrl = profile['avatarUrl']?.toString();
        final firstName = name.split(RegExp(r'\s+')).first;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 32,
                isMobile ? 16 : 32,
                isMobile ? 16 : 32,
                40,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. HERO SECTION
                  FadeInUp(
                    offset: 40,
                    child: _TeacherHeroSection(
                      teacherName: firstName,
                      fullName: name,
                      avatarUrl: avatarUrl,
                      isLeadTeacher: isLeadTeacher,
                      isMobile: isMobile,
                      onProfileTap: widget.onProfileTap,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. QUICK STATS
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    offset: 30,
                    child: _TeacherKpiRow(
                      repo: repo,
                      classes: widget.classes,
                      isMobile: isMobile,
                      isLeadTeacher: isLeadTeacher,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Quick Links
                  FadeInUp(
                    delay: const Duration(milliseconds: 150),
                    offset: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: AppLocalizations.of(context)!.quickLinks1,
                          action: "",
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: isMobile ? 2 : 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            QuickTile(
                              onTap: () => widget.onTabSelect(5),
                              icon: Icons.library_books_outlined,
                              label: AppLocalizations.of(context)!.library,
                              color: SchoolColors.primary,
                            ),
                            QuickTile(
                              onTap: () => widget.onTabSelect(6),
                              icon: Icons.ondemand_video_outlined,
                              label: AppLocalizations.of(context)!.webinars,
                              color: SchoolColors.accent,
                            ),
                            QuickTile(
                              onTap: () => widget.onTabSelect(7),
                              icon: Icons.book_outlined,
                              label: AppLocalizations.of(context)!.magazine,
                              color: SchoolColors.green,
                            ),
                            QuickTile(
                              onTap: () => widget.onTabSelect(9),
                              icon: Icons.people_outline,
                              label: AppLocalizations.of(context)!.participants,
                              color: SchoolColors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 3. ACTION REQUIRED & SCHEDULE
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    offset: 20,
                    child: isMobile
                        ? Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: l10n.needsReviewToday.toUpperCase(),
                                    action: '',
                                  ),
                                  const SizedBox(height: 16),
                                  const RepaintBoundary(
                                    child: _NeedsAttentionCard(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: l10n.todaysClasses.toUpperCase(),
                                    action: l10n.viewAll,
                                    onActionTap: () => widget.onTabSelect(8),
                                  ),
                                  const SizedBox(height: 16),
                                  RepaintBoundary(
                                    child: _TeacherTodayScheduleInline(
                                      repo: repo,
                                      now: DateTime.now(),
                                      classes: widget.classes,
                                      onSelectClass: widget.onSelectClass,
                                      onCopyGuestLink: widget.onCopyGuestLink,
                                      onDeleteClass: widget.onDeleteClass,
                                      onOpenSchedule: () =>
                                          widget.onTabSelect(8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: l10n.needsReviewToday
                                          .toUpperCase(),
                                      action: '',
                                    ),
                                    const SizedBox(height: 16),
                                    const RepaintBoundary(
                                      child: _NeedsAttentionCard(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: l10n.todaysClasses.toUpperCase(),
                                      action: l10n.viewAll,
                                      onActionTap: () => widget.onTabSelect(8),
                                    ),
                                    const SizedBox(height: 16),
                                    RepaintBoundary(
                                      child: _TeacherTodayScheduleInline(
                                        repo: repo,
                                        now: DateTime.now(),
                                        classes: widget.classes,
                                        onSelectClass: widget.onSelectClass,
                                        onCopyGuestLink: widget.onCopyGuestLink,
                                        onDeleteClass: widget.onDeleteClass,
                                        onOpenSchedule: () =>
                                            widget.onTabSelect(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TeacherHeroSection extends StatelessWidget {
  const _TeacherHeroSection({
    required this.teacherName,
    required this.fullName,
    required this.avatarUrl,
    required this.isLeadTeacher,
    required this.isMobile,
    required this.onProfileTap,
  });

  final String teacherName;
  final String fullName;
  final String? avatarUrl;
  final bool isLeadTeacher;
  final bool isMobile;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeColor = isLeadTeacher
        ? SchoolColors.secondary
        : SchoolColors.primary;
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 17
        ? l10n.goodAfternoon
        : l10n.goodEvening;

    return GlassCard(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      borderRadius: 24,
      color: isDark
          ? themeColor.withValues(alpha: 0.08)
          : themeColor.withValues(alpha: 0.04),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColor.withValues(alpha: 0.15),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            StatusChip(
                              label: isLeadTeacher ? 'LEAD FACULTY' : 'FACULTY',
                              color: themeColor,
                              icon: isLeadTeacher
                                  ? Icons.verified_rounded
                                  : Icons.school_rounded,
                            ),
                            if (isLeadTeacher) ...[
                              const SizedBox(width: 8),
                              const StatusChip(
                                label: 'ADMIN',
                                color: SchoolColors.orange,
                              ),
                            ],
                          ],
                        ),
                        if (isMobile)
                          SchoolAvatar(
                            name: fullName,
                            avatarUrl: avatarUrl,
                            radius: 20,
                            onTap: onProfileTap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '$greeting,\n$teacherName.',
                            style: AppTextStyle.display(
                              context,
                            ).copyWith(fontSize: isMobile ? 28 : 36),
                          ),
                        ),
                        if (!isMobile)
                          SchoolAvatar(
                            name: fullName,
                            avatarUrl: avatarUrl,
                            radius: 32,
                            onTap: onProfileTap,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.isLarge = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SchoolCard(
      padding: EdgeInsets.all(isLarge ? 28 : 20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 24 : 16),
          Text(
            value,
            style: AppTextStyle.mono(
              fontSize: isLarge ? 42 : 32,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : SchoolColors.text,
            ).copyWith(letterSpacing: -1),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? SchoolColors.darkTextSecondary
                  : SchoolColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TeacherKpiRow extends StatefulWidget {
  const _TeacherKpiRow({
    required this.repo,
    required this.classes,
    required this.isMobile,
    required this.isLeadTeacher,
  });
  final SchoolRepository repo;
  final List<Map<String, dynamic>> classes;
  final bool isMobile;
  final bool isLeadTeacher;

  @override
  State<_TeacherKpiRow> createState() => _TeacherKpiRowState();
}

class _TeacherKpiRowState extends State<_TeacherKpiRow> {
  Stream<QuerySnapshot>? _submissionsStream;
  Future<QuerySnapshot>? _gradedFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _submissionsStream = widget.repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'submitted')
          .snapshots();
      _gradedFuture = widget.repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'graded')
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentCount = widget.classes.fold<int>(
      0,
      (acc, c) => acc + ((c['studentIds'] as List?)?.length ?? 0),
    );
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: _submissionsStream,
      builder: (context, submissionsSnap) {
        return FutureBuilder<QuerySnapshot>(
          future: _gradedFuture,
          builder: (context, gradedSnap) {
            final ungradedCount = submissionsSnap.data?.docs.length ?? 0;
            final gradedDocs = gradedSnap.data?.docs ?? [];
            double avg = 0;
            if (gradedDocs.isNotEmpty) {
              final sum = gradedDocs.fold<double>(0, (acc, d) {
                final g = d.data() as Map<String, dynamic>;
                return acc +
                    (double.tryParse(g['grade']?.toString() ?? '0') ?? 0);
              });
              avg = sum / gradedDocs.length;
            }

            final avgStr = avg == 0 ? "—" : avg.toStringAsFixed(1);
            final gradedStr = gradedDocs.isEmpty
                ? l10n.noGradesYet
                : "${gradedDocs.length} ${l10n.grade.toLowerCase()}";

            if (widget.isMobile) {
              return Column(
                children: [
                  _StatCard(
                    title: l10n.avgGrade.toUpperCase(),
                    value: avgStr,
                    subtitle: gradedStr,
                    color: SchoolColors.green,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: l10n.ungraded.toUpperCase(),
                          value: ungradedCount.toString(),
                          subtitle: l10n.today,
                          color: SchoolColors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: l10n.totalStudents.toUpperCase(),
                          value: studentCount.toString(),
                          subtitle: "${widget.classes.length} classes",
                          color: SchoolColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _StatCard(
                    title: l10n.avgGrade.toUpperCase(),
                    value: avgStr,
                    subtitle: gradedStr,
                    color: SchoolColors.green,
                    isLarge: true,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: _StatCard(
                    title: l10n.ungraded.toUpperCase(),
                    value: ungradedCount.toString(),
                    subtitle: l10n.today,
                    color: SchoolColors.red,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: _StatCard(
                    title: l10n.totalStudents.toUpperCase(),
                    value: studentCount.toString(),
                    subtitle: "${widget.classes.length} classes",
                    color: SchoolColors.primary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _NeedsAttentionCard extends StatefulWidget {
  const _NeedsAttentionCard({super.key});

  @override
  State<_NeedsAttentionCard> createState() => _NeedsAttentionCardState();
}

class _NeedsAttentionCardState extends State<_NeedsAttentionCard> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _attentionStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _attentionStream = repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'submitted')
          .limit(3)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _attentionStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty &&
            snapshot.connectionState != ConnectionState.waiting) {
          return SchoolCard(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.done_all_rounded,
                    color: SchoolColors.green,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.allChecked,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SchoolColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SchoolCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < docs.length; i++) ...[
                _AttentionSubmissionRow(
                  doc: docs[i],
                  isLast: i == docs.length - 1,
                ),
                if (i < docs.length - 1) const Divider(height: 1, indent: 64),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AttentionSubmissionRow extends StatelessWidget {
  const _AttentionSubmissionRow({required this.doc, required this.isLast});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isLast;

  void _reviewSubmission(
    BuildContext context,
    SchoolRepository repo,
    String studentName,
  ) async {
    final data = doc.data();
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
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
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                  ],
                  const Divider(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gradeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.scoreInOrPoints,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      if (gradeVal == null) {
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
                          submissionId: doc.id,
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
                  ? const SizedBox(
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
    final data = doc.data();
    final repo = AppScope.of(context).repository;
    final studentId = data['studentId']?.toString() ?? '';
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, dynamic>?>(
      future: repo.getUserData(studentId),
      builder: (context, userSnap) {
        final name = userSnap.data?['name']?.toString() ?? l10n.student;
        final title = data['assignmentTitle'] ?? l10n.assignment;

        return _AttentionRow(
          icon: Icons.assignment_outlined,
          color: SchoolColors.red,
          title: l10n.work,
          subtitle: "$name · $title",
          onTap: () => _reviewSubmission(context, repo, name),
          isLast: isLast,
        );
      },
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Уведомление: $title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : null,
        child: Padding(
          padding: context.screenPadding,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SchoolColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: SchoolColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherTodayScheduleInline extends StatefulWidget {
  const _TeacherTodayScheduleInline({
    required this.repo,
    required this.now,
    required this.classes,
    required this.onSelectClass,
    required this.onCopyGuestLink,
    required this.onDeleteClass,
    required this.onOpenSchedule,
  });
  final SchoolRepository repo;
  final DateTime now;
  final List<Map<String, dynamic>> classes;
  final ValueChanged<String> onSelectClass;
  final void Function(String, String) onCopyGuestLink;
  final void Function(String, String) onDeleteClass;
  final VoidCallback onOpenSchedule;

  @override
  State<_TeacherTodayScheduleInline> createState() =>
      _TeacherTodayScheduleInlineState();
}

class _TeacherTodayScheduleInlineState
    extends State<_TeacherTodayScheduleInline> {
  Stream<List<ScheduleEntry>>? _schedulesStream;
  Stream<List<ScheduleOverride>>? _overridesStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final uid = widget.repo.uid ?? '';
      _schedulesStream = widget.repo.teacherSchedulesStream(uid);
      _overridesStream = widget.repo.teacherScheduleOverridesStream(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScheduleEntry>>(
      stream: _schedulesStream,
      builder: (context, schedSnap) {
        return StreamBuilder<List<ScheduleOverride>>(
          stream: _overridesStream,
          builder: (context, ovSnap) {
            final schedules = schedSnap.data ?? [];
            final overrides = ovSnap.data ?? [];
            final todayItems = resolveDay(
              date: widget.now,
              schedules: schedules,
              overrides: overrides,
            );

            if (todayItems.isEmpty) {
              return _NoClassesEmptyState(
                onOpenSchedule: widget.onOpenSchedule,
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: todayItems.length,
              itemBuilder: (context, index) {
                final it = todayItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FadeInUp(
                    delay: Duration(milliseconds: 50 * index),
                    child: RepaintBoundary(child: _buildClassItem(context, it)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildClassItem(BuildContext context, ResolvedScheduleItem it) {
    final clsData = widget.classes.firstWhere(
      (c) => c['id'] == it.classId,
      orElse: () => <String, dynamic>{},
    );
    final clsName = clsData['name']?.toString() ?? it.classId;
    final clsSubject = clsData['subject']?.toString() ?? '—';
    final studentCount = (clsData['studentIds'] as List?)?.length ?? 0;

    final nowMin = widget.now.hour * 60 + widget.now.minute;
    final isLive = nowMin >= it.startMinute && nowMin < it.endMinute;
    final isDone = nowMin >= it.endMinute;

    return TeacherTodayClassRow(
      name: clsName,
      subject: clsSubject,
      timeLabel: '${_fmt(it.startMinute)} – ${_fmt(it.endMinute)}',
      roomLabel: it.room,
      note: it.note,
      color: colorFromHex(it.color, SchoolColors.primary),
      isLive: isLive,
      isDone: isDone,
      isCancelled: it.cancelled,
      students: studentCount,
      onTap: () => widget.onSelectClass(it.classId),
      onAction: () => widget.onSelectClass(it.classId), // Navigation for now
      repo: widget.repo,
      classId: it.classId,
      startMinute: it.startMinute,
    );
  }

  String _fmt(int min) {
    final h = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class TeacherTodayClassRow extends StatefulWidget {
  const TeacherTodayClassRow({
    super.key,
    required this.name,
    required this.subject,
    required this.timeLabel,
    required this.roomLabel,
    required this.color,
    required this.isLive,
    required this.isDone,
    required this.isCancelled,
    required this.students,
    required this.onTap,
    required this.onAction,
    required this.repo,
    required this.classId,
    required this.startMinute,
    this.note,
  });

  final String name, subject, timeLabel;
  final String? roomLabel;
  final String? note;
  final Color color;
  final bool isLive, isDone, isCancelled;
  final int students;
  final VoidCallback onTap, onAction;
  final SchoolRepository repo;
  final String classId;
  final int startMinute;

  @override
  State<TeacherTodayClassRow> createState() => _TeacherTodayClassRowState();
}

class _TeacherTodayClassRowState extends State<TeacherTodayClassRow> {
  Stream<QuerySnapshot>? _submissionsStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _submissionsStream = widget.repo.firestore
          .collection('submissions')
          .where('classId', isEqualTo: widget.classId)
          .where('status', isEqualTo: 'submitted')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTitle = widget.subject.isNotEmpty
        ? widget.subject
        : widget.name;
    final subtitle = widget.subject.isNotEmpty ? widget.name : '';
    final room = widget.roomLabel?.trim();

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final minutesUntil = widget.startMinute - nowMin;

    return SchoolCard(
      padding: EdgeInsets.zero,
      onTap: widget.onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (widget.isLive)
              Container(
                width: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: context.screenPadding,
                child: Row(
                  children: [
                    ClassBadge(
                      name: primaryTitle,
                      color: widget.color,
                      size: 46,
                      radius: 12,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.timeLabel}${room != null ? ' · ${l10n.cabinetWithNumber(room)}' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? SchoolColors.darkMuted
                                  : SchoolColors.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            primaryTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            children: [
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? SchoolColors.darkTextSecondary
                                        : SchoolColors.textSecondary,
                                  ),
                                ),
                              if (subtitle.isNotEmpty)
                                Text(
                                  ' · ',
                                  style: TextStyle(
                                    color: SchoolColors.muted.withOpacity(0.5),
                                  ),
                                ),
                              Text(
                                l10n.studentsCount(widget.students),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? SchoolColors.darkMuted
                                      : SchoolColors.muted,
                                ),
                              ),
                            ],
                          ),
                          if (widget.note != null &&
                              widget.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: widget.color.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                widget.note!.trim(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: widget.color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _submissionsStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: SchoolColors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count ${l10n.ungraded.toUpperCase()}',
                            style: const TextStyle(
                              color: SchoolColors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.isLive)
                      const StatusChip(
                        label: 'LIVE',
                        color: SchoolColors.primary,
                        pulseDot: true,
                      )
                    else if (widget.isDone)
                      StatusChip(
                        label: l10n.done.toUpperCase(),
                        color: SchoolColors.muted,
                        icon: Icons.check_circle_outline_rounded,
                      )
                    else if (minutesUntil > 0 && minutesUntil <= 60)
                      StatusChip(
                        label: l10n.inMin(minutesUntil).toUpperCase(),
                        color: SchoolColors.secondary,
                        icon: Icons.access_time_rounded,
                      )
                    else
                      StatusChip(
                        label: l10n.upcoming.toUpperCase(),
                        color: SchoolColors.muted,
                        icon: Icons.event_note_rounded,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoClassesEmptyState extends StatelessWidget {
  const _NoClassesEmptyState({required this.onOpenSchedule});
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVietnamese = l10n.localeName == 'vi';

    return SchoolCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: SchoolColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            isVietnamese
                ? "Bạn không có lịch dạy hôm nay 🎉"
                : l10n.noClassesScheduled,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: SchoolColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onOpenSchedule,
            child: Text(l10n.openWeeklySchedule),
          ),
        ],
      ),
    );
  }
}
