import 'package:school_world/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:school_world/l10n/app_localizations.dart';
import '../../main.dart';
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

    final animCtrl = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );
    final fadeAnim = useMemoized(
      () => CurvedAnimation(parent: animCtrl, curve: Curves.easeIn),
      [animCtrl],
    );
    final slideAnim = useMemoized(
      () => Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animCtrl,
              curve: const ElasticOutCurve(0.95),
            ),
          ),
      [animCtrl],
    );

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
          name:
              user.displayName ?? user.email?.split('@').first ?? l10n.student,
        );

        final result = await repo.joinClass(
          previewData.value!['classId'].toString(),
        );

        if (context.mounted) {
          AppScope.of(
            context,
          ).appState.selectClass(result['classId'].toString());
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
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
                  colors: [
                    SchoolColors.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppLayout.pagePadding(
                  context,
                ).copyWith(top: 24, bottom: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: SchoolColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: SchoolColors.primary.withValues(alpha: 0.15),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: SchoolColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.studentPortalTerm3.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: SchoolColors.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        l10n.joinYourFirstClass,
                        style: AppTextStyle.display(
                          context,
                        ).copyWith(fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.joinFirstClassDesc,
                        textAlign: TextAlign.justify,
                        style: AppTextStyle.bodyMd.copyWith(
                          color: isDark
                              ? SchoolColors.darkTextSecondary
                              : SchoolColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        l10n.inviteCode.toUpperCase(),
                        style: AppTextStyle.labelSm.copyWith(
                          color: isDark
                              ? SchoolColors.darkMuted
                              : SchoolColors.muted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(12)],
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: isDark ? Colors.white : SchoolColors.text,
                        ),
                        onChanged: (_) {
                          if (codeError.value != null) codeError.value = null;
                        },
                        decoration: InputDecoration(
                          hintText: 'ABCD-1234',
                          errorText: codeError.value,
                          prefixIcon: const Icon(
                            Icons.key_rounded,
                            size: 20,
                            color: SchoolColors.primary,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TactileSpringButton(
                        onTap: loading.value ? null : previewClass,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: SchoolColors.primary.withValues(
                                alpha: 0.4,
                              ),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: loading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: SchoolColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.previewClassAction,
                                      style: AppTextStyle.labelMd.copyWith(
                                        color: SchoolColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
                                  ClassBadge(
                                    name:
                                        previewData.value!['className']
                                            ?.toString() ??
                                        '?',
                                    color: SchoolColors.primary,
                                    size: 56,
                                    radius: 14,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          previewData.value!['className']
                                                  ?.toString() ??
                                              '',
                                          style: AppTextStyle.titleSm.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : SchoolColors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.teacherLabel(
                                            previewData.value!['teacherName']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          style: AppTextStyle.bodyMd.copyWith(
                                            fontSize: 13,
                                            color: isDark
                                                ? SchoolColors.darkTextSecondary
                                                : SchoolColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: SchoolColors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _TactileSpringButton(
                        onTap: (previewData.value == null || loading.value)
                            ? null
                            : joinClass,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: previewData.value != null
                                ? SchoolColors.primary
                                : (isDark
                                      ? SchoolColors.darkBorder
                                      : SchoolColors.border),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: previewData.value != null
                                ? [SchoolColors.cardShadowHover]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.joinClass.toUpperCase(),
                            style: AppTextStyle.labelMd.copyWith(
                              color: previewData.value != null
                                  ? Colors.white
                                  : SchoolColors.muted,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
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
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _isPressed ? 1.5 : 0.0, 0.0),
        child: Opacity(
          opacity: widget.onTap == null ? 0.5 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
