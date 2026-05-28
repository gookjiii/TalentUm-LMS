import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class ClassSettingsScreen extends StatefulWidget {
  const ClassSettingsScreen({super.key, required this.classId});
  final String classId;

  @override
  State<ClassSettingsScreen> createState() => _ClassSettingsScreenState();
}

class _ClassSettingsScreenState extends State<ClassSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки класса'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        streamFactory: () => repo.firestore
            .collection('classes')
            .doc(widget.classId)
            .snapshots(),
        keys: [widget.classId],
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data();
          if (data == null) return const Center(child: Text('Класс не найден'));

          final appState = AppScope.of(context).appState;
          final isLeadOfClass = appState.isLeadTeacher ||
              (data['teacherId'] != null && data['teacherId'] == repo.uid);

          final permissions = Map<String, dynamic>.from(
            data['permissions'] ?? {},
          );
          final canStudentChat = permissions['canStudentChat'] ?? true;
          final canStudentPost = permissions['canStudentPost'] ?? true;
          final requireApproval = permissions['requireApproval'] ?? false;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SectionHeader(title: 'Общие настройки'),
              const SizedBox(height: 16),
              SchoolCard(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Название класса'),
                      subtitle: Text(data['name'] ?? ''),
                      trailing: const Icon(Icons.edit_rounded, size: 20),
                      onTap: () => _editName(context, data['name'] ?? ''),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Код приглашения'),
                      subtitle: Text(data['inviteCode'] ?? 'Нет кода'),
                      trailing: const Icon(Icons.refresh_rounded, size: 20),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Разрешения для учеников'),
              const SizedBox(height: 16),
              SchoolCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Общение в чате'),
                      subtitle: const Text(
                        'Разрешить ученикам писать сообщения в общий чат',
                      ),
                      value: canStudentChat,
                      activeColor: SchoolColors.primary,
                      onChanged: (val) =>
                          _updatePermission('canStudentChat', val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Публикации в ленте'),
                      subtitle: const Text(
                        'Разрешить ученикам создавать посты в ленте новостей',
                      ),
                      value: canStudentPost,
                      activeColor: SchoolColors.primary,
                      onChanged: (val) =>
                          _updatePermission('canStudentPost', val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Модерация вступления'),
                      subtitle: const Text(
                        'Требовать одобрение учителя для новых участников',
                      ),
                      value: requireApproval,
                      activeColor: SchoolColors.primary,
                      onChanged: (val) =>
                          _updatePermission('requireApproval', val),
                    ),
                  ],
                ),
              ),
              if (isLeadOfClass) ...[
                const SizedBox(height: 32),
                const SectionHeader(title: 'Опасная зона'),
                const SizedBox(height: 16),
                SchoolCard(
                  child: ListTile(
                    leading: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Удалить класс',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Это действие нельзя отменить. Все данные будут удалены.',
                    ),
                    onTap: () => _confirmDelete(context),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _updatePermission(String key, bool value) async {
    final repo = AppScope.of(context).repository;
    await repo.firestore.collection('classes').doc(widget.classId).set({
      'permissions': {key: value},
    }, SetOptions(merge: true));
  }

  Future<void> _editName(BuildContext context, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить название'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Название класса'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final repo = AppScope.of(context).repository;
      await repo.firestore.collection('classes').doc(widget.classId).update({
        'name': ctrl.text.trim(),
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить класс?'),
        content: const Text(
          'Все сообщения, задания и оценки будут безвозвратно удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('УДАЛИТЬ'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      // Implement recursive deletion in production
      Navigator.pop(context);
    }
  }
}
