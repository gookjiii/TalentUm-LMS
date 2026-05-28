import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class NavDest {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const NavDest(this.label, this.icon, this.selectedIcon);
}

class StudentSidebar extends StatelessWidget {
  const StudentSidebar({
    super.key,
    required this.extended,
    required this.selectedIndex,
    required this.onSelect,
    required this.navigationItems,
    required this.classes,
    required this.activeClassId,
    required this.onSelectClass,
  });

  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavDest> navigationItems;
  final List<Map<String, dynamic>> classes;
  final String? activeClassId;
  final ValueChanged<String> onSelectClass;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;

    return Container(
      width: extended ? 260 : 80,
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
          _SidebarHeader(extended: extended, subtitle: 'Портал ученика'),
          _SidebarDivider(),

          // Navigation items
          const SizedBox(height: 6),
          ...List.generate(navigationItems.length, (i) {
            final item = navigationItems[i];
            final selected = selectedIndex == i;
            return _SidebarNavItem(
              icon: selected ? item.selectedIcon : item.icon,
              label: item.label,
              selected: selected,
              extended: extended,
              onTap: () => onSelect(i),
            );
          }),

          // Classes section
          if (extended) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'МОИ КЛАССЫ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final c = classes[index];
                  final id = c['id'] as String;
                  final isActive = id == activeClassId;
                  return _SidebarClassItem(
                    name: c['name']?.toString() ?? '',
                    color: parseHexColor(c['coverColor']),
                    selected: isActive,
                    onTap: () {
                      onSelectClass(id);
                      if (selectedIndex == 0) onSelect(1);
                    },
                  );
                },
              ),
            ),
          ] else
            const Spacer(),

          _SidebarDivider(),
          _UserCard(extended: extended, onSignOut: repo.signOut),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHARED SIDEBAR PIECES
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

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.extended,
    required this.subtitle,
    this.title = 'School World',
  });

  final bool extended;
  final String title;
  final String subtitle;

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
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
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

class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
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
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
              height: 44,
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
                  // Animated left accent bar
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

class _SidebarClassItem extends StatefulWidget {
  const _SidebarClassItem({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarClassItem> createState() => _SidebarClassItemState();
}

class _SidebarClassItemState extends State<_SidebarClassItem> {
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
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: widget.selected
                  ? Border.all(
                      color: widget.color.withValues(alpha: 0.25),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                ClassBadge(name: widget.name, color: widget.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: widget.selected ? Colors.white : inactiveColor,
                    ),
                  ),
                ),
                if (widget.selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.extended, required this.onSignOut});
  final bool extended;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.userDocStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final fallbackName = repo.auth.currentUser?.displayName ?? 'Ученик';
        final name = (data['name'] as String?)?.isNotEmpty == true
            ? data['name'] as String
            : fallbackName;
        final avatarUrl = data['avatarUrl'] as String?;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(extended ? 12 : 8),
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
                          'Ученик',
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
                    tooltip: 'Выйти',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Keep SidebarItem and SidebarClassItem exported for any external usage
typedef SidebarItem = _SidebarNavItem;
