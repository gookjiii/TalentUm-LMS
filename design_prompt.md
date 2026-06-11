SYSTEM PROMPT: Nâng cấp Giao diện Flutter TalentUm (Elite Digital Campus)Vai trò của bạn: Bạn là một Chuyên gia Lập trình Flutter & UI/UX Designer.Nhiệm vụ: Nhiệm vụ của bạn là áp dụng toàn bộ bản nâng cấp UI/UX dưới đây vào dự án Flutter hiện tại. Dự án này sử dụng kiến trúc Riverpod, Flutter Hooks, và phong cách thiết kế Glassmorphism (Thủy tinh mờ), kết hợp với các hiệu ứng vật lý lò xo (Spring physics).BƯỚC 1: KIỂM TRA VÀ CẬP NHẬT DEPENDENCIESĐảm bảo tệp pubspec.yaml có các thư viện sau. Nếu chưa có, hãy thêm vào:dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  flutter_hooks: ^0.20.5
  google_fonts: ^6.2.1
BƯỚC 2: CẬP NHẬT MÀN HÌNH ONBOARDING (GIA NHẬP LỚP HỌC)Đường dẫn tệp: lib/src/screens/onboarding_screen.dartChỉ thị: Thay thế toàn bộ nội dung tệp cũ bằng mã nguồn dưới đây. Tệp mới sử dụng HookWidget để quản lý state và animation mượt mà hơn.import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:school_world/l10n/app_localizations.dart';
import '../../main.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

class OnboardingScreen extends HookWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final codeController = useTextEditingController();
    final previewData = useState<Map<String, dynamic>?>(null);
    final loading = useState<bool>(false);
    final codeError = useState<String?>(null);

    final animCtrl = useAnimationController(duration: const Duration(milliseconds: 500));
    final fadeAnim = useMemoized(() => CurvedAnimation(parent: animCtrl, curve: Curves.easeIn), [animCtrl]);
    final slideAnim = useMemoized(() => Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: animCtrl, curve: const ElasticOutCurve(0.95))), [animCtrl]);

    useEffect(() {
      if (previewData.value != null) animCtrl.forward(from: 0.0);
      return null;
    }, [previewData.value]);

    Future<void> previewClass() async {
      final code = codeController.text.trim();
      if (code.isEmpty) {
        codeError.value = l10n.enterInvitationCode;
        return;
      }
      loading.value = true;
      codeError.value = null;
      try {
        final repo = AppScope.of(context).repository;
        final data = await repo.validateInviteCode(code.toUpperCase());
        previewData.value = data;
      } catch (_) {
        codeError.value = l10n.codeNotFoundCheckAnd;
        previewData.value = null;
      } finally {
        loading.value = false;
      }
    }

    Future<void> joinClass() async {
      if (previewData.value == null) return;
      loading.value = true;
      try {
        final repo = AppScope.of(context).repository;
        final user = repo.auth.currentUser;
        if (user == null) return;

        await repo.createProfile(
          role: 'student',
          name: user.displayName ?? user.email?.split('@').first ?? l10n.student,
        );

        final result = await repo.joinClass(previewData.value!['classId'].toString());
        
        if (context.mounted) {
          AppScope.of(context).appState.selectClass(result['classId'].toString());
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        loading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? SchoolColors.darkBg : const Color(0xFFF9FAFC),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [SchoolColors.primary.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: SchoolColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: SchoolColors.primary.withValues(alpha: 0.15), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 13, color: SchoolColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              l10n.studentPortalTerm3.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: SchoolColors.primary, letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(l10n.joinYourFirstClass, style: AppTextStyle.display(context).copyWith(fontSize: 34, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Text(l10n.joinFirstClassDesc, style: AppTextStyle.bodyMd.copyWith(color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary, height: 1.55)),
                      const SizedBox(height: 36),
                      Text(l10n.inviteCode.toUpperCase(), style: AppTextStyle.labelSm.copyWith(color: isDark ? SchoolColors.darkMuted : SchoolColors.muted, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(12)],
                        style: GoogleFonts.jetBrainsMono(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4, color: isDark ? Colors.white : SchoolColors.text),
                        onChanged: (_) { if (codeError.value != null) codeError.value = null; },
                        decoration: InputDecoration(
                          hintText: 'ABCD-1234',
                          errorText: codeError.value,
                          prefixIcon: const Icon(Icons.key_rounded, size: 20, color: SchoolColors.primary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TactileSpringButton(
                        onTap: loading.value ? null : previewClass,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SchoolColors.primary.withValues(alpha: 0.4), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: loading.value
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search_rounded, size: 18, color: SchoolColors.primary),
                                    const SizedBox(width: 8),
                                    Text(l10n.previewClassAction, style: AppTextStyle.labelMd.copyWith(color: SchoolColors.primary, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        ),
                      ),
                      if (previewData.value != null) ...[
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: fadeAnim,
                          child: SlideTransition(
                            position: slideAnim,
                            child: GlassCard(
                              padding: const EdgeInsets.all(20),
                              borderRadius: 20,
                              child: Row(
                                children: [
                                  ClassBadge(name: previewData.value!['className']?.toString() ?? '?', color: SchoolColors.primary, size: 56, radius: 14),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(previewData.value!['className']?.toString() ?? '', style: AppTextStyle.titleSm.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : SchoolColors.text)),
                                        const SizedBox(height: 4),
                                        Text(l10n.teacherLabel(previewData.value!['teacherName']?.toString() ?? ''), style: AppTextStyle.bodyMd.copyWith(fontSize: 13, color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: SchoolColors.green, shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _TactileSpringButton(
                        onTap: (previewData.value == null || loading.value) ? null : joinClass,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: previewData.value != null ? SchoolColors.primary : (isDark ? SchoolColors.darkBorder : SchoolColors.border),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: previewData.value != null ? [SchoolColors.cardShadowHover] : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(l10n.joinClass.toUpperCase(), style: AppTextStyle.labelMd.copyWith(color: previewData.value != null ? Colors.white : SchoolColors.muted, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TactileSpringButton extends StatefulWidget {
  const _TactileSpringButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<_TactileSpringButton> createState() => _TactileSpringButtonState();
}
class _TactileSpringButtonState extends State<_TactileSpringButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _isPressed ? 1.5 : 0.0, 0.0),
        child: Opacity(opacity: widget.onTap == null ? 0.5 : 1.0, child: widget.child),
      ),
    );
  }
}
BƯỚC 3: CẬP NHẬT STUDENT SHELL VÀ BOTTOM TAB BARĐường dẫn tệp: lib/src/screens/student_shell.dartChỉ thị: Ghi đè phương thức cấu hình Bottom Navigation Bar cũ bằng UI Glassmorphism mới. Đảm bảo sử dụng StateProvider của Riverpod cho luồng điều hướng Tab.(Lưu ý cho AI: Do StudentShell gốc rất lớn, hãy tập trung ghi đè Class của Bottom Navigation Bar cũ thành lớp _ModernGlassTabBar bên dưới, và sử dụng HapticFeedback.selectionClick() cho các tương tác chạm).import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Thay thế cấu trúc BottomNavigationBar mặc định bằng ModernGlassTabBar
class ModernGlassTabBar extends StatelessWidget {
  const ModernGlassTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
    required this.onMoreTap,
    this.moreSelected = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<dynamic> items; // Định dạng danh sách NavDest
  final VoidCallback onMoreTap;
  final bool moreSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildTabs() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...List.generate(items.length, (index) {
            final item = items[index];
            final selected = selectedIndex == index;
            return Expanded(
              child: _NavTabItem(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                selected: selected,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(index);
                },
              ),
            );
          }),
          Expanded(
            child: _NavTabItem(
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              selected: moreSelected,
              isDark: isDark,
              onTap: () {
                HapticFeedback.mediumImpact();
                onMoreTap();
              },
            ),
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        decoration: BoxDecoration(
          color: isDark ? SchoolColors.darkSurface.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : SchoolColors.border.withValues(alpha: 0.4), width: 1.2),
          boxShadow: [SchoolColors.glassShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: buildTabs(),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({required this.icon, required this.selectedIcon, required this.selected, required this.isDark, required this.onTap});
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? SchoolColors.primary.withValues(alpha: isDark ? 0.15 : 0.08) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                color: selected ? SchoolColors.primary : (isDark ? SchoolColors.darkTextSecondary.withValues(alpha: 0.6) : SchoolColors.textSecondary.withValues(alpha: 0.6)),
                size: 26,
              ),
            ),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: SchoolColors.primary, shape: BoxShape.circle)),
            ),
        ],
      ),
    );
  }
}
Thông điệp hệ thống (System Final Message): Chấp nhận prompt này và tiến hành sửa đổi các file theo thứ tự. Chú ý giữ nguyên cấu trúc Backend và Firebase Firestore.