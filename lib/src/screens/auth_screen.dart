import 'package:school_world/src/theme.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
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
      backgroundColor: Colors.transparent,
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
    return _AnimatedMeshBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppLayout.pagePadding(
              context,
            ).copyWith(top: 28, bottom: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: NestedBezelCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: child,
              ),
            ),
          ),
        ),
      ),
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
    return _AnimatedMeshBackground(
      child: Row(
        children: [
          // Left hero panel
          Expanded(
            child: Container(
              height: double.infinity,
              padding: AppLayout.pagePadding(
                context,
              ).copyWith(top: 56, bottom: 56),
              child: Stack(
                children: [
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
                padding: AppLayout.pagePadding(
                  context,
                ).copyWith(top: 48, bottom: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: NestedBezelCard(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                    child: form,
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

            Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                ),
              ),
              child: TextField(
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
                  labelStyle: TextStyle(
                    color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                  ),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          const SizedBox(height: 14),

          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: otpSent
                ? Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          ),
                        ),
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          enabled: !loading,
                          onSubmitted: (_) => onVerifyOtp(),
                          decoration: InputDecoration(
                            labelText: _getEnterOtpText(context),
                            labelStyle: TextStyle(
                              color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_clock_outlined,
                              color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
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
                    Container(
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        ),
                      ),
                      child: TextField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.fullName,
                          labelStyle: TextStyle(
                            color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.emailMail,
              labelStyle: TextStyle(
                color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            onSubmitted: (_) => onSubmit(),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              labelStyle: TextStyle(
                color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(obscurePassword),
                    color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                  ),
                ),
                onPressed: onTogglePassword,
              ),
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

        if (!isSignUp) ...[
          const _BiometricButton(),
          const SizedBox(height: 14),
        ],

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

class _AnimatedMeshBackground extends StatefulWidget {
  const _AnimatedMeshBackground({required this.child});
  final Widget child;

  @override
  State<_AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<_AnimatedMeshBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                -0.5 + _controller.value,
                -0.5 + (_controller.value * 0.5),
              ),
              radius: 1.5,
              colors: isDark ? const [
                Color(0xFF7C3AED),
                Color(0xFF0F172A),
                Color(0xFF000000),
              ] : const [
                Color(0xFF7C3AED),
                Color(0xFFE2E8F0),
                Color(0xFFFFFFFF),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _BiometricButton extends StatefulWidget {
  const _BiometricButton();

  @override
  State<_BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends State<_BiometricButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.forward();
    // Biometric mock action
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric authentication initiated...')),
    );
  }

  void _onTapCancel() {
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scaleController,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SchoolColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.fingerprint_rounded,
                color: SchoolColors.primary,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Face ID / Fingerprint',
                style: TextStyle(
                  color: SchoolColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
