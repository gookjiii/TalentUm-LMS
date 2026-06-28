import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class BulkClassCreateScreen extends StatefulWidget {
  const BulkClassCreateScreen({super.key});

  @override
  State<BulkClassCreateScreen> createState() => _BulkClassCreateScreenState();
}

class _ClassDraft {
  final TextEditingController controller;
  Color color;

  _ClassDraft({required String name, required this.color})
    : controller = TextEditingController(text: name);

  void dispose() => controller.dispose();
}

class _BulkClassCreateScreenState extends State<BulkClassCreateScreen> {
  final List<_ClassDraft> _drafts = [
    _ClassDraft(name: '', color: SchoolColors.primary),
  ];
  bool _loading = false;

  final List<Color> _availableColors = [
    SchoolColors.primary,
    SchoolColors.secondary,
    SchoolColors.accent,
    SchoolColors.green,
    SchoolColors.orange,
    SchoolColors.purple,
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
  ];

  void _addMore() => setState(() {
    final lastColor = _drafts.lastOrNull?.color ?? SchoolColors.primary;
    final nextIdx =
        (_availableColors.indexOf(lastColor) + 1) % _availableColors.length;
    _drafts.add(_ClassDraft(name: '', color: _availableColors[nextIdx]));
  });

  void _pasteList() async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importList),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pasteClassNamesSeparated),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Mathematics 10A\nPhysics 11B\nHistory 9C",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.unknownKey),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.import),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      final names = ctrl.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        setState(() {
          for (var d in _drafts) d.dispose();
          _drafts.clear();
          for (int i = 0; i < names.length; i++) {
            _drafts.add(
              _ClassDraft(
                name: names[i],
                color: _availableColors[i % _availableColors.length],
              ),
            );
          }
        });
      }
    }
    ctrl.dispose();
  }

  Future<void> _createAll() async {
    final validDrafts = _drafts
        .where((d) => d.controller.text.trim().isNotEmpty)
        .toList();
    if (validDrafts.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repo = AppScope.of(context).repository;
      for (final d in validDrafts) {
        await repo.createClass(
          name: d.controller.text.trim(),
          coverColor:
              '#${d.color.value.toRadixString(16).substring(2).toUpperCase()}',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lớp học đã được tạo thành công: ${validDrafts.length}',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final d in _drafts) d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.creatingClasses),
        actions: [
          TextButton.icon(
            onPressed: _pasteList,
            icon: const Icon(Icons.content_paste_rounded, size: 18),
            label: Text(l10n.importList),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.coolFactory, style: AppTextStyle.display(context)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.enterTheNamesOfThe,
                    style: TextStyle(color: SchoolColors.muted, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            StaggeredList(
              children: [
                for (int i = 0; i < _drafts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ClassDraftRow(
                      draft: _drafts[i],
                      onRemove: _drafts.length > 1
                          ? () => setState(() => _drafts.removeAt(i))
                          : null,
                      availableColors: _availableColors,
                      onColorChange: (c) =>
                          setState(() => _drafts[i].color = c),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _addMore,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addMore),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Hero(
            tag: 'bulk_create_btn',
            child: FilledButton.icon(
              onPressed: _loading ? null : _createAll,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(l10n.createAllClasses),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassDraftRow extends StatelessWidget {
  const _ClassDraftRow({
    required this.draft,
    this.onRemove,
    required this.availableColors,
    required this.onColorChange,
  });

  final _ClassDraft draft;
  final VoidCallback? onRemove;
  final List<Color> availableColors;
  final ValueChanged<Color> onColorChange;

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ListenableBuilder(
            listenable: draft.controller,
            builder: (context, _) => ClassBadge(
              name: draft.controller.text.isEmpty ? "?" : draft.controller.text,
              color: draft.color,
              size: 48,
              radius: 12,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: draft.controller,
                  decoration: const InputDecoration(
                    hintText: "E.g. Math 101",
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final color in availableColors)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => onColorChange(color),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: draft.color == color
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                                boxShadow: [
                                  if (draft.color == color)
                                    const BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: SchoolColors.red,
              ),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
