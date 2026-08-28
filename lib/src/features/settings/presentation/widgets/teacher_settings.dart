import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/utils/reload_app.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/features/settings/presentation/widgets/settings_layout.dart';

class TeacherSettingsTab extends StatefulWidget {
  const TeacherSettingsTab({super.key});

  @override
  State<TeacherSettingsTab> createState() => _TeacherSettingsTabState();
}

class _TeacherSettingsTabState extends State<TeacherSettingsTab> {
  String _getAccentColorName(Color color, bool isRu) {
    final val = color.value;
    if (val == const Color(0xFF2563EB).value) {
      return isRu ? AppLocalizations.of(context)!.schoolBlue : 'School blue';
    } else if (val == const Color(0xFF059669).value ||
        val == SchoolColors.green.value) {
      return isRu ? AppLocalizations.of(context)!.emerald : 'Emerald';
    } else if (val == const Color(0xFFF59E0B).value ||
        val == SchoolColors.yellow.value) {
      return isRu ? AppLocalizations.of(context)!.amber : 'Amber';
    } else if (val == const Color(0xFFDC2626).value ||
        val == SchoolColors.red.value) {
      return isRu ? AppLocalizations.of(context)!.scarlet : 'Crimson';
    } else if (val == const Color(0xFF7C3AED).value ||
        val == SchoolColors.primary.value) {
      return isRu ? AppLocalizations.of(context)!.violet : 'Purple';
    }
    return isRu ? AppLocalizations.of(context)!.schoolBlue : 'School blue';
  }

  bool _loading = true;
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final file = result.files.first;
      final repo = AppScope.of(context).repository;
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

      if (avatarUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.avatarUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
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

  Map<String, dynamic> _userData = {};
  int _classesCount = 0;
  int _studentsCount = 0;
  bool _initialized = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _subscribeToUser();
      _loadCounts();
    }
  }

  void _subscribeToUser() {
    final repo = AppScope.of(context).repository;
    _userSub = repo.userDocStream().listen(
      (snap) {
        if (mounted) {
          setState(() {
            _userData = _normaliseMap(snap.data());
            _loading = false;
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Unable to load teacher settings: $error');
        if (mounted) {
          setState(() {
            _userData = <String, dynamic>{};
            _loading = false;
          });
        }
      },
    );
  }

  Map<String, dynamic> _normaliseMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Future<void> _loadCounts() async {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) return;
    try {
      final classesSnap = await repo.firestore
          .collection('classes')
          .where('teacherId', isEqualTo: uid)
          .get();
      final uniqueStudents = <String>{};
      for (final doc in classesSnap.docs) {
        final rawIds = doc.data()['studentIds'];
        if (rawIds is Iterable) {
          uniqueStudents.addAll(rawIds.whereType<String>());
        }
      }
      if (mounted) {
        setState(() {
          _classesCount = classesSnap.docs.length;
          _studentsCount = uniqueStudents.length;
        });
      }
    } catch (error) {
      // Settings must remain usable when a teacher has no class documents or
      // Firestore is temporarily unavailable.
      debugPrint('Unable to load teacher class counts: $error');
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // The settings tab can be mounted while MaterialApp is rebuilding its
      // locale delegate. Avoid a null-check crash during that short window.
      return const Center(child: CircularProgressIndicator());
    }
    final user = FirebaseAuth.instance.currentUser;
    final storedName = _userData['name']?.toString().trim();
    final name = storedName?.isNotEmpty == true
        ? storedName ?? ''
        : (user?.displayName ?? l10n.teacher);
    final avatarUrl = _userData['avatarUrl']?.toString();
    final email = user?.email ?? '';
    final school = _userData['school']?.toString().trim().isNotEmpty == true
        ? _userData['school'].toString()
        : l10n.n57;
    final appState = AppScope.of(context).appState;
    final settings = _normaliseMap(_userData['settings']);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                PageHeader(
                  title: l10n.settings,
                  subtitle: l10n.personalizationAndAccountManagement,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),

                // Profile Card
                SettingsProfileCard(
                  name: name,
                  avatarUrl: avatarUrl,
                  sub:
                      '${appState.isLeadTeacher ? l10n.administrator : l10n.teacher} · $school',
                  countLabel: '$_classesCount ${l10n.classes.toLowerCase()}',
                  verifiedLabel: l10n.verified,
                  roleColor: appState.isLeadTeacher
                      ? SchoolColors.primary
                      : SchoolColors.red,
                  onEditAvatar: _uploadingAvatar ? null : _pickAndUploadAvatar,
                ),

                const SizedBox(height: 12),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: SettingsStatCard(
                        label: l10n
                            .studentsCount(_studentsCount)
                            .split(':')[0]
                            .toUpperCase(),
                        value: _studentsCount.toString(),
                        color: SchoolColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SettingsStatCard(
                        // `createClass` is intentionally a one-word action in
                        // both locales ("Create"/"Создать"). Indexing the
                        // second split token caused Settings to crash at
                        // runtime with a null-check error in the web shell.
                        label: l10n.classes.toUpperCase(),
                        value: _classesCount.toString(),
                        color: SchoolColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SettingsStatCard(
                        label: AppLocalizations.of(context)!.experience,
                        value: _userData['experience']?.toString() ?? '—',
                        color: SchoolColors.yellow,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SettingsGroup(
                  label: l10n.studentAccount.split(' ')[1],
                  children: [
                    SettingsRow(
                      icon: Icons.person_outline_rounded,
                      color: SchoolColors.primary,
                      label: AppLocalizations.of(context)!.personalInformation,
                      sub: name,
                      onTap: () => _editName(context, name),
                    ),
                    SettingsRow(
                      icon: Icons.email_outlined,
                      color: SchoolColors.yellow,
                      label: l10n.email,
                      sub: email,
                      onTap: () => _editEmail(context, email),
                    ),
                    SettingsRow(
                      icon: Icons.link_rounded,
                      color: SchoolColors.accent,
                      label: AppLocalizations.of(context)!.linkedAccounts,
                      sub: 'Google · Apple',
                      onTap: () => _showLinkedAccounts(context),
                      last: true,
                    ),
                  ],
                ),

                SettingsGroup(
                  label: l10n.notifications,
                  children: [
                    SettingsRow(
                      icon: Icons.notifications_none_rounded,
                      color: SchoolColors.red,
                      label: AppLocalizations.of(context)!.pushNotifications,
                      sub: AppLocalizations.of(context)!.allowedForChatAndTasks,
                      right: _CustomToggle(
                        on: settings['pushEnabled'] ?? true,
                        onChanged: (v) => _updateSetting('pushEnabled', v),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: SchoolColors.primary,
                      label: AppLocalizations.of(context)!.newMessages,
                      sub: AppLocalizations.of(context)!.soundVibration,
                      right: _CustomToggle(
                        on: settings['msgNotifs'] ?? true,
                        onChanged: (v) => _updateSetting('msgNotifs', v),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.push_pin_outlined,
                      color: SchoolColors.yellow,
                      label: AppLocalizations.of(context)!.updates,
                      sub: AppLocalizations.of(context)!.quietMode22000700,
                      right: _CustomToggle(
                        on: settings['pinNotifs'] ?? false,
                        onChanged: (v) => _updateSetting('pinNotifs', v),
                      ),
                      last: true,
                    ),
                  ],
                ),

                SettingsGroup(
                  label: AppLocalizations.of(context)!.registration,
                  children: [
                    SettingsRow(
                      icon: Icons.dark_mode_outlined,
                      color: SchoolColors.accent,
                      label: l10n.darkMode,
                      sub: appState.isDarkMode
                          ? AppLocalizations.of(context)!.enabled
                          : AppLocalizations.of(context)!.system,
                      right: _CustomToggle(
                        on: appState.isDarkMode,
                        onChanged: (v) => appState.toggleDarkMode(),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.speed_rounded,
                      color: SchoolColors.yellow,
                      label:
                          Localizations.localeOf(context).languageCode == 'ru'
                          ? 'Режим высокой производительности'
                          : 'High Performance Mode',
                      sub: Localizations.localeOf(context).languageCode == 'ru'
                          ? 'Снижает графическую нагрузку для слабых устройств'
                          : 'Reduces graphics load for low-end devices',
                      right: _CustomToggle(
                        on: appState.performanceMode,
                        onChanged: (v) => appState.setPerformanceMode(v),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.palette_outlined,
                      color: SchoolColors.primary,
                      label: AppLocalizations.of(context)!.accentColor,
                      sub: _getAccentColorName(
                        appState.accentColor,
                        Localizations.localeOf(context).languageCode == 'ru',
                      ),
                      right: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final c in [
                            const Color(0xFF2563EB),
                            SchoolColors.green,
                            SchoolColors.yellow,
                            SchoolColors.red,
                          ])
                            GestureDetector(
                              onTap: () {
                                final isSelected =
                                    c.value == appState.accentColor.value;
                                if (!isSelected) {
                                  appState.setAccentColor(c);
                                  Future.delayed(
                                    const Duration(milliseconds: 250),
                                    () {
                                      reloadApp();
                                    },
                                  );
                                }
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: c.value == appState.accentColor.value
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    if (c.value == appState.accentColor.value)
                                      BoxShadow(
                                        color: c.withOpacity(0.4),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                child: c.value == appState.accentColor.value
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.language_rounded,
                      color: SchoolColors.green,
                      label: l10n.language,
                      sub: appState.locale?.languageCode == 'ru'
                          ? AppLocalizations.of(context)!.russianRu
                          : 'English (en)',
                      onTap: () => _editLanguage(context),
                      last: true,
                    ),
                  ],
                ),

                SettingsGroup(
                  label: AppLocalizations.of(context)!.tariffPlan,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: SchoolColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: SchoolColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.freePlan,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      l10n.currentPlan,
                                      style: const TextStyle(
                                        color: SchoolColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.soonAvailable),
                                      ),
                                    ),
                                style: FilledButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  l10n.upgrade,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SettingsGroup(
                  label: AppLocalizations.of(context)!.safety,
                  children: [
                    SettingsRow(
                      icon: Icons.security_outlined,
                      color: SchoolColors.red,
                      label: AppLocalizations.of(context)!.twofactorProtection,
                      sub: AppLocalizations.of(context)!.enabledAuthenticator,
                      right: StatusChip(
                        label: AppLocalizations.of(context)!.actively,
                        color: SchoolColors.green,
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.download_outlined,
                      color: SchoolColors.accent,
                      label: AppLocalizations.of(context)!.downloadMyData,
                      sub: AppLocalizations.of(context)!.exportToZip,
                      onTap: () => _downloadMyData(context),
                      last: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => _confirmSignOut(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SchoolColors.red,
                    side: BorderSide(color: SchoolColors.red.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.signOut),
                ),
                const SizedBox(height: 16),
                const Text(
                  'School World v 2.4.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SchoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateSetting(String key, bool value) async {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) return;

    await repo.firestore.collection('users').doc(uid).set({
      'settings': {key: value},
    }, SetOptions(merge: true));
    // Stream subscription will pick up the update automatically
  }

  Future<void> _editName(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editProfile),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      if (!context.mounted) return;
      final repo = AppScope.of(context).repository;
      await repo.updateProfile(
        name: controller.text.trim(),
        firstName: controller.text.trim().split(' ')[0],
        lastName: '',
      );
      // Stream subscription will pick up the name update automatically
    }
  }

  Future<void> _editEmail(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.contactSupportForEmail)));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.signOut}?'),
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

    if (ok == true && context.mounted) {
      final scope = AppScope.of(context);
      scope.appState.resetSession();
      await scope.repository.signOut();
      reloadApp();
    }
  }

  void _showLinkedAccounts(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providers =
        user?.providerData.map((p) => p.providerId).toList() ?? [];
    final isGoogle = providers.contains('google.com');
    final isApple = providers.contains('apple.com');
    final isEmail = providers.contains('password');

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context)!.linkedAccounts,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
                  _buildProviderTile(
                    'Google',
                    isGoogle,
                    Icons.g_mobiledata_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildProviderTile('Apple', isApple, Icons.apple_rounded),
                  const SizedBox(height: 14),
                  _buildProviderTile(
                    AppLocalizations.of(context)!.emailpassword,
                    isEmail,
                    Icons.email_rounded,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.ready),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProviderTile(String name, bool linked, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const Spacer(),
        StatusChip(
          label: linked
              ? AppLocalizations.of(context)!.related
              : AppLocalizations.of(context)!.notRelated,
          color: linked ? SchoolColors.green : SchoolColors.muted,
        ),
      ],
    );
  }

  void _editLanguage(BuildContext context) {
    final appState = AppScope.of(context).appState;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.language,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLanguageTile(
                    ctx,
                    AppLocalizations.of(context)!.russianRu,
                    'ru',
                    appState,
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageTile(ctx, 'English (en)', 'en', appState),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.ready),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String name,
    String code,
    dynamic appState,
  ) {
    final isSelected = appState.locale?.languageCode == code;
    return InkWell(
      onTap: () {
        appState.setLocale(Locale(code));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              code == 'ru'
                  ? AppLocalizations.of(context)!.languageChangedToRussian
                  : 'Language changed to English',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: SchoolColors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _downloadMyData(BuildContext context) {
    bool exporting = false;
    double progress = 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (ctx, setS) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassCard(
                  child: exporting
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SchoolColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.preparingAZipArchive,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: SchoolColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.exportData,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              AppLocalizations.of(context)!.aZipArchiveWillBe,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    AppLocalizations.of(context)!.unknownKey,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () async {
                                    setS(() {
                                      exporting = true;
                                    });
                                    for (int i = 0; i <= 10; i++) {
                                      await Future.delayed(
                                        const Duration(milliseconds: 150),
                                      );
                                      if (ctx.mounted) {
                                        setS(() {
                                          progress = i / 10;
                                        });
                                      }
                                    }
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.theArchiveWasSuccessfullySaved,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.export,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CustomToggle extends StatelessWidget {
  const _CustomToggle({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: on,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: SchoolColors.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: SchoolColors.border,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
