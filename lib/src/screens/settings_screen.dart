import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'teacher_access_card.dart';
import '../app_state.dart';
import '../firebase/school_repository.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';
import '../config/app_version.dart';
import '../utils/reload_app.dart';
import '../../main.dart';
import '../features/settings/presentation/widgets/settings_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.appState,
    this.onBack,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;
  final VoidCallback? onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final file = result.files.first;
      final repo = widget.repository;
      final uid = repo.uid;
      if (uid == null) throw Exception('Not logged in');

      final path =
          'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      String? avatarUrl;
      if (file.bytes != null) {
        avatarUrl = await repo.updateCurrentUserAvatarFromBytes(
          path,
          file.bytes!,
        );
      } else if (file.path != null) {
        avatarUrl = await repo.updateCurrentUserAvatarFromFile(
          path,
          File(file.path!),
        );
      }

      if (avatarUrl != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.avatarUpdated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.uploadError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text =
        widget.repository.auth.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getAccentColorName(Color color, bool isRu) {
    final val = color.value;
    if (val == const Color(0xFF2563EB).value) {
      return isRu ? AppLocalizations.of(context)!.schoolBlue : 'School blue';
    } else if (val == const Color(0xFF059669).value) {
      return isRu ? AppLocalizations.of(context)!.emerald : 'Emerald';
    } else if (val == const Color(0xFFF59E0B).value) {
      return isRu ? AppLocalizations.of(context)!.amber : 'Amber';
    } else if (val == const Color(0xFFDC2626).value) {
      return isRu ? AppLocalizations.of(context)!.scarlet : 'Crimson';
    } else if (val == const Color(0xFF7C3AED).value) {
      return isRu ? AppLocalizations.of(context)!.violet : 'Purple';
    }
    return isRu ? AppLocalizations.of(context)!.schoolBlue : 'School blue';
  }

  Widget _buildColorDot(Color color, bool isDark) {
    final isSelected = widget.appState.accentColor.value == color.value;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          widget.appState.setAccentColor(color);
          Future.delayed(const Duration(milliseconds: 250), () {
            reloadApp();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: isDark ? Colors.white : Colors.black87,
                  width: 2,
                )
              : Border.all(color: Colors.transparent, width: 0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
            : null,
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.language,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Divider(
                color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
              ),
              _LanguageTile(
                flag: '🇬🇧',
                label: l10n.english,
                sublabel: 'English',
                selected:
                    widget.appState.locale?.languageCode == 'en' ||
                    (widget.appState.locale == null &&
                        Localizations.localeOf(context).languageCode == 'en'),
                onTap: () {
                  widget.appState.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              Divider(
                color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                indent: 56,
              ),
              _LanguageTile(
                flag: '🇷🇺',
                label: l10n.russian,
                sublabel: AppLocalizations.of(context)!.russian,
                selected:
                    widget.appState.locale?.languageCode == 'ru' ||
                    (widget.appState.locale == null &&
                        Localizations.localeOf(context).languageCode == 'ru'),
                onTap: () {
                  widget.appState.setLocale(const Locale('ru'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppLocalizations.of(context) == null) {
      // Keep the profile route safe while MaterialApp is resolving its locale.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final isDark = widget.appState.isDarkMode;
        final isRu = Localizations.localeOf(context).languageCode == 'ru';

        // Localized labels matching screenshot
        final notificationsLabel = isRu
            ? AppLocalizations.of(context)!.notifications
            : 'Notifications';
        final pushNotificationsLabel = isRu
            ? AppLocalizations.of(context)!.pushNotifications
            : 'Push notifications';
        final pushNotificationsSub = isRu
            ? AppLocalizations.of(context)!.allowedForChatAndTasks
            : 'Allowed for chat and assignments';
        final newMessagesLabel = isRu
            ? AppLocalizations.of(context)!.newMessages
            : 'New messages';
        final newMessagesSub = isRu
            ? AppLocalizations.of(context)!.soundVibration
            : 'Sound + vibration';
        final updatesLabel = isRu
            ? AppLocalizations.of(context)!.updates
            : 'Updates';
        final updatesSub = isRu
            ? AppLocalizations.of(context)!.quietMode22000700
            : 'Quiet mode: 22:00–07:00';

        final appearanceLabel = isRu
            ? AppLocalizations.of(context)!.registration
            : 'Appearance';
        final darkThemeLabel = isRu
            ? AppLocalizations.of(context)!.darkTheme
            : 'Dark theme';
        final darkThemeSub = isRu
            ? AppLocalizations.of(context)!.system
            : 'System';
        final accentColorLabel = isRu
            ? AppLocalizations.of(context)!.accentColor
            : 'Accent color';
        final languageLabel = isRu
            ? AppLocalizations.of(context)!.language
            : 'Language';
        final activeLanguageSub = widget.appState.locale?.languageCode == 'en'
            ? 'English (en)'
            : AppLocalizations.of(context)!.russianRu;
        final performanceLabel = isRu
            ? 'Режим высокой производительности'
            : 'High Performance Mode';
        final performanceSub = isRu
            ? 'Отключить эффекты размытия для слабых устройств'
            : 'Disable blur effects for low-end devices';

        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // Embedded Settings is controlled by the shell's bottom
                  // navigation. Only standalone routes need their own back
                  // action.
                  if (widget.onBack == null && Navigator.of(context).canPop())
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(l10n.back),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  PageHeader(
                    title: l10n.settings,
                    subtitle: l10n.personalizationAndAccountManagement,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                  ),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: widget.repository.userDocStream(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() ?? {};
                      final role = data['role']?.toString().toLowerCase();
                      final isStudent = role == 'student';
                      final isParent = role == 'parent';
                      final currentName =
                          data['name'] as String? ??
                          widget.repository.auth.currentUser?.displayName ??
                          (isParent ? l10n.parent : l10n.student);
                      final avatarUrl = data['avatarUrl']?.toString();
                      final rawClassIds = data['classIds'];
                      final classCount = rawClassIds is Iterable
                          ? rawClassIds.length
                          : 0;
                      final roleLabel = isParent
                          ? l10n.parent
                          : isStudent
                          ? l10n.student
                          : l10n.student;
                      final school = data['school']?.toString().trim();
                      final subtitle = [
                        roleLabel,
                        if (school != null && school.isNotEmpty) school,
                      ].join(' · ');

                      if (_nameController.text.isEmpty &&
                          currentName.isNotEmpty) {
                        _nameController.text = currentName;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SettingsProfileCard(
                            name: currentName,
                            avatarUrl: avatarUrl,
                            sub: subtitle,
                            countLabel:
                                '$classCount ${l10n.classes.toLowerCase()}',
                            verifiedLabel: l10n.verified,
                            roleColor: widget.appState.accentColor,
                            onEditAvatar: _uploadingAvatar
                                ? null
                                : () => _pickAndUploadAvatar(context),
                          ),
                          const SizedBox(height: 12),
                          SettingsGroup(
                            label: l10n.studentAccount,
                            children: [
                              SettingsRow(
                                icon: Icons.person_outline_rounded,
                                color: SchoolColors.primary,
                                label: l10n.personalInformation,
                                sub: currentName,
                                onTap: () => _editName(context, currentName),
                              ),
                              SettingsRow(
                                icon: Icons.email_outlined,
                                color: SchoolColors.yellow,
                                label: l10n.email,
                                sub:
                                    widget.repository.auth.currentUser?.email ??
                                    '',
                                onTap: () => _showEmailNotice(context, l10n),
                              ),
                              SettingsRow(
                                icon: Icons.link_rounded,
                                color: SchoolColors.accent,
                                label: l10n.linkedAccounts,
                                sub: 'Google · Apple',
                                onTap: () => _showLinkedAccounts(context),
                                last: true,
                              ),
                            ],
                          ),
                          if (isStudent) ...[
                            SettingsGroup(
                              label: isRu
                                  ? l10n.academicPerformanceAndSubjects
                                  : 'Academics',
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: _StatsRow(data: data, l10n: l10n),
                                ),
                              ],
                            ),
                            SettingsGroup(
                              label: l10n.linkingCode,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: _LinkingCard(
                                    email:
                                        widget
                                            .repository
                                            .auth
                                            .currentUser
                                            ?.email ??
                                        '',
                                    l10n: l10n,
                                  ),
                                ),
                              ],
                            ),
                            _ParentLinkRequestsCard(
                              repository: widget.repository,
                            ),
                            const SizedBox(height: 8),
                            const TeacherAccessCard(),
                          ],
                        ],
                      );
                    },
                  ),

                  SettingsGroup(
                    label: notificationsLabel,
                    children: [
                      SettingsRow(
                        icon: Icons.notifications_none_rounded,
                        color: SchoolColors.red,
                        label: pushNotificationsLabel,
                        sub: pushNotificationsSub,
                        right: Switch.adaptive(
                          value: widget.appState.pushNotifications,
                          onChanged: widget.appState.setPushNotifications,
                          activeColor: widget.appState.accentColor,
                        ),
                        onTap: () => widget.appState.setPushNotifications(
                          !widget.appState.pushNotifications,
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        color: SchoolColors.primary,
                        label: newMessagesLabel,
                        sub: newMessagesSub,
                        right: Switch.adaptive(
                          value: widget.appState.soundAndVibe,
                          onChanged: widget.appState.setSoundAndVibe,
                          activeColor: widget.appState.accentColor,
                        ),
                        onTap: () => widget.appState.setSoundAndVibe(
                          !widget.appState.soundAndVibe,
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.push_pin_outlined,
                        color: SchoolColors.yellow,
                        label: updatesLabel,
                        sub: updatesSub,
                        right: Switch.adaptive(
                          value: widget.appState.quietModeUpdates,
                          onChanged: widget.appState.setQuietModeUpdates,
                          activeColor: widget.appState.accentColor,
                        ),
                        onTap: () => widget.appState.setQuietModeUpdates(
                          !widget.appState.quietModeUpdates,
                        ),
                        last: true,
                      ),
                    ],
                  ),

                  SettingsGroup(
                    label: appearanceLabel,
                    children: [
                      SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        color: SchoolColors.accent,
                        label: darkThemeLabel,
                        sub: darkThemeSub,
                        right: Switch.adaptive(
                          value: isDark,
                          onChanged: (_) => widget.appState.toggleDarkMode(),
                          activeColor: widget.appState.accentColor,
                        ),
                        onTap: () => widget.appState.toggleDarkMode(),
                      ),
                      SettingsRow(
                        icon: Icons.palette_outlined,
                        color: SchoolColors.primary,
                        label: accentColorLabel,
                        sub: _getAccentColorName(
                          widget.appState.accentColor,
                          isRu,
                        ),
                        right: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildColorDot(const Color(0xFF2563EB), isDark),
                            const SizedBox(width: 8),
                            _buildColorDot(const Color(0xFF059669), isDark),
                            const SizedBox(width: 8),
                            _buildColorDot(const Color(0xFFF59E0B), isDark),
                            const SizedBox(width: 8),
                            _buildColorDot(const Color(0xFFDC2626), isDark),
                          ],
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.language_rounded,
                        color: SchoolColors.green,
                        label: languageLabel,
                        sub: activeLanguageSub,
                        onTap: () => _showLanguagePicker(context, l10n),
                      ),
                      SettingsRow(
                        icon: Icons.speed_rounded,
                        color: SchoolColors.yellow,
                        label: performanceLabel,
                        sub: performanceSub,
                        right: Switch.adaptive(
                          value: widget.appState.performanceMode,
                          onChanged: widget.appState.setPerformanceMode,
                          activeColor: widget.appState.accentColor,
                        ),
                        onTap: () => widget.appState.setPerformanceMode(
                          !widget.appState.performanceMode,
                        ),
                        last: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── About section ───────────────────────────────────
                  _SectionLabel(
                    label: isRu
                        ? AppLocalizations.of(context)!.aboutTheApplication
                        : 'About',
                  ),
                  SchoolCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _InfoTile(
                          icon: Icons.info_outline_rounded,
                          label: isRu
                              ? AppLocalizations.of(context)!.version
                              : 'Version',
                          trailing: kAppVersion,
                        ),
                        Divider(
                          height: 1,
                          color: isDark
                              ? SchoolColors.darkBorder
                              : SchoolColors.border,
                          indent: 56,
                        ),
                        _InfoTile(
                          icon: Icons.school_outlined,
                          label: 'School World',
                          trailing: 'edu platform',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Danger zone ─────────────────────────────────────
                  _SectionLabel(
                    label: isRu
                        ? AppLocalizations.of(context)!.dangerZone
                        : 'Danger Zone',
                    color: SchoolColors.red,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SchoolColors.red.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Material(
                        color: isDark
                            ? SchoolColors.red.withValues(alpha: 0.06)
                            : SchoolColors.redContainer.withValues(alpha: 0.4),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: SchoolColors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: SchoolColors.red,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            l10n.signOut,
                            style: const TextStyle(
                              color: SchoolColors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            isRu
                                ? AppLocalizations.of(
                                    context,
                                  )!.youWillBeRedirectedTo
                                : 'You will be redirected to the sign in screen',
                            style: TextStyle(
                              color: SchoolColors.red.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => _signOut(context, l10n),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveName(BuildContext context, AppLocalizations l10n) async {
    try {
      await widget.repository.updateProfileName(_nameController.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

  Future<void> _editName(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: current);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editProfile),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (shouldSave != true || name.isEmpty || !context.mounted) return;

    try {
      await widget.repository.updateProfile(
        name: name,
        firstName: name.split(RegExp(r'\s+')).first,
        lastName: '',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

  void _showLinkedAccounts(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final providers =
        widget.repository.auth.currentUser?.providerData
            .map((provider) => provider.providerId)
            .toSet() ??
        <String>{};
    final entries = <(String, String)>[
      ('Google', 'google.com'),
      ('Apple', 'apple.com'),
      (l10n.emailpassword, 'password'),
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.linkedAccounts),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  entry.$2 == 'google.com'
                      ? Icons.g_mobiledata_rounded
                      : entry.$2 == 'apple.com'
                      ? Icons.apple_rounded
                      : Icons.email_outlined,
                ),
                title: Text(entry.$1),
                trailing: StatusChip(
                  label: providers.contains(entry.$2)
                      ? l10n.related
                      : l10n.notRelated,
                  color: providers.contains(entry.$2)
                      ? SchoolColors.green
                      : SchoolColors.muted,
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.ready),
          ),
        ],
      ),
    );
  }

  void _showEmailNotice(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.contactSupportForEmail)));
  }

  Future<void> _signOut(BuildContext context, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.confirmSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: SchoolColors.red,
              minimumSize: const Size(100, 44),
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirm == true) {
      widget.appState.resetSession();
      await widget.repository.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

class _ParentLinkRequestsCard extends StatelessWidget {
  const _ParentLinkRequestsCard({required this.repository});

  final SchoolRepository repository;

  Future<void> _respond(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> request,
    bool approved,
  ) async {
    final studentId = repository.uid;
    final parentId = request.data()['parentId']?.toString();
    if (studentId == null || parentId == null || parentId.isEmpty) return;

    final batch = repository.firestore.batch();
    if (approved) {
      batch.set(
        repository.firestore.collection('users').doc(parentId),
        {
          'childIds': FieldValue.arrayUnion([studentId]),
        },
        SetOptions(merge: true),
      );
    }
    batch.update(request.reference, {
      'status': approved ? 'approved' : 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved ? 'Parent linked successfully' : 'Request rejected',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentId = repository.uid;
    if (studentId == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.firestore
          .collection('parent_link_requests')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        final requests = (snapshot.data?.docs ?? const [])
            .where((doc) => doc.data()['status'] == 'pending')
            .toList();
        if (requests.isEmpty) return const SizedBox.shrink();
        return SchoolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Parent link requests',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final request in requests)
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: repository.firestore
                      .collection('users')
                      .doc(request.data()['parentId']?.toString())
                      .get(),
                  builder: (context, parentSnapshot) {
                    final parent = parentSnapshot.data?.data();
                    final name =
                        parent?['name']?.toString() ??
                        parent?['email']?.toString() ??
                        'Parent';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name),
                      subtitle: Text(parent?['email']?.toString() ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Reject',
                            onPressed: () => _respond(context, request, false),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Approve',
                            onPressed: () => _respond(context, request, true),
                            icon: const Icon(
                              Icons.check_rounded,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color:
              color ?? (isDark ? SchoolColors.darkMuted : SchoolColors.muted),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// MODERN SETTING TILE
// ─────────────────────────────────────────────────────────────────
class _ModernSettingTile extends StatelessWidget {
  const _ModernSettingTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// LANGUAGE TILE (For Bottom Sheet)
// ─────────────────────────────────────────────────────────────────
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(flag, style: const TextStyle(fontSize: 18)),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Theme.of(context).colorScheme.primary : null,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        sublabel,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? Icon(
                Icons.check_circle_rounded,
                key: const ValueKey('check'),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// INFO TILE
// ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isDark ? SchoolColors.darkMuted : SchoolColors.muted)
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: Text(
        trailing,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data, required this.l10n});
  final Map<String, dynamic> data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final classIds = data['classIds'] is Iterable
        ? (data['classIds'] as Iterable).whereType<String>().toList()
        : <String>[];
    final repo = AppScope.of(context).repository;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final averageLabel = isRu ? 'СРЕДНИЙ БАЛЛ' : 'AVERAGE SCORE';
    final average = data['averageGrade'] ?? data['averageScore'] ?? '—';

    return Row(
      children: [
        Expanded(
          child: SettingsStatCard(
            label: l10n.classes.toUpperCase(),
            value: classIds.length.toString(),
            color: SchoolColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FutureBuilder<QuerySnapshot?>(
            future: classIds.isEmpty
                ? Future<QuerySnapshot?>.value(null)
                : repo.firestore
                      .collection('assignments')
                      .where('classId', whereIn: classIds.take(30).toList())
                      .get(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return SettingsStatCard(
                label: l10n.assignments.toUpperCase(),
                value: count.toString(),
                color: SchoolColors.orange,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SettingsStatCard(
            label: averageLabel,
            value: average.toString(),
            color: SchoolColors.green,
          ),
        ),
      ],
    );
  }
}

class _LinkingCard extends StatelessWidget {
  const _LinkingCard({required this.email, required this.l10n});
  final String email;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrData = jsonEncode({'type': 'link_child', 'email': email});

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SchoolColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: SchoolColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.linkingCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.showThisCodeToYourParent,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? SchoolColors.darkMuted
                          : SchoolColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 180.0,
            gapless: false,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.circle,
              color: Color(0xFF0F172A),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          email,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: SchoolColors.primary,
          ),
        ),
      ],
    );
  }
}
