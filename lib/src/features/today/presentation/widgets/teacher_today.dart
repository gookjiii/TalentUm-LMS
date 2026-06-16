import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../firebase/school_repository.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';
import 'package:school_world/main.dart';

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
    final isDesktop = MediaQuery.sizeOf(context).width > 1200;
    final repo = AppScope.of(context).repository;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, profileSnap) {
        final profile = profileSnap.data?.data() ?? const <String, dynamic>{};
        final user = repo.auth.currentUser;
        final name = (profile['name']?.toString().trim().isNotEmpty ?? false)
            ? profile['name'].toString().trim()
            : (user?.displayName ?? "Professor");
            
        final firstName = name.split(RegExp(r'\s+')).first;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 16,
                  isDesktop ? 32 : 16,
                  isDesktop ? 32 : 16,
                  isDesktop ? 32 : 100,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _EliteTeacherHeader(teacherName: firstName, isDesktop: isDesktop),
                                SizedBox(height: isDesktop ? 48 : 24),
                                _TeacherStatsGrid(repo: repo, classes: widget.classes, isDesktop: isDesktop),
                                SizedBox(height: isDesktop ? 48 : 32),
                                const _SectionHeader(title: 'Mission Timeline', icon: Icons.auto_awesome),
                                const SizedBox(height: 24),
                                _TeacherTimelineList(classes: widget.classes),
                              ],
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 48),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  const _CampusVitalityCard(),
                                  const SizedBox(height: 32),
                                  _ActionCenterCard(repo: repo),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _EliteTeacherHeader extends StatelessWidget {
  const _EliteTeacherHeader({required this.teacherName, required this.isDesktop});
  final String teacherName;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MISSION CONTROL',
          style: AppTextStyle.labelSm.copyWith(
            color: SchoolColors.primaryLight,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Welcome back,\nProf. $teacherName',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 48 : 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1.5,
                ),
              ),
            ),

          ],
        ),
      ],
    );
  }
}

class _TeacherStatsGrid extends StatelessWidget {
  const _TeacherStatsGrid({required this.repo, required this.classes, required this.isDesktop});
  final SchoolRepository repo;
  final List<Map<String, dynamic>> classes;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final studentCount = classes.fold<int>(0, (acc, c) => acc + ((c['studentIds'] as List?)?.length ?? 0));

    return StreamBuilder<QuerySnapshot>(
      stream: repo.firestore.collection('submissions').where('status', isEqualTo: 'submitted').snapshots(),
      builder: (context, snapshot) {
        final pendingGrades = snapshot.data?.docs.length ?? 0;

        if (!isDesktop) {
          return Column(
            children: [
              _StatCard(
                value: classes.length.toString(),
                label: 'Classes Today',
                icon: Icons.school_outlined,
                isDesktop: false,
              ),
              const SizedBox(height: 16),
              _StatCard(
                value: pendingGrades.toString(),
                label: 'Pending Grades',
                icon: Icons.assignment_outlined,
                isAlert: pendingGrades > 0,
                isDesktop: false,
              ),
              const SizedBox(height: 16),
              _StatCard(
                value: studentCount.toString(),
                label: 'Active Students',
                icon: Icons.people_outline,
                isDesktop: false,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                value: classes.length.toString(),
                label: 'Classes Today',
                icon: Icons.school_outlined,
                isDesktop: true,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _StatCard(
                value: pendingGrades.toString(),
                label: 'Pending Grades',
                icon: Icons.assignment_outlined,
                isAlert: pendingGrades > 0,
                isDesktop: true,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _StatCard(
                value: studentCount.toString(),
                label: 'Active Students',
                icon: Icons.people_outline,
                isDesktop: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.icon, this.isAlert = false, required this.isDesktop});
  final String value;
  final String label;
  final IconData icon;
  final bool isAlert;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final iconColor = isAlert ? SchoolColors.red : SchoolColors.primaryLight;

    return NestedBezelCard(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: isDesktop 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isAlert ? SchoolColors.red : Colors.white,
                      ),
                    ),
                    Icon(icon, color: iconColor, size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label.toUpperCase(),
                  style: AppTextStyle.labelSm.copyWith(
                    color: SchoolColors.darkMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SchoolColors.darkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isAlert ? SchoolColors.red : Colors.white,
                        ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SchoolColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _TeacherTimelineList extends StatelessWidget {
  const _TeacherTimelineList({required this.classes});
  final List<Map<String, dynamic>> classes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(classes.length, (index) {
        final cls = classes[index];
        final hour = 8 + (index * 2);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SchoolColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:30 - ${(hour + 1).toString().padLeft(2, '0')}:45',
                    style: AppTextStyle.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: SchoolColors.primaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: GlassCard(
                  onTap: () {},
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cls['name']?.toString() ?? 'Class',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              cls['subject']?.toString() ?? 'Subject',
                              style: const TextStyle(fontSize: 13, color: SchoolColors.darkMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const _LivePulseBadge(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _LivePulseBadge extends HookWidget {
  const _LivePulseBadge();

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: const Duration(seconds: 2))..repeat(reverse: true);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SchoolColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: SchoolColors.success.withOpacity(0.2 + 0.3 * controller.value)),
          ),
          child: Text(
            'LIVE',
            style: AppTextStyle.labelSm.copyWith(color: SchoolColors.success, fontWeight: FontWeight.w900),
          ),
        );
      },
    );
  }
}

class _CampusVitalityCard extends StatelessWidget {
  const _CampusVitalityCard();

  @override
  Widget build(BuildContext context) {
    return NestedBezelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAMPUS VITALITY',
            style: AppTextStyle.labelSm.copyWith(color: SchoolColors.primaryLight, letterSpacing: 1.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 0.88,
                    strokeWidth: 16,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(SchoolColors.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '88%',
                      style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      'HEALTHY',
                      style: AppTextStyle.labelSm.copyWith(color: SchoolColors.success, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'STABILITY', value: 'High', color: SchoolColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'ENGAGEMENT', value: 'Optimal', color: SchoolColors.primaryLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyle.labelSm.copyWith(fontSize: 10, color: SchoolColors.darkMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _ActionCenterCard extends StatelessWidget {
  const _ActionCenterCard({required this.repo});
  final SchoolRepository repo;

  @override
  Widget build(BuildContext context) {
    return NestedBezelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTION CENTER',
                style: AppTextStyle.labelSm.copyWith(color: SchoolColors.primaryLight, letterSpacing: 1.5, fontWeight: FontWeight.w900),
              ),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: SchoolColors.red, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repo.firestore.collection('submissions').where('status', isEqualTo: 'submitted').limit(4).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('All caught up!', style: TextStyle(color: SchoolColors.darkMuted))),
                );
              }
              return Column(
                children: docs.map((doc) => _ActionBarItem(doc: doc)).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('VIEW ALL TASKS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ActionBarItem extends StatelessWidget {
  const _ActionBarItem({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: SchoolColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_note, color: SchoolColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Submission', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('Assignment ID: ${doc.id.substring(0, 5)}...', style: const TextStyle(fontSize: 11, color: SchoolColors.darkMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: SchoolColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('URGENT', style: TextStyle(color: SchoolColors.red, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
