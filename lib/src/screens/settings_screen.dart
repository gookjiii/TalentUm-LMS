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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MediaQuery.sizeOf(context).width < 720
          ? AppBar(title: Text(l10n.settings))
          : AppBar(title: Text(l10n.settings)),
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

          // ── Appearance section ──────────────────────────────
          _SectionLabel(label: 'Внешний вид'),
          SchoolCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ToggleTile(
                  icon: isDark
                      ? Icons.nightlight_rounded
                      : Icons.wb_sunny_rounded,
                  label: 'Тёмная тема',
                  value: isDark,
                  onChanged: (_) => widget.appState.toggleDarkMode(),
                  iconColor: isDark
                      ? const Color(0xFF818CF8)
                      : const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Language section ────────────────────────────────
          _SectionLabel(label: l10n.language),
          SchoolCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LanguageTile(
                  flag: '🇬🇧',
                  label: l10n.english,
                  sublabel: 'English',
                  selected:
                      widget.appState.locale?.languageCode == 'en' ||
                      (widget.appState.locale == null &&
                          Localizations.localeOf(context).languageCode == 'en'),
                  onTap: () => widget.appState.setLocale(const Locale('en')),
                ),
                Divider(
                  height: 1,
                  color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
                  indent: 56,
                ),
                _LanguageTile(
                  flag: '🇷🇺',
                  label: l10n.russian,
                  sublabel: 'Русский',
                  selected:
                      widget.appState.locale?.languageCode == 'ru' ||
                      (widget.appState.locale == null &&
                          Localizations.localeOf(context).languageCode == 'ru'),
                  onTap: () => widget.appState.setLocale(const Locale('ru')),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── About section ───────────────────────────────────
          _SectionLabel(label: 'О приложении'),
          SchoolCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Версия',
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
          _SectionLabel(label: 'Опасная зона', color: SchoolColors.red),
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
                    'Вы будете перенаправлены на экран входа',
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
// TOGGLE TILE (for dark mode)
// ─────────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c =
        iconColor ?? (isDark ? SchoolColors.darkMuted : SchoolColors.muted);

    return ListTile(
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween<double>(
            begin: 0.4,
            end: 0.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Container(
          key: ValueKey(value),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: c),
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: SchoolColors.primary,
      ),
      onTap: () => onChanged(!value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// LANGUAGE TILE
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
