import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';

class EliteAssignmentHub extends HookWidget {
  const EliteAssignmentHub({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedId = useState<int>(1);
    final isDesktop = MediaQuery.sizeOf(context).width > 900;

    final assignments = [
      {
        'id': 1,
        'title': 'Tích phân bội ba nâng cao',
        'course': 'Advanced Calculus',
        'due': '15/06/2026',
        'status': 'progress',
        'description': 'Giải quyết các bài toán về tích phân mặt và ứng dụng của nó trong tính thể tích vật thể phức hợp.'
      },
      {
        'id': 2,
        'title': 'Hệ thống học máy trong Giáo dục',
        'course': 'AI Ethics',
        'due': '10/06/2026',
        'status': 'submitted',
        'description': 'Viết báo cáo đánh giá tác động của AI đến mô hình đào tạo đại học truyền thống.'
      },
      {
        'id': 3,
        'title': 'Thực nghiệm cơ học lượng tử',
        'course': 'Quantum Physics',
        'due': '08/06/2026',
        'status': 'overdue',
        'description': 'Báo cáo số liệu đo đạc bước sóng và phân tích nhiễu từ khe kép.'
      },
      {
        'id': 4,
        'title': 'Phân tích dữ liệu người dùng',
        'course': 'Data Science',
        'due': '20/06/2026',
        'status': 'progress',
        'description': 'Xây dựng dashboard trực quan hóa hành vi người dùng trên nền tảng TalentUm.'
      },
    ];

    final activeAssignment = assignments.firstWhere((a) => a['id'] == selectedId.value);

    return Scaffold(
      backgroundColor: SchoolColors.darkBg,
      body: SafeArea(
        child: Padding(
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
                            EliteTactileButton(
                              onTap: () {},
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: SchoolColors.darkBorder, height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(40),
                          itemCount: assignments.length,
                          itemBuilder: (context, index) {
                            final item = assignments[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: 100 * index),
                              child: _AssignmentCard(
                                item: item,
                                isActive: selectedId.value == item['id'],
                                onTap: () => selectedId.value = item['id'] as int,
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
                    child: _SubmissionPanel(assignment: activeAssignment),
                  ),
                ),
            ],
          ),
        ),
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
                _StatusTag(status: item['status'] as String),
                Text(
                  'Hạn: ${item['due']}',
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
              item['title'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['course'] as String,
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
  const _StatusTag({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'submitted':
        color = SchoolColors.success;
        label = 'Đã nộp';
        break;
      case 'progress':
        color = SchoolColors.primary;
        label = 'Đang làm';
        break;
      case 'overdue':
        color = SchoolColors.red;
        label = 'Quá hạn';
        break;
      default:
        color = SchoolColors.darkMuted;
        label = status;
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
  const _SubmissionPanel({required this.assignment});
  final Map<String, dynamic> assignment;

  @override
  Widget build(BuildContext context) {
    final isUploading = useState(false);
    final progress = useState(0.0);

    void simulateUpload() {
      isUploading.value = true;
      progress.value = 0.0;
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        progress.value += 0.1;
        if (progress.value >= 1.0) {
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
                assignment['title'] as String,
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
                assignment['description'] as String,
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
                'Submission Files',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (assignment['status'] == 'submitted')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(color: SchoolColors.darkBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_outline, color: SchoolColors.success),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI_Ethics_Report_Final.pdf',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Uploaded on June 10, 2026',
                              style: TextStyle(
                                fontSize: 11,
                                color: SchoolColors.darkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
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
            text: assignment['status'] == 'submitted' ? 'Đã nộp thành công' : 'Nộp bài ngay',
            onTap: assignment['status'] == 'submitted' ? null : () {},
          ),
        ),
      ],
    );
  }
}
