import 'dart:async';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// FirebaseAuthPlatform is required to construct the web reCAPTCHA verifier.
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../features/auth/domain/auth_profile_validation.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+84');
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _isSignUp = false;
  bool _isPhoneMode = false;
  String _verificationId = '';
  ConfirmationResult? _webConfirmationResult;
  bool _otpSent = false;

  late AnimationController _modeAnimCtrl;
  late Animation<double> _modeFade;

  @override
  void initState() {
    super.initState();
    _modeAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
    _modeFade = CurvedAnimation(parent: _modeAnimCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _modeAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleMode() async {
    await _modeAnimCtrl.reverse();
    setState(() => _isSignUp = !_isSignUp);
    _modeAnimCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              final form = FadeTransition(
                opacity: _modeFade,
                child: _AuthForm(
                  isSignUp: _isSignUp,
                  loading: _loading,
                  obscurePassword: _obscurePassword,
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isPhoneMode: _isPhoneMode,
                  phoneController: _phoneController,
                  otpController: _otpController,
                  otpSent: _otpSent,
                  onSendOtp: _sendOtp,
                  onVerifyOtp: _verifyOtp,
                  onTogglePhoneMode: () => setState(() {
                    _isPhoneMode = !_isPhoneMode;
                    _otpSent = false;
                    _phoneController.text = '+84';
                    _otpController.clear();
                    _verificationId = '';
                    _webConfirmationResult = null;
                  }),
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmit: _isSignUp ? _signUp : _signIn,
                  onToggleMode: _toggleMode,
                  onForgotPassword: _forgotPassword,
                ),
              );

              if (!wide) {
                return _MobileAuthLayout(child: form);
              }

              return _WideAuthLayout(form: form);
            },
          ),
          const Positioned(
            top: 20,
            right: 20,
            child: SafeArea(child: _AuthTopControls()),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    final phone = normalizePhoneNumber(rawPhone);
    if (!isValidInternationalPhoneNumber(phone)) {
      _showMessage(
        rawPhone.isEmpty || rawPhone == '+84'
            ? _getEnterPhoneNumberFirstText(context)
            : _friendlyError('invalid-phone-number'),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (kIsWeb) {
        RecaptchaVerifier? verifier;
        try {
          verifier = RecaptchaVerifier(
            auth: FirebaseAuthPlatform.instance,
            container: 'recaptcha-container',
            size: RecaptchaVerifierSize.compact,
            theme: RecaptchaVerifierTheme.dark,
          );
        } catch (_) {}

        final confirmation = await AppScope.of(context).repository
            .signInWithPhoneNumberWeb(phone, verifier: verifier)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('OTP request timed out');
              },
            );
        if (!mounted) return;
        setState(() {
          _webConfirmationResult = confirmation;
          _verificationId = confirmation.verificationId;
          _otpSent = true;
          _loading = false;
        });
        _showMessage(_getOtpSentSuccessText(context));
        return;
      }
      await AppScope.of(context).repository.verifyPhone(
        phoneNumber: phone,
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _loading = false;
          });
          _showMessage(_getOtpSentSuccessText(context));
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _loading = false);
          _showMessage(_friendlyError(e.message ?? e.toString()));
        },
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } catch (e) {
            if (mounted) _showMessage(_friendlyError(e.toString()));
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showMessage(_friendlyError(e.toString()));
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage(_getEnterOtpFirstText(context));
      return;
    }

    setState(() => _loading = true);

    try {
      if (kIsWeb && _webConfirmationResult == null) {
        throw FirebaseAuthException(
          code: 'session-expired',
          message: 'OTP session expired. Please request a new code.',
        );
      }
      if (kIsWeb) {
        await _webConfirmationResult!.confirm(code);
      } else {
        await AppScope.of(context).repository.signInWithPhoneCredential(
          verificationId: _verificationId,
          smsCode: code,
        );
      }
    } catch (e) {
      if (mounted) _showMessage(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    final email = normalizeOptionalEmail(_emailController.text);
    if (email == null || _passwordController.text.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.pleaseEnterYourEmailAnd);
      return;
    }
    if (!isValidEmailAddress(email)) {
      _showMessage(_getInvalidEmailText(context));
      return;
    }
    setState(() => _loading = true);
    try {
      await AppScope.of(
        context,
      ).repository.signInWithEmail(email, _passwordController.text);
    } catch (e) {
      if (mounted) _showMessage(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final name = normalizeDisplayName(_nameController.text);
    final email = normalizeOptionalEmail(_emailController.text);
    if (name.isEmpty || email == null || _passwordController.text.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.pleaseFillInAllFields);
      return;
    }
    if (!isValidEmailAddress(email)) {
      _showMessage(_getInvalidEmailText(context));
      return;
    }
    if (_passwordController.text.length < 6) {
      _showMessage(AppLocalizations.of(context)!.passwordIsTooWeakMinimum);
      return;
    }
    setState(() => _loading = true);
    try {
      await AppScope.of(
        context,
      ).repository.signUpWithEmail(email, _passwordController.text, name);
    } catch (e) {
      if (mounted) _showMessage(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.enterYourEmailToReset);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showMessage('Письмо для сброса пароля отправлено на $email');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted)
        _showMessage(
          e.message ?? AppLocalizations.of(context)!.passwordResetError,
        );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return AppLocalizations.of(context)!.invalidEmailOrPassword;
    }
    if (raw.contains('user-not-found'))
      return AppLocalizations.of(context)!.userNotFound;
    if (raw.contains('email-already-in-use')) {
      return AppLocalizations.of(context)!.thisEmailIsAlreadyRegistered;
    }
    if (raw.contains('weak-password')) {
      return AppLocalizations.of(context)!.passwordIsTooWeakMinimum;
    }
    if (raw.contains('network-request-failed'))
      return AppLocalizations.of(context)!.unknownKey15;
    if (raw.contains('invalid-phone-number')) {
      return _localizedAuthMessage(
        context,
        vi: 'Số điện thoại không hợp lệ. Hãy dùng định dạng quốc tế, ví dụ +84901234567.',
        ru: 'Неверный номер телефона. Используйте международный формат, например +79261234567.',
        en: 'Invalid phone number. Use international format, for example +84901234567.',
      );
    }
    if (raw.contains('invalid-verification-code')) {
      return _localizedAuthMessage(
        context,
        vi: 'Mã OTP không chính xác.',
        ru: 'Неверный код OTP.',
        en: 'The OTP code is invalid.',
      );
    }
    if (raw.contains('session-expired') || raw.contains('code-expired')) {
      return _localizedAuthMessage(
        context,
        vi: 'Phiên OTP đã hết hạn. Vui lòng gửi lại mã.',
        ru: 'Срок действия OTP истёк. Запросите новый код.',
        en: 'The OTP session expired. Request a new code.',
      );
    }
    if (raw.contains('too-many-requests') || raw.contains('quota-exceeded')) {
      return _localizedAuthMessage(
        context,
        vi: 'Đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.',
        ru: 'Слишком много запросов. Повторите попытку позже.',
        en: 'Too many requests. Please try again later.',
      );
    }
    if (raw.contains('timed out') || raw.contains('TimeoutException')) {
      return _localizedAuthMessage(
        context,
        vi: 'Hệ thống gửi mã OTP phản hồi chậm. Vui lòng thử lại.',
        ru: 'Время ожидания запроса OTP истекло. Попробуйте еще раз.',
        en: 'OTP request timed out. Please try again.',
      );
    }
    if (raw.contains('error-code:-39') ||
        raw.contains('-39') ||
        raw.contains('captcha-check-failed')) {
      return _localizedAuthMessage(
        context,
        vi: 'Xác minh reCAPTCHA không thành công hoặc tính năng Đăng nhập SĐT chưa được bật trên Firebase Console.',
        ru: 'Проверка reCAPTCHA не пройдена или вход по номеру телефона не включен в консоли Firebase.',
        en: 'reCAPTCHA verification failed or Phone Sign-in is not enabled in Firebase Console.',
      );
    }
    if (raw.contains('operation-not-allowed')) {
      return _localizedAuthMessage(
        context,
        vi: 'Tính năng đăng nhập SĐT chưa được bật trong Firebase Console.',
        ru: 'Вход по номеру телефона не включен в консоли Firebase.',
        en: 'Phone sign-in is not enabled in Firebase Console.',
      );
    }
    if (raw.contains('app-not-authorized')) {
      return _localizedAuthMessage(
        context,
        vi: 'Tên miền chưa được ủy quyền trong Firebase Console (Authorized Domains).',
        ru: 'Домен не авторизован в консоли Firebase (Authorized Domains).',
        en: 'Domain is not authorized in Firebase Console.',
      );
    }
    if (raw.contains('invalid-app-credential')) {
      return _localizedAuthMessage(
        context,
        vi: 'Lỗi xác thực App / reCAPTCHA. Vui lòng kiểm tra cấu hình Firebase.',
        ru: 'Ошибка проверки reCAPTCHA / App check. Проверьте настройки Firebase.',
        en: 'App credential / reCAPTCHA check failed. Check Firebase settings.',
      );
    }
    return raw.isNotEmpty
        ? raw
        : AppLocalizations.of(context)!.somethingWentWrongTryAgain;
  }
}

String _localizedAuthMessage(
  BuildContext context, {
  required String vi,
  required String ru,
  required String en,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'vi':
      return vi;
    case 'ru':
      return ru;
    default:
      return en;
  }
}

// ─────────────────────────────────────────────────────────────────
// MOBILE LAYOUT
// ─────────────────────────────────────────────────────────────────
class _MobileAuthLayout extends StatelessWidget {
  const _MobileAuthLayout({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Gradient background
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF090D16),
                        const Color(0xFF15102A),
                        const Color(0xFF0F172A),
                      ]
                    : [
                        const Color(0xFFF6F5FB),
                        const Color(0xFFECE7F6),
                        Colors.white,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          top: -80,
          right: -60,
          child: _DecorativeCircle(
            size: 260,
            color: SchoolColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
          ),
        ),
        Positioned(
          bottom: 60,
          left: -80,
          child: _DecorativeCircle(
            size: 200,
            color: SchoolColors.secondary.withValues(
              alpha: isDark ? 0.15 : 0.08,
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SchoolCard(
                  padding: const EdgeInsets.all(28),
                  borderRadius: 24,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDE (DESKTOP) LAYOUT
// ─────────────────────────────────────────────────────────────────
class _WideAuthLayout extends StatelessWidget {
  const _WideAuthLayout({required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Left hero panel
        Expanded(
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF070A14), // Ultra-deep space navy
                  Color(0xFF130D24), // Midnight amethyst
                  Color(0xFF261048), // Rich brand amethyst
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Ambient Radial Glow Orbs (Luminous aurora lighting)
                Positioned(
                  top: -120,
                  right: -80,
                  child: _DecorativeCircle(
                    size: 520,
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    centerColor: const Color(0xFFA855F7).withValues(alpha: 0.45),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -80,
                  child: _DecorativeCircle(
                    size: 460,
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                    centerColor: const Color(0xFF6366F1).withValues(alpha: 0.38),
                  ),
                ),
                Positioned(
                  top: 240,
                  right: -60,
                  child: _DecorativeCircle(
                    size: 340,
                    color: const Color(0xFFEC4899).withValues(alpha: 0.18),
                    centerColor: const Color(0xFFF43F5E).withValues(alpha: 0.24),
                  ),
                ),

                // Subtle Dot Grid overlay for high-end SaaS depth
                const Positioned.fill(child: _DotGridPattern()),

                // Hero content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Platform pill badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.14),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFBBF24),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFF78350F),
                                    size: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _localizedAuthMessage(
                                    context,
                                    vi: 'NỀN TẢNG HỌC TẬP THÔNG MINH',
                                    ru: 'ОБРАЗОВАТЕЛЬНАЯ ПЛАТФОРМА',
                                    en: 'SMART LEARNING PLATFORM',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Brand identity lockup: Squircle Logo + App Name + Live Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9333EA).withValues(alpha: 0.4),
                                      blurRadius: 26,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, -1),
                                    ),
                                  ],
                                ),
                                child: const SchoolLogo(size: 46),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                      streamFactory: () => AppScope.of(context)
                                          .repository
                                          .systemSettingsStream(),
                                      builder: (context, snapshot) {
                                        final appName =
                                            snapshot.data?.get('appName') as String? ?? 'TalentUm';
                                        return Text(
                                          appName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            height: 1.1,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1.2,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFF10B981),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _localizedAuthMessage(
                                            context,
                                            vi: 'Hệ thống trực tuyến v2.0',
                                            ru: 'Онлайн-портал v2.0',
                                            en: 'Cloud Portal v2.0',
                                          ),
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.75),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Slogan / Tagline
                          Text(
                            AppLocalizations.of(context)!
                                .singleClassForChatnfeedAnd
                                .replaceAll(r'\n', ' '),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 15.5,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Feature Showcase Cards
                          _FeatureShowcase(),
                          const SizedBox(height: 20),

                          // Social Proof & Trust Bar
                          const _SocialProofBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right form panel
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SchoolCard(
                  padding: const EdgeInsets.all(36),
                  borderRadius: 24,
                  child: form,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _FeatureCard(
          icon: Icons.forum_rounded,
          title: l10n.realtimeClassChat,
          desc: _localizedAuthMessage(
            context,
            vi: 'Trao đổi tức thì với giáo viên và các bạn trong lớp',
            ru: 'Мгновенное общение с учителями и одноклассниками',
            en: 'Instant discussions with teachers and classmates',
          ),
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          glowColor: const Color(0xFF8B5CF6),
        ),
        _FeatureCard(
          icon: Icons.campaign_rounded,
          title: l10n.adsAndFeed,
          desc: _localizedAuthMessage(
            context,
            vi: 'Bản tin thông báo, tài liệu & lịch học cập nhật',
            ru: 'Объявления класса, материалы и расписание',
            en: 'Class announcements, materials & schedule updates',
          ),
          gradientColors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
          glowColor: const Color(0xFFF59E0B),
        ),
        _FeatureCard(
          icon: Icons.task_alt_rounded,
          title: l10n.assignmentsAndAssessments,
          desc: _localizedAuthMessage(
            context,
            vi: 'Giao nộp bài tập, chấm điểm trực tiếp & kho tài liệu',
            ru: 'Сдача заданий, оценивание и библиотека материалов',
            en: 'Homework submissions, grading & digital library',
          ),
          gradientColors: const [Color(0xFF10B981), Color(0xFF06B6D4)],
          glowColor: const Color(0xFF10B981),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.gradientColors,
    required this.glowColor,
  });

  final IconData icon;
  final String title;
  final String desc;
  final List<Color> gradientColors;
  final Color glowColor;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: _isHovered ? 0.32 : 0.13),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withValues(alpha: _isHovered ? 0.25 : 0.06),
              blurRadius: _isHovered ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.desc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHovered ? 0.9 : 0.25,
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialProofBar extends StatelessWidget {
  const _SocialProofBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Avatar stack
          SizedBox(
            width: 72,
            height: 28,
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  child: _MiniAvatar(
                    gradient: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    icon: Icons.school_rounded,
                  ),
                ),
                const Positioned(
                  left: 18,
                  child: _MiniAvatar(
                    gradient: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                    icon: Icons.person_rounded,
                  ),
                ),
                const Positioned(
                  left: 36,
                  child: _MiniAvatar(
                    gradient: [Color(0xFF10B981), Color(0xFF06B6D4)],
                    icon: Icons.face_rounded,
                  ),
                ),
                Positioned(
                  left: 54,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        '+1k',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _localizedAuthMessage(
                    context,
                    vi: 'Được tin dùng bởi hơn 10.000+ học sinh & giáo viên',
                    ru: 'Более 10 000+ учеников и учителей по всей стране',
                    en: 'Trusted by 10,000+ teachers and students',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.gradient, required this.icon});
  final List<Color> gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({
    required this.size,
    required this.color,
    this.centerColor,
  });

  final double size;
  final Color color;
  final Color? centerColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              centerColor ?? color,
              color.withValues(alpha: 0.4),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

class _DotGridPattern extends StatelessWidget {
  const _DotGridPattern();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _DotGridPainter(),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    const spacing = 32.0;
    for (double x = 16; x < size.width; x += spacing) {
      for (double y = 16; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────
// AUTH FORM
// ─────────────────────────────────────────────────────────────────
class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.isSignUp,
    required this.loading,
    required this.obscurePassword,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isPhoneMode,
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onTogglePhoneMode,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onForgotPassword,
  });

  final bool isSignUp;
  final bool loading;
  final bool obscurePassword;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPhoneMode;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpSent;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onTogglePhoneMode;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isPhoneMode) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isWide) ...[
            const Center(child: SchoolLogo(size: 64)),
            const SizedBox(height: 16),
            CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              streamFactory: () =>
                  AppScope.of(context).repository.systemSettingsStream(),
              builder: (context, snapshot) {
                final appName =
                    snapshot.data?.get('appName') as String? ?? 'TalentUm';
                return Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          Text(
            _getLoginWithPhoneText(context),
            textAlign: isWide ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 26 : 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : SchoolColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _getPhoneAuthHintText(context),
            textAlign: isWide ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? SchoolColors.darkTextSecondary
                  : SchoolColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),

          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: otpSent
                ? TextInputAction.next
                : TextInputAction.done,
            enabled: !loading && !otpSent,
            onSubmitted: (_) {
              if (!otpSent) onSendOtp();
            },
            decoration: InputDecoration(
              labelText: _getPhoneText(context),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),

          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: otpSent
                ? Column(
                    children: [
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        enabled: !loading,
                        onSubmitted: (_) => onVerifyOtp(),
                        decoration: InputDecoration(
                          labelText: _getEnterOtpText(context),
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          SchoolButton.primary(
            label: otpSent
                ? _getVerifyAndLoginText(context)
                : _getSendOtpText(context),
            backgroundColor: SchoolColors.primary,
            icon: Icon(
              otpSent ? Icons.verified_user_rounded : Icons.send_rounded,
            ),
            isLoading: loading,
            isFullWidth: true,
            size: SchoolButtonSize.lg,
            onPressed: otpSent ? onVerifyOtp : onSendOtp,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _localizedAuthMessage(context, vi: 'HOẶC', ru: 'ИЛИ', en: 'OR'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white38 : SchoolColors.muted,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: onTogglePhoneMode,
            icon: const Icon(Icons.mail_outline_rounded, size: 18),
            label: Text(
              _getLoginWithEmailText(context),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : SchoolColors.text,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isWide) ...[
          const Center(child: SchoolLogo(size: 64)),
          const SizedBox(height: 16),
          CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            streamFactory: () =>
                AppScope.of(context).repository.systemSettingsStream(),
            builder: (context, snapshot) {
              final appName =
                  snapshot.data?.get('appName') as String? ?? 'TalentUm';
              return Text(
                appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        Text(
          isSignUp
              ? AppLocalizations.of(context)!.createAnAccount
              : AppLocalizations.of(context)!.welcomeBack,
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isWide ? 26 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : SchoolColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isSignUp
              ? _localizedAuthMessage(
                  context,
                  vi: 'Nhập thông tin bên dưới để tạo tài khoản mới của bạn',
                  ru: 'Введите свои данные для создания аккаунта',
                  en: 'Enter your details below to create your account',
                )
              : _localizedAuthMessage(
                  context,
                  vi: 'Vui lòng đăng nhập để tiếp tục vào lớp học',
                  ru: 'Войдите, чтобы продолжить обучение',
                  en: 'Please sign in to continue to your classroom',
                ),
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? SchoolColors.darkTextSecondary
                : SchoolColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),

        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          child: isSignUp
              ? Column(
                  children: [
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fullName,
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.emailMail,
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          onSubmitted: (_) => onSubmit(),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  key: ValueKey(obscurePassword),
                ),
              ),
              onPressed: onTogglePassword,
            ),
          ),
        ),

        if (!isSignUp) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)!.forgotYourPassword,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SchoolColors.primary,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),

        _SubmitButton(isSignUp: isSignUp, loading: loading, onSubmit: onSubmit),
        const SizedBox(height: 14),

        TextButton(
          onPressed: onToggleMode,
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
                TextSpan(
                  text: isSignUp
                      ? AppLocalizations.of(context)!.alreadyHaveAnAccount
                      : AppLocalizations.of(context)!.dontHaveAnAccount,
                ),
                TextSpan(
                  text: isSignUp
                      ? AppLocalizations.of(context)!.login
                      : AppLocalizations.of(context)!.register,
                  style: const TextStyle(
                    color: SchoolColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _localizedAuthMessage(context, vi: 'HOẶC', ru: 'ИЛИ', en: 'OR'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white38 : SchoolColors.muted,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        OutlinedButton.icon(
          onPressed: onTogglePhoneMode,
          icon: const Icon(Icons.phone_iphone_rounded, size: 18),
          label: Text(
            _getLoginWithPhoneText(context),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : SchoolColors.text,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSignUp,
    required this.loading,
    required this.onSubmit,
  });

  final bool isSignUp;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SchoolButton.primary(
      label: isSignUp
          ? AppLocalizations.of(context)!.createAnAccount
          : AppLocalizations.of(context)!.login,
      backgroundColor: SchoolColors.primary,
      icon: Icon(
        isSignUp ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
      ),
      isLoading: loading,
      isFullWidth: true,
      size: SchoolButtonSize.lg,
      onPressed: onSubmit,
    );
  }
}

String _getPhoneText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Номер телефона';
  if (locale == 'vi') return 'Số điện thoại';
  return 'Phone number';
}

String _getSendOtpText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Отправить OTP';
  if (locale == 'vi') return 'Gửi mã OTP';
  return 'Send OTP';
}

String _getEnterOtpText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Введите код OTP';
  if (locale == 'vi') return 'Nhập mã OTP';
  return 'Enter OTP Code';
}

String _getVerifyAndLoginText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Подтвердить и продолжить';
  if (locale == 'vi') return 'Xác nhận & Tiếp tục';
  return 'Verify & continue';
}

String _getLoginWithPhoneText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Продолжить по номеру телефона';
  if (locale == 'vi') return 'Tiếp tục bằng số điện thoại';
  return 'Continue with phone';
}

String _getPhoneAuthHintText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') {
    return 'Для нового аккаунта после OTP потребуется только имя.';
  }
  if (locale == 'vi') {
    return 'Tài khoản mới chỉ cần nhập tên sau khi xác thực OTP.';
  }
  return 'New accounts only need a name after OTP verification.';
}

String _getLoginWithEmailText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Войти по Email';
  if (locale == 'vi') return 'Đăng nhập bằng Email';
  return 'Login with email';
}

String _getEnterPhoneNumberFirstText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Пожалуйста, введите номер телефона';
  if (locale == 'vi') return 'Vui lòng nhập số điện thoại trước';
  return 'Please enter phone number first';
}

String _getEnterOtpFirstText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Пожалуйста, введите код OTP';
  if (locale == 'vi') return 'Vui lòng nhập mã OTP';
  return 'Please enter OTP code';
}

String _getOtpSentSuccessText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'OTP код отправлен!';
  if (locale == 'vi') return 'Mã OTP đã được gửi thành công!';
  return 'OTP code sent successfully!';
}

String _getInvalidEmailText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Введите корректный email.';
  if (locale == 'vi') return 'Vui lòng nhập email hợp lệ.';
  return 'Enter a valid email address.';
}

class _AuthTopControls extends StatelessWidget {
  const _AuthTopControls();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context).appState;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocaleCode = appState.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? SchoolColors.darkSurfaceElevated.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Language / Язык',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: isDark ? SchoolColors.darkSurfaceElevated : Colors.white,
            elevation: 8,
            onSelected: (code) {
              appState.setLocale(Locale(code));
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (currentLocaleCode == 'en')
                      const Icon(Icons.check_rounded, size: 18, color: SchoolColors.primary),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ru',
                child: Row(
                  children: [
                    const Text('🇷🇺', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    const Text('Русский', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (currentLocaleCode == 'ru')
                      const Icon(Icons.check_rounded, size: 18, color: SchoolColors.primary),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentLocaleCode == 'ru' ? '🇷🇺' : '🇬🇧',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentLocaleCode == 'ru' ? 'RU' : 'EN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : SchoolColors.text,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isDark ? Colors.white70 : SchoolColors.muted,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 18,
            width: 1,
            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 18,
              color: isDark ? const Color(0xFFFBBF24) : SchoolColors.primary,
            ),
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            splashRadius: 18,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: () => appState.toggleDarkMode(),
          ),
        ],
      ),
    );
  }
}

