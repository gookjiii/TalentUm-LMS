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
    } else if (val == const Color(0xFF059669).value || val == SchoolColors.green.value) {
      return isRu ? AppLocalizations.of(context)!.emerald : 'Emerald';
    } else if (val == const Color(0xFFF59E0B).value || val == SchoolColors.yellow.value) {
      return isRu ? AppLocalizations.of(context)!.amber : 'Amber';
    } else if (val == const Color(0xFFDC2626).value || val == SchoolColors.red.value) {
      return isRu ? AppLocalizations.of(context)!.scarlet : 'Crimson';
    } else if (val == const Color(0xFF7C3AED).value || val == SchoolColors.primary.value) {
      return isRu ? AppLocalizations.of(context)!.violet : 'Purple';
    }
    return isRu ? AppLocalizations.of(context)!.schoolBlue : 'School blue';
  }

  bool _loading = true;
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
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

      final path = 'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      Map<String, dynamic>? uploadResult;
      if (file.bytes != null) {
        uploadResult = await repo.uploadFileWeb(path, file.bytes!);
      } else if (file.path != null) {
        uploadResult = await repo.uploadFile(path, File(file.path!));
      }

      if (uploadResult != null && uploadResult['url'] != null) {
        final url = uploadResult['url'] as String;
        await repo.firestore.collection('users').doc(uid).update({
          'avatarUrl': url,
        });
        await repo.auth.currentUser?.updatePhotoURL(url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.avatarUpdated)),
          );
        }
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
    _userSub = repo.userDocStream().listen((snap) {
      if (mounted) {
        setState(() {
          _userData = snap.data() ?? {};
          _loading = false;
        });
      }
    });
  }

  Future<void> _loadCounts() async {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) return;
    final classesSnap = await repo.firestore
        .collection('classes')
        .where('teacherId', isEqualTo: uid)
        .get();
    final uniqueStudents = <String>{};
    for (final doc in classesSnap.docs) {
      uniqueStudents.addAll(
        List<String>.from(doc.data()['studentIds'] ?? []),
      );
    }
    if (mounted) {
      setState(() {
        _classesCount = classesSnap.docs.length;
        _studentsCount = uniqueStudents.length;
      });
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

    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final name = (_userData['name'] as String?)?.isNotEmpty == true
        ? _userData['name'] as String
        : (user?.displayName ?? AppLocalizations.of(context)!.teacher);
    final avatarUrl = _userData['avatarUrl'] as String?;
    final email = user?.email ?? '';
    final school = _userData['school'] ?? AppLocalizations.of(context)!.n57;
    final appState = AppScope.of(context).appState;
    final settings = _userData['settings'] as Map<String, dynamic>? ?? {};

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
                _ProfileCard(
                  name: name,
                  avatarUrl: avatarUrl,
                  sub:
                      '${appState.isLeadTeacher ? 'Lead Teacher' : l10n.teacher} · $school',
                  isTeacher: true,
                  classesCount: _classesCount,
                  onEditAvatar: _uploadingAvatar ? null : _pickAndUploadAvatar,
                ),

            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
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
                  child: _StatMiniCard(
                    label: l10n.createClass.split(' ')[1].toUpperCase(),
                    value: _classesCount.toString(),
                    color: SchoolColors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMiniCard(
                    label: AppLocalizations.of(context)!.experience,
                    value: _userData['experience']?.toString() ?? '—',
                    color: SchoolColors.yellow,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _SettingsGroup(
              label: l10n.studentAccount.split(' ')[1],
              children: [
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  color: SchoolColors.primary,
                  label: AppLocalizations.of(context)!.personalInformation,
                  sub: name,
                  onTap: () => _editName(context, name),
                ),
                _SettingsRow(
                  icon: Icons.email_outlined,
                  color: SchoolColors.yellow,
                  label: l10n.email,
                  sub: email,
                  onTap: () => _editEmail(context, email),
                ),
                _SettingsRow(
                  icon: Icons.link_rounded,
                  color: SchoolColors.accent,
                  label: AppLocalizations.of(context)!.linkedAccounts,
                  sub: 'Google · Apple',
                  onTap: () => _showLinkedAccounts(context),
                  last: true,
                ),
              ],
            ),

            _SettingsGroup(
              label: l10n.notifications,
              children: [
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  color: SchoolColors.red,
                  label: AppLocalizations.of(context)!.pushNotifications,
                  sub: AppLocalizations.of(context)!.allowedForChatAndTasks,
                  right: _CustomToggle(
                    on: settings['pushEnabled'] ?? true,
                    onChanged: (v) => _updateSetting('pushEnabled', v),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: SchoolColors.primary,
                  label: AppLocalizations.of(context)!.newMessages,
                  sub: AppLocalizations.of(context)!.soundVibration,
                  right: _CustomToggle(
                    on: settings['msgNotifs'] ?? true,
                    onChanged: (v) => _updateSetting('msgNotifs', v),
                  ),
                ),
                _SettingsRow(
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

            _SettingsGroup(
              label: AppLocalizations.of(context)!.registration,
              children: [
                _SettingsRow(
                  icon: Icons.dark_mode_outlined,
                  color: SchoolColors.accent,
                  label: l10n.darkMode,
                  sub: appState.isDarkMode ? AppLocalizations.of(context)!.enabled : AppLocalizations.of(context)!.system,
                  right: _CustomToggle(
                    on: appState.isDarkMode,
                    onChanged: (v) => appState.toggleDarkMode(),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.speed_rounded,
                  color: SchoolColors.yellow,
                  label: Localizations.localeOf(context).languageCode == 'ru'
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
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  color: SchoolColors.primary,
                  label: AppLocalizations.of(context)!.accentColor,
                  sub: _getAccentColorName(appState.accentColor, Localizations.localeOf(context).languageCode == 'ru'),
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
                            final isSelected = c.value == appState.accentColor.value;
                            if (!isSelected) {
                              appState.setAccentColor(c);
                              Future.delayed(const Duration(milliseconds: 250), () {
                                reloadApp();
                              });
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
                _SettingsRow(
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

            _SettingsGroup(
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
                                  SnackBar(content: Text(l10n.soonAvailable)),
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

            _SettingsGroup(
              label: AppLocalizations.of(context)!.safety,
              children: [
                _SettingsRow(
                  icon: Icons.security_outlined,
                  color: SchoolColors.red,
                  label: AppLocalizations.of(context)!.twofactorProtection,
                  sub: AppLocalizations.of(context)!.enabledAuthenticator,
                  right: StatusChip(
                    label: AppLocalizations.of(context)!.actively,
                    color: SchoolColors.green,
                  ),
                ),
                _SettingsRow(
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
              padding: const EdgeInsets.all(24),
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
          label: linked ? AppLocalizations.of(context)!.related : AppLocalizations.of(context)!.notRelated,
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
              padding: const EdgeInsets.all(24),
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
                  _buildLanguageTile(ctx, AppLocalizations.of(context)!.russianRu, 'ru', appState),
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
                  padding: const EdgeInsets.all(24),
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
                              AppLocalizations.of(context)!.preparingAZipArchive,
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
                                            AppLocalizations.of(context)!.theArchiveWasSuccessfullySaved,
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.sub,
    required this.isTeacher,
    required this.classesCount,
    this.avatarUrl,
    this.onEditAvatar,
  });
  final String name, sub;
  final bool isTeacher;
  final int classesCount;
  final String? avatarUrl;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isTeacher ? SchoolColors.red : SchoolColors.primary)
                        .withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: avatarUrl == null
                          ? LinearGradient(
                              colors: isTeacher
                                  ? [SchoolColors.red, SchoolColors.yellow]
                                  : [SchoolColors.green, SchoolColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SchoolAvatar(
                      name: name,
                      avatarUrl: avatarUrl,
                      radius: 32,
                      color: avatarUrl != null ? null : Colors.transparent,
                      onEditAvatar: onEditAvatar,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: SchoolColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SchoolColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(
                          label: '$classesCount классов',
                          color: SchoolColors.primary.withOpacity(0.1),
                          textColor: SchoolColors.primary,
                        ),
                        const SizedBox(width: 6),
                        StatusChip(
                          label: AppLocalizations.of(context)!.verified,
                          color: SchoolColors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: SchoolColors.muted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: SchoolColors.muted,
              letterSpacing: 1,
            ),
          ),
        ),
        SchoolCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
    this.onTap,
    this.right,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String label, sub;
  final VoidCallback? onTap;
  final Widget? right;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(
                    color: SchoolColors.border.withOpacity(0.5),
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: SchoolColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            right ??
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: SchoolColors.muted,
                ),
          ],
        ),
      ),
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
