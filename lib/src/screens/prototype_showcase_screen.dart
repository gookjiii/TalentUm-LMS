import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

/// Màn hình Prototype Trực quan & Tương tác cho Bản Cập nhật Mới
/// (Interactive UI/UX Prototype & Design System Showcase)
class PrototypeShowcaseScreen extends StatefulWidget {
  const PrototypeShowcaseScreen({super.key});

  @override
  State<PrototypeShowcaseScreen> createState() =>
      _PrototypeShowcaseScreenState();
}

class _PrototypeShowcaseScreenState extends State<PrototypeShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Simulator State
  int _simulatedTab = 0;
  bool _isTeacherMode = false;
  double _simulatedWidth = 375; // iPhone frame default
  bool _simulatedLoading = false;
  bool _simulatedFullWidth = false;
  bool _simulatedLeadingIcon = true;
  bool _simulatedTrailingIcon = false;
  int _simulatedScheduleDay = 0;
  SchoolButtonSize _selectedSize = SchoolButtonSize.md;
  SchoolButtonVariant _selectedVariant = SchoolButtonVariant.primary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '✨ Prototype Update Mới (UI/UX 2.0)',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? SchoolColors.darkSurface : Colors.white,
        foregroundColor: isDark ? SchoolColors.darkText : SchoolColors.text,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: SchoolColors.primary,
          unselectedLabelColor:
              isDark ? SchoolColors.darkMuted : SchoolColors.muted,
          indicatorColor: SchoolColors.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.phone_iphone_rounded), text: 'Mobile Simulator'),
            Tab(icon: Icon(Icons.touch_app_rounded), text: 'Button System'),
            Tab(icon: Icon(Icons.title_rounded), text: 'PageHeader & Layout'),
            Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'Mobile Chat UX'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMobileSimulatorTab(isDark),
          _buildButtonSystemTab(isDark),
          _buildPageHeaderTab(isDark),
          _buildMobileChatTab(isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 1: MOBILE SIMULATOR
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMobileSimulatorTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          // Simulator Controls Card
          SchoolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        color: SchoolColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tùy chỉnh Mô phỏng Thiết bị',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? SchoolColors.darkText : SchoolColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('iPhone (375px)'),
                      selected: _simulatedWidth == 375,
                      onSelected: (s) => setState(() => _simulatedWidth = 375),
                      selectedColor: SchoolColors.primary.withValues(alpha: 0.15),
                    ),
                    ChoiceChip(
                      label: const Text('Android Mini (360px)'),
                      selected: _simulatedWidth == 360,
                      onSelected: (s) => setState(() => _simulatedWidth = 360),
                      selectedColor: SchoolColors.primary.withValues(alpha: 0.15),
                    ),
                    ChoiceChip(
                      label: const Text('iPhone Pro Max (430px)'),
                      selected: _simulatedWidth == 430,
                      onSelected: (s) => setState(() => _simulatedWidth = 430),
                      selectedColor: SchoolColors.primary.withValues(alpha: 0.15),
                    ),
                    FilterChip(
                      label: Text(_isTeacherMode
                          ? '👨‍🏫 Teacher Mode'
                          : '👨‍🎓 Student Mode'),
                      selected: _isTeacherMode,
                      onSelected: (s) => setState(() => _isTeacherMode = s),
                      selectedColor: SchoolColors.accent.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Phone Screen Frame
          Center(
            child: Container(
              width: _simulatedWidth,
              height: 680,
              decoration: BoxDecoration(
                color: isDark ? SchoolColors.darkSurface : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    // Simulated Content
                    Positioned.fill(
                      child: _simulatedTab == 3
                          ? _buildSimulatedScheduleView(isDark)
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                            // Mobile Header
                            PageHeader(
                              showBackButton: false,
                              title: _isTeacherMode
                                  ? 'Chào mừng, Thầy An!'
                                  : 'Chào mừng, Linh!',
                              subtitle: 'Thứ Bảy, 29 tháng 8',
                              padding: EdgeInsets.zero,
                              trailing: SchoolAvatar(
                                name: _isTeacherMode ? 'Thầy An' : 'Linh',
                                radius: 22,
                                showBorder: true,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // KPI Row
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? SchoolColors.darkSurface
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : SchoolColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isTeacherMode
                                              ? 'BÀI CẦN CHẤM'
                                              : 'LỚP HỌC',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: SchoolColors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isTeacherMode ? '12' : '4',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? SchoolColors.darkSurface
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : SchoolColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isTeacherMode
                                              ? 'TIẾT DẠY HÔM NAY'
                                              : 'BÀI TẬP CẦN NỘP',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: SchoolColors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isTeacherMode ? '3' : '2',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Action CTA Card
                            SchoolCard(
                              color: SchoolColors.primary.withValues(
                                alpha: isDark ? 0.18 : 0.08,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome,
                                          color: SchoolColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _isTeacherMode
                                              ? 'Tạo bài tập tuần mới'
                                              : 'Chuỗi học tập: 5 ngày liên tiếp',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SchoolButton.primary(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              '✨ Tương tác Prototype thành công!'),
                                        ),
                                      );
                                    },
                                    label: _isTeacherMode
                                        ? 'Giao bài ngay'
                                        : 'Tiếp tục luyện tập',
                                    size: SchoolButtonSize.sm,
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    isFullWidth: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Floating Glassmorphism Navigation Bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SchoolMobileNavBar(
                        selectedIndex: _simulatedTab,
                        onSelect: (i) {
                          setState(() => _simulatedTab = i);
                        },
                        items: const [
                          SchoolMobileNavItem(
                            label: 'Today',
                            icon: Icons.dashboard_outlined,
                            selectedIcon: Icons.dashboard_rounded,
                          ),
                          SchoolMobileNavItem(
                            label: 'Chat',
                            icon: Icons.chat_bubble_outline_rounded,
                            selectedIcon: Icons.chat_bubble_rounded,
                            badgeCount: 3,
                          ),
                          SchoolMobileNavItem(
                            label: 'Quests',
                            icon: Icons.assignment_outlined,
                            selectedIcon: Icons.assignment_rounded,
                          ),
                          SchoolMobileNavItem(
                            label: 'Schedule',
                            icon: Icons.calendar_month_outlined,
                            selectedIcon: Icons.calendar_month_rounded,
                          ),
                        ],
                        moreLabel: 'More',
                        onMoreTap: () => _openSimulatedMoreSheet(context, isDark),
                        moreSelected: _simulatedTab == -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSimulatedMoreSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          color: isDark ? SchoolColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : SchoolColors.border.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : SchoolColors.border.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bảng Chọn Tính Năng Thêm (More)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMockMoreCard(
                        'Bản tin',
                        Icons.campaign_rounded,
                        SchoolColors.secondary,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMockMoreCard(
                        'Thư viện',
                        Icons.library_books_rounded,
                        SchoolColors.accent,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMockMoreCard(
                        'Webinars',
                        Icons.ondemand_video_rounded,
                        SchoolColors.primary,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMockMoreCard(
                        'Nhật ký',
                        Icons.book_rounded,
                        SchoolColors.orange,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SchoolButton.primary(
                  onPressed: () => Navigator.pop(ctx),
                  label: 'Đóng Bottom Sheet',
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockMoreCard(
      String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedScheduleView(bool isDark) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayDates = ['24', '25', '26', '27', '28', '29', '30'];
    final fullDayTitles = [
      'Thứ Hai, 24 tháng 8',
      'Thứ Ba, 25 tháng 8',
      'Thứ Tư, 26 tháng 8',
      'Thứ Năm, 27 tháng 8',
      'Thứ Sáu, 28 tháng 8',
      'Thứ Bảy, 29 tháng 8',
      'Chủ Nhật, 30 tháng 8',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Dropdown
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tháng 8 2026',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? SchoolColors.darkText : SchoolColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: SchoolColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_rounded, size: 14, color: SchoolColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Lịch của tôi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SchoolColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Day Strip
          Row(
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => setState(() => _simulatedScheduleDay = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _simulatedScheduleDay == i
                              ? SchoolColors.primary
                              : (i == 5
                                  ? SchoolColors.primary
                                      .withValues(alpha: isDark ? 0.2 : 0.1)
                                  : (isDark
                                      ? SchoolColors.darkSurface
                                      : Colors.white)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _simulatedScheduleDay == i
                                ? SchoolColors.primary
                                : (i == 5
                                    ? SchoolColors.primary.withValues(alpha: 0.5)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : SchoolColors.border)),
                          ),
                          boxShadow: _simulatedScheduleDay == i
                              ? [
                                  BoxShadow(
                                    color: SchoolColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              days[i],
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: _simulatedScheduleDay == i
                                    ? Colors.white
                                    : (isDark
                                        ? SchoolColors.darkMuted
                                        : SchoolColors.muted),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayDates[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _simulatedScheduleDay == i
                                    ? Colors.white
                                    : (isDark
                                        ? SchoolColors.darkText
                                        : SchoolColors.text),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (i % 2 == 0)
                                  Container(
                                    width: 3.5,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: _simulatedScheduleDay == i
                                          ? Colors.white
                                          : SchoolColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Day Title
          Row(
            children: [
              Expanded(
                child: Text(
                  fullDayTitles[_simulatedScheduleDay],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_simulatedScheduleDay == 5)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SchoolColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'HÔM NAY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: SchoolColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Simulated Lessons Cards
          if (_simulatedScheduleDay % 2 == 0) ...[
            _buildMockLessonCard(
              title: _isTeacherMode ? 'Toán học nâng cao' : 'Toán học',
              time: '08:00 – 08:45 (45 min)',
              clsName: 'Lớp 10A1 · 32 học sinh',
              room: 'Phòng 204',
              color: SchoolColors.primary,
              status: 'LIVE',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildMockLessonCard(
              title: _isTeacherMode ? 'Vật lý chuyên đề' : 'Vật lý',
              time: '09:00 – 09:45 (45 min)',
              clsName: 'Lớp 10A2 · 28 học sinh',
              room: 'Phòng 301',
              color: SchoolColors.orange,
              status: 'UPCOMING',
              isDark: isDark,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? SchoolColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : SchoolColors.border,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 36, color: SchoolColors.primary),
                  const SizedBox(height: 10),
                  const Text(
                    'Không có tiết học nào',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SchoolButton.primary(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '✨ Mở bảng Thêm tiết học cho ngày này!')),
                      );
                    },
                    size: SchoolButtonSize.sm,
                    icon: const Icon(Icons.add_rounded),
                    label: 'Thêm tiết học',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMockLessonCard({
    required String title,
    required String time,
    required String clsName,
    required String room,
    required Color color,
    required String status,
    required bool isDark,
  }) {
    return SchoolCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (status == 'LIVE')
                          const StatusChip(
                            label: 'LIVE',
                            color: SchoolColors.primary,
                            pulseDot: true,
                          )
                        else
                          const StatusChip(
                            label: 'UPCOMING',
                            color: SchoolColors.secondary,
                            icon: Icons.access_time_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clsName,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? SchoolColors.darkTextSecondary
                            : SchoolColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 13,
                            color: isDark
                                ? SchoolColors.darkMuted
                                : SchoolColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          room,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? SchoolColors.darkMuted
                                : SchoolColors.muted,
                          ),
                        ),
                      ],
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

  // ─────────────────────────────────────────────────────────────────
  // TAB 2: BUTTON DESIGN SYSTEM PLAYGROUND
  // ─────────────────────────────────────────────────────────────────
  Widget _buildButtonSystemTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Interactive Playground
          SchoolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎛️ Interactive Button Playground',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),

                // Variant selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SchoolButtonVariant.values.map((v) {
                    return ChoiceChip(
                      label: Text(v.name.toUpperCase()),
                      selected: _selectedVariant == v,
                      onSelected: (s) {
                        if (s) setState(() => _selectedVariant = v);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Size selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SchoolButtonSize.values.map((size) {
                    return ChoiceChip(
                      label: Text(
                          '${size.name.toUpperCase()} (${size.height.toInt()}px)'),
                      selected: _selectedSize == size,
                      onSelected: (s) {
                        if (s) setState(() => _selectedSize = size);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Switches
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    FilterChip(
                      label: const Text('isLoading'),
                      selected: _simulatedLoading,
                      onSelected: (s) => setState(() => _simulatedLoading = s),
                    ),
                    FilterChip(
                      label: const Text('isFullWidth'),
                      selected: _simulatedFullWidth,
                      onSelected: (s) =>
                          setState(() => _simulatedFullWidth = s),
                    ),
                    FilterChip(
                      label: const Text('leadingIcon'),
                      selected: _simulatedLeadingIcon,
                      onSelected: (s) =>
                          setState(() => _simulatedLeadingIcon = s),
                    ),
                    FilterChip(
                      label: const Text('trailingIcon'),
                      selected: _simulatedTrailingIcon,
                      onSelected: (s) =>
                          setState(() => _simulatedTrailingIcon = s),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Preview Area
                Center(
                  child: SchoolButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('⚡ Đã bấm nút SchoolButton!')),
                      );
                    },
                    label: 'Thực Hiện Hành Động',
                    variant: _selectedVariant,
                    size: _selectedSize,
                    isLoading: _simulatedLoading,
                    isFullWidth: _simulatedFullWidth,
                    icon: _simulatedLeadingIcon
                        ? const Icon(Icons.bolt_rounded)
                        : null,
                    trailingIcon: _simulatedTrailingIcon
                        ? const Icon(Icons.arrow_forward_rounded)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Icon Buttons Showcase
          SchoolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔲 SchoolIconButton Matrix (4 Kích Thước & 4 Biến Thể)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SchoolIconButton.filled(
                      icon: const Icon(Icons.video_call_rounded),
                      size: SchoolIconButtonSize.lg,
                      onPressed: () {},
                      tooltip: 'Filled LG',
                    ),
                    SchoolIconButton.tonal(
                      icon: const Icon(Icons.topic_outlined),
                      size: SchoolIconButtonSize.md,
                      onPressed: () {},
                      tooltip: 'Tonal MD',
                    ),
                    SchoolIconButton.standard(
                      icon: const Icon(Icons.search_rounded),
                      size: SchoolIconButtonSize.sm,
                      onPressed: () {},
                      tooltip: 'Standard SM',
                    ),
                    SchoolIconButton.destructive(
                      icon: const Icon(Icons.delete_outline_rounded),
                      size: SchoolIconButtonSize.xs,
                      onPressed: () {},
                      tooltip: 'Destructive XS',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dialog Action Group Preview
          SchoolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💬 Dialog Actions Standard (SchoolButtonGroup)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chuẩn hóa hai nút Hủy và Xác nhận với độ dài tự động co giãn và căn lề phải:',
                  style: TextStyle(fontSize: 13, color: SchoolColors.muted),
                ),
                const SizedBox(height: 16),
                SchoolButtonGroup.dialogActions(
                  cancel: SchoolButton.ghost(
                    onPressed: () {},
                    label: 'Hủy bỏ',
                  ),
                  confirm: SchoolButton.primary(
                    onPressed: () {},
                    label: 'Xác nhận tạo lớp',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 3: PAGE HEADER & RESPONSIVE LAYOUT
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPageHeaderTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SchoolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📱 Responsive PageHeader Demo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'PageHeader tự động nhận diện màn hình nhỏ (<600px) để co cỡ chữ từ 28px về 22px và căn lề 20px đồng bộ trục với toàn bộ giao diện:',
                  style: TextStyle(fontSize: 13, color: SchoolColors.muted),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? SchoolColors.darkSurfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                    ),
                  ),
                  child: PageHeader(
                    showBackButton: false,
                    title: 'Lịch Học & Bài Giảng Trực Tuyến',
                    subtitle: 'Học kỳ 1 · Lớp 10A1 Chuyên Toán',
                    classContext: '10A1 Chuyên Toán',
                    onClassContextTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đổi lớp học!')),
                      );
                    },
                    trailing: SchoolAddButton(
                      tooltip: 'Thêm tiết học',
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 4: MOBILE CHAT UX
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMobileChatTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SchoolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💬 Nâng Cấp Header Chat Mobile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Avatar lớp học được tăng từ 18px lên 34px sắc nét, tích hợp đa ngôn ngữ số thành viên và touch target tối thiểu 40x40px:',
                  style: TextStyle(fontSize: 13, color: SchoolColors.muted),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? SchoolColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18),
                        color: SchoolColors.primary,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.topic_outlined, size: 20),
                      ),
                      const SizedBox(width: 4),
                      ClassBadge(
                        name: 'Lớp 10A1',
                        color: SchoolColors.primary,
                        size: 34,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Lớp 10A1 Chuyên Toán',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '32 thành viên, trực tuyến',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? SchoolColors.darkMuted
                                    : SchoolColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.video_call_rounded, size: 22),
                        color: SchoolColors.primary,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert_rounded, size: 22),
                      ),
                    ],
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
