import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';
import '../app_state.dart';
import '../firebase/school_repository.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

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
    if (val == const Color(0xFF7C3AED).value) {
      return isRu ? 'Фиолетовый' : 'Purple';
    } else if (val == const Color(0xFF059669).value) {
      return isRu ? 'Изумрудный' : 'Emerald';
    } else if (val == const Color(0xFFF59E0B).value) {
      return isRu ? 'Янтарный' : 'Amber';
    } else if (val == const Color(0xFFDC2626).value) {
      return isRu ? 'Алый' : 'Crimson';
    }
    return isRu ? 'Школьный синий' : 'School Blue';
  }

  Widget _buildColorDot(Color color, bool isDark) {
    final isSelected = widget.appState.accentColor.value == color.value;
    return GestureDetector(
      onTap: () => widget.appState.setAccentColor(color),
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
                sublabel: 'Русский',
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    // Localized labels matching screenshot
    final notificationsLabel = isRu ? 'Уведомления' : 'Notifications';
    final pushNotificationsLabel = isRu ? 'Push-уведомления' : 'Push notifications';
    final pushNotificationsSub = isRu ? 'Разрешены для чата и заданий' : 'Allowed for chat and assignments';
    final newMessagesLabel = isRu ? 'Новые сообщения' : 'New messages';
    final newMessagesSub = isRu ? 'Звук + вибрация' : 'Sound + vibration';
    final updatesLabel = isRu ? 'Обновления' : 'Updates';
    final updatesSub = isRu ? 'Тихий режим: 22:00–07:00' : 'Quiet mode: 22:00–07:00';

    final appearanceLabel = isRu ? 'Оформление' : 'Appearance';
    final darkThemeLabel = isRu ? 'Тёмная тема' : 'Dark theme';
    final darkThemeSub = isRu ? 'Системная' : 'System';
    final accentColorLabel = isRu ? 'Акцентный цвет' : 'Accent color';
    final languageLabel = isRu ? 'Язык' : 'Language';
    final activeLanguageSub = widget.appState.locale?.languageCode == 'en'
        ? 'English (en)'
        : 'Русский (ru)';

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
          SchoolCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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
                      _buildColorDot(const Color(0xFF7C3AED), isDark),
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
          _SectionLabel(label: isRu ? 'О приложении' : 'About'),
          SchoolCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  label: isRu ? 'Версия' : 'Version',
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
          _SectionLabel(label: isRu ? 'Опасная зона' : 'Danger Zone', color: SchoolColors.red),
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
                        ? 'Вы будете перенаправлены на экран входа'
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
