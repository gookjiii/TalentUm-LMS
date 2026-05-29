import 'package:school_world/l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.unknownKey),
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
          if (data == null) return Center(child: Text(AppLocalizations.of(context)!.unknownKey));

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
              SectionHeader(title: AppLocalizations.of(context)!.generalSettings1),
              const SizedBox(height: 16),
              SchoolCard(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.unknownKey),
                      subtitle: Text(data['name'] ?? ''),
                      trailing: const Icon(Icons.edit_rounded, size: 20),
                      onTap: () => _editName(context, data['name'] ?? ''),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.invitationCode),
                      subtitle: Text(data['inviteCode'] ?? AppLocalizations.of(context)!.unknownKey11),
                      trailing: const Icon(Icons.refresh_rounded, size: 20),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SectionHeader(title: AppLocalizations.of(context)!.studentPermissions),
              const SizedBox(height: 16),
              SchoolCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.chat),
                      subtitle: Text(
                        AppLocalizations.of(context)!.allowStudentsToWriteMessages,
                      ),
                      value: canStudentChat,
                      activeColor: SchoolColors.primary,
                      onChanged: (val) =>
                          _updatePermission('canStudentChat', val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.publicationsInTheFeed),
                      subtitle: Text(
                        AppLocalizations.of(context)!.allowStudentsToCreateNews,
                      ),
                      value: canStudentPost,
                      activeColor: SchoolColors.primary,
                      onChanged: (val) =>
                          _updatePermission('canStudentPost', val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.moderationOfEntry),
                      subtitle: Text(
                        AppLocalizations.of(context)!.requireTeacherApprovalForNew,
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
                SectionHeader(title: AppLocalizations.of(context)!.dangerZone),
                const SizedBox(height: 16),
                SchoolCard(
                  child: ListTile(
                    leading: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.deleteClass,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.thisActionCannotBeUndone1,
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
        title: Text(AppLocalizations.of(context)!.changeName),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: AppLocalizations.of(context)!.unknownKey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.unknownKey),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.save),
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
        title: Text(AppLocalizations.of(context)!.deleteAClass),
        content: Text(
          AppLocalizations.of(context)!.allMessagesAssignmentsAndGrades,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.unknownKey),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete1),
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
