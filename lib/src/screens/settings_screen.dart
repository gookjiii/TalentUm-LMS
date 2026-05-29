import 'dart:io';
import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_state.dart';
import '../firebase/school_repository.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';
import '../utils/reload_app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.appState,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
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
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Аватар обновлен / Avatar updated')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки / Upload error: $e')),
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
              : Border.all(
                  color: Colors.transparent,
                  width: 0,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: isSelected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              )
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
              Divider(color: isDark ? SchoolColors.darkBorder : SchoolColors.border),
              _LanguageTile(
                flag: '🇬🇧',
                label: l10n.english,
                sublabel: 'English',
                selected: widget.appState.locale?.languageCode == 'en' ||
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
                selected: widget.appState.locale?.languageCode == 'ru' ||
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
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final isDark = widget.appState.isDarkMode;
        final isRu = Localizations.localeOf(context).languageCode == 'ru';

        // Localized labels matching screenshot
        final notificationsLabel = isRu ? AppLocalizations.of(context)!.notifications : 'Notifications';
        final pushNotificationsLabel = isRu ? AppLocalizations.of(context)!.pushNotifications : 'Push notifications';
        final pushNotificationsSub = isRu ? AppLocalizations.of(context)!.allowedForChatAndTasks : 'Allowed for chat and assignments';
        final newMessagesLabel = isRu ? AppLocalizations.of(context)!.newMessages : 'New messages';
        final newMessagesSub = isRu ? AppLocalizations.of(context)!.soundVibration : 'Sound + vibration';
        final updatesLabel = isRu ? AppLocalizations.of(context)!.updates : 'Updates';
        final updatesSub = isRu ? AppLocalizations.of(context)!.quietMode22000700 : 'Quiet mode: 22:00–07:00';

        final appearanceLabel = isRu ? AppLocalizations.of(context)!.registration : 'Appearance';
        final darkThemeLabel = isRu ? AppLocalizations.of(context)!.darkTheme : 'Dark theme';
        final darkThemeSub = isRu ? AppLocalizations.of(context)!.system : 'System';
        final accentColorLabel = isRu ? AppLocalizations.of(context)!.accentColor : 'Accent color';
        final languageLabel = isRu ? AppLocalizations.of(context)!.language : 'Language';
        final activeLanguageSub = widget.appState.locale?.languageCode == 'en'
            ? 'English (en)'
            : AppLocalizations.of(context)!.russianRu;

        return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Profile section ─────────────────────────────────
          _SectionLabel(label: l10n.profile),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: widget.repository.userDocStream(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? {};
              final avatarUrl = data['avatarUrl'] as String?;
              final currentName = data['name'] as String? ?? widget.repository.auth.currentUser?.displayName ?? '';
              
              if (_nameController.text.isEmpty && currentName.isNotEmpty) {
                _nameController.text = currentName;
              }

              return SchoolCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _uploadingAvatar ? null : () => _pickAndUploadAvatar(context),
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _uploadingAvatar
                                    ? const Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: CircularProgressIndicator(strokeWidth: 2.5),
                                      )
                                    : SchoolAvatar(
                                        name: currentName,
                                        avatarUrl: avatarUrl,
                                        radius: 40,
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: widget.appState.accentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.name,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save_outlined),
                          tooltip: l10n.saveChanges,
                          onPressed: () => _saveName(context, l10n),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // ── Notifications section ───────────────────────────
          _SectionLabel(label: notificationsLabel),
          SchoolCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ModernSettingTile(
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFFEF4444),
                  iconBgColor: const Color(0xFFFEE2E2),
                  title: pushNotificationsLabel,
                  subtitle: pushNotificationsSub,
                  trailing: Switch.adaptive(
                    value: widget.appState.pushNotifications,
                    onChanged: (val) => widget.appState.setPushNotifications(val),
                    activeColor: widget.appState.accentColor,
                  ),
                  onTap: () => widget.appState.setPushNotifications(
                    !widget.appState.pushNotifications,
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                  indent: 68,
                ),
                _ModernSettingTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  iconBgColor: const Color(0xFFF5F3FF),
                  title: newMessagesLabel,
                  subtitle: newMessagesSub,
                  trailing: Switch.adaptive(
                    value: widget.appState.soundAndVibe,
                    onChanged: (val) => widget.appState.setSoundAndVibe(val),
                    activeColor: widget.appState.accentColor,
                  ),
                  onTap: () => widget.appState.setSoundAndVibe(
                    !widget.appState.soundAndVibe,
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                  indent: 68,
                ),
                _ModernSettingTile(
                  icon: Icons.push_pin_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  iconBgColor: const Color(0xFFFFEDD5),
                  title: updatesLabel,
                  subtitle: updatesSub,
                  trailing: Switch.adaptive(
                    value: widget.appState.quietModeUpdates,
                    onChanged: (val) => widget.appState.setQuietModeUpdates(val),
                    activeColor: widget.appState.accentColor,
                  ),
                  onTap: () => widget.appState.setQuietModeUpdates(
                    !widget.appState.quietModeUpdates,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Appearance section ──────────────────────────────
          _SectionLabel(label: appearanceLabel),
          SchoolCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ModernSettingTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFD1FAE5),
                  title: darkThemeLabel,
                  subtitle: darkThemeSub,
                  trailing: Switch.adaptive(
                    value: isDark,
                    onChanged: (_) => widget.appState.toggleDarkMode(),
                    activeColor: widget.appState.accentColor,
                  ),
                  onTap: () => widget.appState.toggleDarkMode(),
                ),
                Divider(
                  height: 1,
                  color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                  indent: 68,
                ),
                _ModernSettingTile(
                  icon: Icons.palette_outlined,
                  iconColor: const Color(0xFF6366F1),
                  iconBgColor: const Color(0xFFEDE9FE),
                  title: accentColorLabel,
                  subtitle: _getAccentColorName(widget.appState.accentColor, isRu),
                  trailing: Row(
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
                Divider(
                  height: 1,
                  color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                  indent: 68,
                ),
                _ModernSettingTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF0E7490),
                  iconBgColor: const Color(0xFFE0F2FE),
                  title: languageLabel,
                  subtitle: activeLanguageSub,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                  ),
                  onTap: () => _showLanguagePicker(context, l10n),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── About section ───────────────────────────────────
          _SectionLabel(label: isRu ? AppLocalizations.of(context)!.aboutTheApplication : 'About'),
          SchoolCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  label: isRu ? AppLocalizations.of(context)!.version : 'Version',
                  trailing: '1.0.0',
                ),
                Divider(
                  height: 1,
                  color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
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
          _SectionLabel(label: isRu ? AppLocalizations.of(context)!.dangerZone : 'Danger Zone', color: SchoolColors.red),
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
                        ? AppLocalizations.of(context)!.youWillBeRedirectedTo
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
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
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
            : const SizedBox(key: ValueKey('none'), width: 20),
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
