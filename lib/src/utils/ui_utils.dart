import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:school_world/l10n/app_localizations.dart';
import '../theme.dart';

Color colorFromHex(String? hex, [Color fallback = SchoolColors.primary]) {
  if (hex == null || hex.isEmpty) return fallback;
  final s = hex.replaceAll('#', '');
  if (s.length != 6 && s.length != 8) return fallback;
  try {
    final v = int.parse(s.length == 6 ? 'FF$s' : s, radix: 16);
    return Color(v);
  } catch (_) {
    return fallback;
  }
}

Color parseHexColor(Object? value, [Color fallback = SchoolColors.primary]) {
  if (value is String) return colorFromHex(value, fallback);
  return fallback;
}

DateTime? toDate(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val);
  try {
    return val.toDate(); // Handles Firebase Timestamp
  } catch (_) {}
  return null;
}

class Hoverable extends HookWidget {
  const Hoverable({
    super.key,
    required this.builder,
    this.onTap,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget Function(bool isHovered) builder;
  final VoidCallback? onTap;
  final MouseCursor cursor;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);

    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: Semantics(
        button: onTap != null,
        child: GestureDetector(onTap: onTap, child: builder(isHovered.value)),
      ),
    );
  }
}

void showClassSwitcher({
  required BuildContext context,
  required List<Map<String, dynamic>> classes,
  required String? currentClassId,
  required ValueChanged<String> onSelect,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: isDark ? SchoolColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewPaddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: SchoolColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.selectClass.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: SchoolColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cls = classes[index];
                final id = cls['id']?.toString() ?? '';
                final name = cls['name']?.toString() ?? 'Class';
                final isSelected = id == currentClassId;

                return _SwitcherItem(
                  name: name,
                  isSelected: isSelected,
                  onTap: () {
                    onSelect(id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _SwitcherItem extends StatelessWidget {
  const _SwitcherItem({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? (isDark ? SchoolColors.primary.withOpacity(0.2) : SchoolColors.primary.withOpacity(0.1))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? SchoolColors.primary.withOpacity(0.3)
                  : (isDark ? SchoolColors.darkBorder : SchoolColors.border),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? SchoolColors.primary : SchoolColors.darkSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: isSelected ? Colors.white : SchoolColors.darkMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.white : SchoolColors.primary)
                        : (isDark ? Colors.white : SchoolColors.text),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: SchoolColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
