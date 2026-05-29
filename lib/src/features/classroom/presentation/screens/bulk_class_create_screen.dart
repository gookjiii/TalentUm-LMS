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

class _BulkClassCreateScreenState extends State<BulkClassCreateScreen> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  bool _loading = false;

  void _addMore() => setState(() => _controllers.add(TextEditingController()));

  Future<void> _createAll() async {
    final names = _controllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repo = AppScope.of(context).repository;
      for (final name in names) {
        await repo.createClass(name: name);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Создано классов: ${names.length}')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.creatingClasses)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.coolFactory,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              AppLocalizations.of(context)!.enterTheNamesOfThe,
              style: TextStyle(color: SchoolColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controllers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => SchoolCard(
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    hintText: 'Напр: 7-й класс AppLocalizations.of(context)!.unknownKey10',
                    prefixIcon: const Icon(Icons.school_rounded),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _controllers.length > 1
                        ? IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                setState(() => _controllers.removeAt(i)),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _addMore,
              icon: const Icon(Icons.add_rounded),
              label: Text(AppLocalizations.of(context)!.addMore),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _loading ? null : _createAll,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppLocalizations.of(context)!.createAllClasses),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
