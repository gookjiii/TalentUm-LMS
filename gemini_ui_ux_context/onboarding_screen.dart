import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';

import '../../main.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  Map<String, dynamic>? _previewData;
  bool _loading = false;
  String? _codeError;

  late AnimationController _previewAnimCtrl;
  late Animation<double> _previewOpacity;
  late Animation<Offset> _previewSlide;

  @override
  void initState() {
    super.initState();
    _previewAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _previewOpacity = CurvedAnimation(
      parent: _previewAnimCtrl,
      curve: Curves.easeOut,
    );
    _previewSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _previewAnimCtrl, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _previewAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SchoolColors.darkBg : const Color(0xFFF5F7FF),
      body: Stack(
        children: [
          // Decorative background blobs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SchoolColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SchoolColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Pill label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: SchoolColors.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.school_rounded,
                                size: 15,
                                color: SchoolColors.primary,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                l10n.studentPortalTerm3,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: SchoolColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.joinYourFirstClass,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.joinFirstClassDesc,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? SchoolColors.darkTextSecondary
                              : SchoolColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Invite code field
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                        onChanged: (_) {
                          if (_codeError != null) {
                            setState(() => _codeError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: l10n.inviteCode,
                          hintText: 'ABC123',
                          prefixIcon: const Icon(
                            Icons.key_rounded,
                            color: SchoolColors.primary,
                          ),
                          errorText: _codeError,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Preview button
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _previewClass,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: SchoolColors.primary,
                            width: 1.5,
                          ),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(l10n.previewClassAction),
                      ),

                      // Animated class preview card
                      if (_previewData != null) ...[
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _previewOpacity,
                          child: SlideTransition(
                            position: _previewSlide,
                            child: _ClassPreviewCard(data: _previewData!),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Join button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: SchoolColors.primary.withValues(
                                alpha: (_previewData != null && !_loading) ? 0.3 : 0.0,
                              ),
                              blurRadius: (_previewData != null && !_loading) ? 20 : 0,
                              offset: (_previewData != null && !_loading)
                                  ? const Offset(0, 6)
                                  : Offset.zero,
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          onPressed: (_previewData == null || _loading)
                              ? null
                              : _onJoinClass,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(l10n.joinClass),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Teacher link
                      TextButton(
                        onPressed: _createTeacherProfile,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? SchoolColors.darkTextSecondary
                                  : SchoolColors.textSecondary,
                            ),
                            children: [
                              TextSpan(text: AppLocalizations.of(context)!.areYouATeacher),
                              TextSpan(
                                text: AppLocalizations.of(context)!.loginAsTeacher,
                                style: TextStyle(
                                  color: SchoolColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Future<void> _previewClass() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = AppLocalizations.of(context)!.enterInvitationCode);
      return;
    }
    setState(() {
      _loading = true;
      _codeError = null;
    });
    try {
      final data = await AppScope.of(
        context,
      ).repository.validateInviteCode(code.toUpperCase());
      setState(() => _previewData = data);
      _previewAnimCtrl.forward(from: 0);
    } catch (_) {
      setState(
        () => _codeError = AppLocalizations.of(context)!.codeNotFoundCheckAnd,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onJoinClass() async {
    if (_previewData == null) return;
    setState(() => _loading = true);
    try {
      final repo = AppScope.of(context).repository;
      final user = repo.auth.currentUser;
      if (user == null) {
        _showMessage(AppLocalizations.of(context)!.pleaseLoginFirst);
        return;
      }
      await repo.createProfile(
        role: 'student',
        name: user.displayName ?? user.email?.split('@').first ?? AppLocalizations.of(context)!.student,
      );
      final result = await repo.joinClass(_previewData!['classId'].toString());
      if (mounted) {
        AppScope.of(context).appState.selectClass(result['classId'].toString());
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTeacherProfile() async {
    setState(() => _loading = true);
    try {
      final repo = AppScope.of(context).repository;
      final user = repo.auth.currentUser;
      if (user == null) {
        _showMessage(AppLocalizations.of(context)!.pleaseLoginFirst);
        return;
      }
      await repo.createProfile(
        role: 'teacher',
        name: user.displayName ?? user.email?.split('@').first ?? AppLocalizations.of(context)!.teacher,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ─────────────────────────────────────────────────────────────────
// CLASS PREVIEW CARD
// ─────────────────────────────────────────────────────────────────
class _ClassPreviewCard extends StatelessWidget {
  const _ClassPreviewCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final className = data['className'] as String? ?? '';
    final teacherName = data['teacherName']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? [const Color(0xFF062017), const Color(0xFF0B2B20)]
        : [SchoolColors.greenContainer, SchoolColors.accentContainer];
    final borderCol = isDark
        ? const Color(0xFF154C34)
        : SchoolColors.green.withValues(alpha: 0.25);
    final textCol = isDark ? SchoolColors.darkText : SchoolColors.text;
    final secTextCol = isDark
        ? SchoolColors.darkTextSecondary
        : SchoolColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: SchoolColors.green.withValues(alpha: isDark ? 0.05 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Class initial badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SchoolColors.primary, SchoolColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: SchoolColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              className.isNotEmpty ? className[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.teacherLabel(teacherName),
                  style: TextStyle(
                    fontSize: 13,
                    color: secTextCol,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SchoolColors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SchoolColors.green.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
