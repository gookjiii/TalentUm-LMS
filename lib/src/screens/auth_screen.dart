import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
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
  final _phoneController = TextEditingController(text: '+7');
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _isSignUp = false;
  bool _isPhoneMode = false;
  String _verificationId = '';
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
      body: LayoutBuilder(
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
                _phoneController.text = '+7';
                _otpController.clear();
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
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone == '+7') {
      _showMessage(_getEnterPhoneNumberFirstText(context));
      return;
    }

    setState(() => _loading = true);

    try {
      await AppScope.of(context).repository.verifyPhone(
        phoneNumber: phone,
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _loading = false;
          });
          _showMessage(_getOtpSentSuccessText(context));
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _loading = false);
          _showMessage(_friendlyError(e.message ?? e.toString()));
        },
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final cred = await FirebaseAuth.instance.signInWithCredential(
              credential,
            );
            await _onLoginSuccess(cred.user);
          } catch (e) {
            _showMessage(_friendlyError(e.toString()));
          } finally {
            setState(() => _loading = false);
          }
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      _showMessage(_friendlyError(e.toString()));
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      _showMessage(_getEnterOtpFirstText(context));
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await AppScope.of(context).repository
          .signInWithPhoneCredential(
            verificationId: _verificationId,
            smsCode: code,
          );
      await _onLoginSuccess(cred.user);
    } catch (e) {
      if (mounted) _showMessage(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onLoginSuccess(User? user) async {
    if (user == null) return;

    final repo = AppScope.of(context).repository;

    final doc = await repo.firestore.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (!doc.exists) {
      final nameController = TextEditingController();
      final submittedName = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(_getWelcomeOnboardingText(context)),
          content: TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.fullName,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_getEnterNameErrorText(context))),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.saveChanges1),
            ),
          ],
        ),
      );

      if (submittedName != null && submittedName.isNotEmpty) {
        await repo.createProfile(
          uid: user.uid,
          name: submittedName,
          role: 'student',
          email: user.email ?? user.phoneNumber ?? '',
        );
      }
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.pleaseEnterYourEmailAnd);
      return;
    }
    setState(() => _loading = true);
    try {
      await AppScope.of(context).repository.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (mounted) _showMessage(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.pleaseFillInAllFields);
      return;
    }
    setState(() => _loading = true);
    try {
      await AppScope.of(context).repository.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
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
    return AppLocalizations.of(context)!.somethingWentWrongTryAgain;
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
                        const Color(0xFF0B1120),
                        const Color(0xFF0E1928),
                        const Color(0xFF111827),
                      ]
                    : [
                        const Color(0xFFF0F5FF),
                        const Color(0xFFF8F7FF),
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
            color: SchoolColors.primary.withValues(alpha: isDark ? 0.15 : 0.10),
          ),
        ),
        Positioned(
          bottom: 60,
          left: -80,
          child: _DecorativeCircle(
            size: 200,
            color: SchoolColors.secondary.withValues(
              alpha: isDark ? 0.10 : 0.07,
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: child,
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
    return Row(
      children: [
        // Left hero panel
        Expanded(
          child: Container(
            height: double.infinity,
            padding: const EdgeInsets.all(56),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1D4ED8),
                  Color(0xFF2563EB),
                  Color(0xFF6366F1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Subtle circle decorations
                Positioned(
                  top: -40,
                  right: -40,
                  child: _DecorativeCircle(
                    size: 220,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: -60,
                  child: _DecorativeCircle(
                    size: 300,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                Positioned(
                  bottom: 160,
                  right: 20,
                  child: _DecorativeCircle(
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                // Hero content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SchoolLogo(size: 72),
                    const SizedBox(height: 32),
                    const Text(
                      'School\nWorld',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.singleClassForChatnfeedAnd,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 18,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _FeaturePills(),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Right form panel
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: form,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturePills extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.chat_bubble_outline_rounded,
        AppLocalizations.of(context)!.realtimeClassChat,
      ),
      (Icons.campaign_outlined, AppLocalizations.of(context)!.adsAndFeed),
      (
        Icons.assignment_outlined,
        AppLocalizations.of(context)!.assignmentsAndAssessments,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(f.$1, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 12),
              Text(
                f.$2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
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

    if (isPhoneMode) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: SchoolLogo(size: 72)),
          const SizedBox(height: 20),
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
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            _getLoginWithPhoneText(context),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? SchoolColors.darkTextSecondary
                  : SchoolColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.0,
            ),
          ),
          const SizedBox(height: 32),

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

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: SchoolColors.primary.withValues(
                    alpha: loading ? 0.0 : 0.35,
                  ),
                  blurRadius: loading ? 0 : 20,
                  offset: loading ? Offset.zero : const Offset(0, 6),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: loading ? null : (otpSent ? onVerifyOtp : onSendOtp),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            otpSent
                                ? Icons.verified_user_rounded
                                : Icons.send_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            otpSent
                                ? _getVerifyAndLoginText(context)
                                : _getSendOtpText(context),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextButton(
            onPressed: onTogglePhoneMode,
            child: Text(
              _getLoginWithEmailText(context),
              style: const TextStyle(
                color: SchoolColors.primary,
                fontWeight: FontWeight.w700,
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
        const Center(child: SchoolLogo(size: 72)),
        const SizedBox(height: 20),
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
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          isSignUp
              ? AppLocalizations.of(context)!.createAnAccount
              : AppLocalizations.of(context)!.welcomeBack,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? SchoolColors.darkTextSecondary
                : SchoolColors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.0,
          ),
        ),
        const SizedBox(height: 32),

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
                style: TextStyle(fontSize: 13),
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
        const SizedBox(height: 8),

        TextButton(
          onPressed: onTogglePhoneMode,
          child: Text(
            _getLoginWithPhoneText(context),
            style: const TextStyle(
              color: SchoolColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.isSignUp,
    required this.loading,
    required this.onSubmit,
  });

  final bool isSignUp;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: SchoolColors.primary.withValues(
              alpha: widget.loading ? 0.0 : 0.35,
            ),
            blurRadius: widget.loading ? 0 : 20,
            offset: widget.loading ? Offset.zero : const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: widget.loading ? null : widget.onSubmit,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: ValueKey('label_${widget.isSignUp}'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isSignUp
                          ? Icons.person_add_alt_1_rounded
                          : Icons.login_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isSignUp
                          ? AppLocalizations.of(context)!.createAnAccount
                          : AppLocalizations.of(context)!.login,
                    ),
                  ],
                ),
        ),
      ),
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
  if (locale == 'ru') return 'Войти';
  if (locale == 'vi') return 'Xác thực & Đăng nhập';
  return 'Verify & Login';
}

String _getLoginWithPhoneText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Войти по номеру телефона';
  if (locale == 'vi') return 'Đăng nhập bằng số điện thoại';
  return 'Login with phone';
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

String _getWelcomeOnboardingText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Добро пожаловать! Пожалуйста, введите ваше ФИО';
  if (locale == 'vi') return 'Chào mừng bạn! Vui lòng nhập Họ và tên của bạn';
  return 'Welcome! Please enter your Full Name';
}

String _getEnterNameErrorText(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ru') return 'Имя không được để trống';
  if (locale == 'vi') return 'Tên không được để trống';
  return 'Name cannot be empty';
}
