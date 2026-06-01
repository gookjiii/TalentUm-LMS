import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class TeacherNavDest {
  const TeacherNavDest(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class TeacherSidebar extends StatelessWidget {
  const TeacherSidebar({
    super.key,
    required this.extended,
    required this.selectedIndex,
    required this.onSelect,
    required this.navigationItems,
    required this.classes,
    required this.activeClassId,
    required this.onDeleteChat,
    required this.onDeleteClass,
    required this.onCopyGuestLink,
    required this.onSelectClass,
    this.onCreateClass,
    this.onProfileTap,
  });

  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<TeacherNavDest> navigationItems;
  final List<Map<String, dynamic>> classes;
  final String? activeClassId;
  final void Function(String, String) onDeleteChat;
  final void Function(String, String) onDeleteClass;
  final void Function(String, String) onCopyGuestLink;
  final ValueChanged<String> onSelectClass;
  final VoidCallback? onCreateClass;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: extended ? 280 : 80,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SchoolColors.sidebarBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _TeacherSidebarHeader(extended: extended, l10n: l10n),
          _SidebarDivider(),
          const SizedBox(height: 6),
          // Nav items + classes in scrollable area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (int i = 0; i < navigationItems.length; i++)
                  _TeacherNavItem(
                    icon: selectedIndex == i
                        ? navigationItems[i].selectedIcon
                        : navigationItems[i].icon,
                    label: navigationItems[i].label,
                    selected: selectedIndex == i,
                    extended: extended,
                    onTap: () => onSelect(i),
                  ),
                if (extended) ...[
                  if (AppScope.of(context).appState.isLeadTeacher)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: _AdminModeToggle(),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 24, 14, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.myClasses.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.3),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        if (AppScope.of(context).appState.isLeadTeacher)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: IconButton(
                              onPressed: onCreateClass,
                              icon: const Icon(Icons.add_rounded, size: 14),
                              color: Colors.white.withValues(alpha: 0.4),
                              padding: EdgeInsets.zero,
                              tooltip: l10n.createClass,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final c in classes)
                    _TeacherClassItem(
                      name: c['name'] ?? '',
                      subject: c['subject'] ?? '',
                      avatarUrl: c['avatarUrl'] as String?,
                      color: parseHexColor(c['coverColor']),
                      selected: c['id'] == activeClassId && selectedIndex != 0,
                      isLead: AppScope.of(context).appState.isLeadTeacher,
                      onTap: () {
                        onSelectClass(c['id'] as String);
                        if (selectedIndex == 0) onSelect(1);
                      },
                      onDeleteChat: () =>
                          onDeleteChat(c['id'] as String, c['name'] ?? ''),
                      onDeleteClass: () =>
                          onDeleteClass(c['id'] as String, c['name'] ?? ''),
                      onCopyLink: () => onCopyGuestLink(
                        c['id'] as String,
                        c['inviteCode'] ?? '',
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (!extended && AppScope.of(context).appState.isLeadTeacher) ...[
            IconButton(
              onPressed: onCreateClass,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white.withValues(alpha: 0.45),
              ),
              tooltip: l10n.createClass,
            ),
            const SizedBox(height: 4),
          ],
          _SidebarDivider(),
          _TeacherUserCard(
            extended: extended,
            onSignOut: repo.signOut,
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────

class _SidebarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _TeacherSidebarHeader extends StatelessWidget {
  const _TeacherSidebarHeader({required this.extended, required this.l10n});
  final bool extended;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: extended
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          const SchoolLogo(size: 36),
          if (extended) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: AppScope.of(
                      context,
                    ).repository.systemSettingsStream(),
                    builder: (context, snapshot) {
                      final doc = snapshot.data;
                      final appName = (doc != null && doc.exists)
                          ? (doc.data()?['appName'] as String? ?? 'TalentUm')
                          : 'TalentUm';
                      return Text(
                        appName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  Text(
                    l10n.teacherConsole,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeacherNavItem extends StatefulWidget {
  const _TeacherNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  State<_TeacherNavItem> createState() => _TeacherNavItemState();
}

class _TeacherNavItemState extends State<_TeacherNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.55);
    final bgColor = widget.selected
        ? Colors.white.withValues(alpha: 0.10)
        : _hovered
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: widget.extended ? '' : widget.label,
        preferBelow: false,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 46,
              padding: EdgeInsets.symmetric(
                horizontal: widget.extended ? 14 : 0,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: widget.extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (widget.selected && widget.extended)
                    Container(
                      width: 3,
                      height: 20,
                      margin: const EdgeInsets.only(right: 11),
                      decoration: BoxDecoration(
                        color: SchoolColors.primaryLight,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: SchoolColors.primaryLight.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    )
                  else if (widget.extended)
                    const SizedBox(width: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      widget.icon,
                      key: ValueKey(widget.icon),
                      size: 20,
                      color: widget.selected ? activeColor : inactiveColor,
                    ),
                  ),
                  if (widget.extended) ...[
                    const SizedBox(width: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: widget.selected ? activeColor : inactiveColor,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherClassItem extends StatefulWidget {
  const _TeacherClassItem({
    required this.name,
    required this.subject,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.onDeleteChat,
    required this.onDeleteClass,
    required this.onCopyLink,
    this.avatarUrl,
    required this.isLead,
    this.isVirtual = false,
  });

  final String name, subject;
  final Color color;
  final bool selected;
  final VoidCallback onTap, onDeleteChat, onDeleteClass, onCopyLink;
  final String? avatarUrl;
  final bool isLead;
  final bool isVirtual;

  @override
  State<_TeacherClassItem> createState() => _TeacherClassItemState();
}

class _TeacherClassItemState extends State<_TeacherClassItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withValues(alpha: 0.6);
    final bgColor = widget.selected
        ? Colors.white.withValues(alpha: 0.09)
        : _hovered
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: widget.selected
                  ? Border.all(
                      color: widget.color.withValues(alpha: 0.22),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (widget.isVirtual)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: widget.color,
                    ),
                  )
                else
                  ClassBadge(
                    name: widget.name,
                    color: widget.color,
                    size: 32,
                    avatarUrl: widget.avatarUrl,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: widget.selected ? Colors.white : inactiveColor,
                        ),
                      ),
                      if (widget.subject.isNotEmpty)
                        Text(
                          widget.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: inactiveColor.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!widget.isVirtual && (widget.selected || _hovered))
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: inactiveColor,
                    ),
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    itemBuilder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return [
                        PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.copyInviteLink,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isLead) ...[
                          PopupMenuItem(
                            value: 'clear',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.clearChat,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.deleteClass,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ];
                    },
                    onSelected: (val) {
                      if (val == 'copy') widget.onCopyLink();
                      if (val == 'clear') widget.onDeleteChat();
                      if (val == 'delete') widget.onDeleteClass();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700.withOpacity(0.15),
            Colors.orange.shade900.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade800.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: Colors.orange.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.adminMode,
              style: TextStyle(
                color: Colors.orange.shade400,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: SchoolColors.green,
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _TeacherUserCard extends StatelessWidget {
  const _TeacherUserCard({
    required this.extended,
    required this.onSignOut,
    this.onTap,
  });

  final bool extended;
  final VoidCallback onSignOut;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final l10n = AppLocalizations.of(context)!;
    final isLead = AppScope.of(context).appState.isLeadTeacher;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.userDocStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final fallbackName = repo.auth.currentUser?.displayName ?? l10n.teacher;
        final name = (data['name'] as String?)?.isNotEmpty == true
            ? data['name'] as String
            : fallbackName;
        final avatarUrl = data['avatarUrl'] as String?;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: extended ? 12 : 4,
            vertical: 12,
          ),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.all(extended ? 12 : 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  SchoolAvatar(
                    name: name,
                    avatarUrl: avatarUrl,
                    radius: extended ? 18 : 15,
                    showBorder: true,
                  ),
                  if (extended) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            isLead ? 'Lead Teacher' : l10n.teacher,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onSignOut,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 17,
                        color: SchoolColors.red,
                      ),
                      tooltip: l10n.logOut,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
