import re

with open('lib/src/features/today/presentation/widgets/student_today.dart', 'r') as f:
    content = f.read()

# 1. Replace the bottom section
old_bottom = """                // 3. UPCOMING TASKS (Staggered List)
                SectionHeader(
                  title: 'Upcoming Assignments',
                  action: 'View All',
                  onActionTap: onHomeworkTap,
                ),
                const SizedBox(height: 16),
                _UpcomingTasksList(classColor: classColor),
                
                const SizedBox(height: 80), // Bottom breathing room"""

new_bottom = """                // 3. BOTTOM SECTION (2-Column on Desktop)
                if (isMobile) ...[
                  SectionHeader(
                    title: 'Action Require',
                    action: 'View All',
                    onActionTap: onHomeworkTap,
                  ),
                  const SizedBox(height: 16),
                  _UpcomingTasksList(classColor: classColor),
                  const SizedBox(height: 40),
                  const SectionHeader(title: 'Timeline'),
                  const SizedBox(height: 16),
                  _TimelineList(classColor: classColor),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Timeline'),
                            const SizedBox(height: 16),
                            _TimelineList(classColor: classColor),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'Action Require',
                              action: 'View All',
                              onActionTap: onHomeworkTap,
                            ),
                            const SizedBox(height: 16),
                            _UpcomingTasksList(classColor: classColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 80), // Bottom breathing room"""

content = content.replace(old_bottom, new_bottom)

# 2. Add _TimelineList
timeline_code = """
// ─────────────────────────────────────────────────────────────────
// TIMELINE LIST
// ─────────────────────────────────────────────────────────────────
class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.classColor});
  final Color classColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final events = [
      {'time': '09:00', 'title': 'Data Structures Lecture', 'type': 'Lecture', 'icon': Icons.video_camera_front_outlined},
      {'time': '11:30', 'title': 'Quiz 2 Opens', 'type': 'Assessment', 'icon': Icons.quiz_outlined},
      {'time': '14:00', 'title': 'Study Group Meeting', 'type': 'Event', 'icon': Icons.group_outlined},
      {'time': '23:59', 'title': 'Assignment Deadline', 'type': 'Deadline', 'icon': Icons.warning_amber_rounded},
    ];

    return StaggeredList(
      delayStep: const Duration(milliseconds: 60),
      children: events.map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SchoolCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? classColor.withValues(alpha: 0.1) : classColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    event['icon'] as IconData,
                    color: classColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: isDark ? SchoolColors.darkMuted : SchoolColors.muted),
                          const SizedBox(width: 6),
                          Text(
                            event['time'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event['type'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
"""

if "_TimelineList" not in content:
    content += timeline_code

with open('lib/src/features/today/presentation/widgets/student_today.dart', 'w') as f:
    f.write(content)
