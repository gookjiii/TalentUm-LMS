import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';

import '../features/auth/domain/auth_profile_validation.dart';
import '../firebase/school_repository.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

/// Collects the minimum profile data that Firebase Auth does not provide for a
/// newly authenticated account (in particular, phone-based accounts).
///
/// The profile is initially created with the `pending` role. The regular
/// onboarding screen then promotes it to a student when the user joins a class
/// or sends a teacher access request. This keeps role selection intact while
/// making name/contact details reliable after OTP verification.
class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({
    required this.user,
    required this.repository,
    super.key,
  });

  final User user;
  final SchoolRepository repository;

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _submitting = false;
  bool _showValidation = false;
  String? _errorText;

  bool get _hasAuthEmail => widget.user.email?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phone = widget.user.phoneNumber;

    return Scaffold(
      backgroundColor: isDark ? SchoolColors.darkBg : const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SchoolCard(
                padding: const EdgeInsets.all(28),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: SchoolLogo(size: 64)),
                      const SizedBox(height: 24),
                      Text(
                        l10n.completeYourProfile,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: SchoolColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.completeYourProfileDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SchoolColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Semantics(
                          label: '${l10n.phone}: $phone',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: SchoolColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  color: SchoolColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: const TextStyle(
                                      color: SchoolColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        enabled: !_submitting,
                        autofocus: true,
                        autocorrect: true,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_showValidation || _errorText != null) {
                            setState(() {
                              _showValidation = false;
                              _errorText = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: l10n.fullName,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          errorText:
                              _showValidation &&
                                  normalizeDisplayName(
                                    _nameController.text,
                                  ).isEmpty
                              ? l10n.enterYourName
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailController,
                        enabled: !_submitting && !_hasAuthEmail,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_showValidation || _errorText != null) {
                            setState(() {
                              _showValidation = false;
                              _errorText = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: _hasAuthEmail
                              ? l10n.emailMail
                              : l10n.contactEmailOptional,
                          helperText: _hasAuthEmail
                              ? null
                              : l10n.phoneAccountEmailHint,
                          helperMaxLines: 3,
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText: _showValidation && _hasInvalidContactEmail
                              ? l10n.enterValidEmailOrLeaveBlank
                              : null,
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SchoolColors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: SchoolColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.saveAndContinue),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => widget.repository.signOut(),
                        child: Text(l10n.signOut),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasInvalidContactEmail {
    final email = normalizeOptionalEmail(_emailController.text);
    return email != null && !isValidEmailAddress(email);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = normalizeDisplayName(_nameController.text);
    final email = normalizeOptionalEmail(_emailController.text);
    final isValid =
        name.isNotEmpty && (email == null || isValidEmailAddress(email));
    if (!isValid) {
      setState(() {
        _showValidation = true;
        _errorText = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _showValidation = false;
      _errorText = null;
    });

    try {
      if (email != null &&
          !await widget.repository.isProfileEmailAvailable(
            email,
            excludeUserId: widget.user.uid,
          )) {
        if (mounted) setState(() => _errorText = l10n.profileEmailAlreadyInUse);
        return;
      }

      await widget.user.updateDisplayName(name);
      await widget.repository.createProfile(
        uid: widget.user.uid,
        name: name,
        role: 'pending',
        email: email,
        phone: widget.user.phoneNumber,
      );
    } catch (error) {
      debugPrint('Could not complete profile: $error');
      if (mounted) {
        setState(() => _errorText = l10n.somethingWentWrongTryAgain);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
