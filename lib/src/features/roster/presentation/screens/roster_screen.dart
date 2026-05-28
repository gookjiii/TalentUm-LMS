import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/features/classroom/presentation/screens/class_settings_screen.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key, this.classId});
  final String? classId;

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _classStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final repo = AppScope.of(context).repository;
      final appState = AppScope.of(context).appState;
      final effectiveClassId = widget.classId ?? appState.selectedClassId;
      if (effectiveClassId != null) {
        _classStream = repo.firestore
            .collection('classes')
            .doc(effectiveClassId)
            .snapshots();
        _initialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context).appState;
    final l10n = AppLocalizations.of(context)!;
    final effectiveClassId = widget.classId ?? appState.selectedClassId;

    if (effectiveClassId == null) {
      return Scaffold(body: Center(child: Text(l10n.selectClassFirst)));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _classStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data();
          if (data == null) return Center(child: Text(l10n.classNotFound));

          final teacherId = data['teacherId']?.toString() ?? '';
          final studentIds = List<String>.from(data['studentIds'] ?? []);
          final adminIds = List<String>.from(data['adminIds'] ?? []);

          return Column(
            children: [
              _MembersHeader(count: 1 + studentIds.length),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                  children: [
                    _TeacherCard(teacherId: teacherId),
                    ...studentIds.map(
                      (id) => _MemberCard(
                        studentId: id,
                        classId: effectiveClassId,
                        isAdmin: adminIds.contains(id),
                        onToggleAdmin: () => _toggleAdmin(
                          effectiveClassId,
                          id,
                          adminIds.contains(id),
                        ),
                        onRemove: () =>
                            _confirmRemove(context, effectiveClassId, id),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleAdmin(String classId, String studentId, bool isAdmin) {
    final repo = AppScope.of(context).repository;
    return repo.toggleClassAdmin(
      classId: classId,
      userId: studentId,
      isAdmin: !isAdmin,
    );
  }

  Future<void> _removeStudent(String classId, String studentId) {
    final repo = AppScope.of(context).repository;
    return repo.removeUserFromClass(classId: classId, userId: studentId);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    String classId,
    String studentId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFromClass),
        content: Text(l10n.removeFromClassDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: SchoolColors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _removeStudent(classId, studentId);
    }
  }
}

class _MembersHeader extends StatelessWidget {
  const _MembersHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.classRoster,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  l10n.totalParticipants(count),
                  style: const TextStyle(
                    color: SchoolColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (AppScope.of(context).appState.isTeacher) ...[
            IconButton.filledTonal(
              onPressed: () {
                final classId = AppScope.of(context).appState.selectedClassId;
                if (classId != null) {
                  showDialog(
                    context: context,
                    builder: (_) => _AddStudentDialog(classId: classId),
                  );
                }
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              tooltip: 'Добавить ученика',
            ),
            const SizedBox(width: 8),
          ],
          if (AppScope.of(context).appState.isLeadTeacher)
            IconButton.filledTonal(
              onPressed: () {
                final classId = AppScope.of(context).appState.selectedClassId;
                if (classId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassSettingsScreen(classId: classId),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.settings_suggest_rounded, size: 20),
            ),
        ],
      ),
    );
  }
}

class _TeacherCard extends StatefulWidget {
  const _TeacherCard({required this.teacherId});
  final String teacherId;

  @override
  State<_TeacherCard> createState() => _TeacherCardState();
}

class _TeacherCardState extends State<_TeacherCard> {
  Future<Map<String, dynamic>?>? _userFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final repo = AppScope.of(context).repository;
      _userFuture = repo.getUserData(widget.teacherId);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: SchoolCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: SchoolColors.border,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          color: SchoolColors.border,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 12,
                          color: SchoolColors.border,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data;
        final name = data?['name']?.toString() ?? l10n.teacher;
        final avatarUrl = data?['avatarUrl']?.toString();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: SchoolCard(
            child: Row(
              children: [
                SchoolAvatar(
                  name: name,
                  avatarUrl: avatarUrl,
                  radius: 22,
                  userId: widget.teacherId,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.teacher,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SchoolColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: l10n.teacherBadge,
                  color: SchoolColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemberCard extends StatefulWidget {
  const _MemberCard({
    required this.studentId,
    required this.classId,
    required this.isAdmin,
    required this.onToggleAdmin,
    required this.onRemove,
  });
  final String studentId, classId;
  final bool isAdmin;
  final VoidCallback onToggleAdmin, onRemove;

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  Future<Map<String, dynamic>?>? _userFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final repo = AppScope.of(context).repository;
      _userFuture = repo.getUserData(widget.studentId);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: SchoolCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: SchoolColors.border,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          color: SchoolColors.border,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 12,
                          color: SchoolColors.border,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data;
        final name = data?['name']?.toString() ?? l10n.student;
        final avatarUrl = data?['avatarUrl']?.toString();
        final appState = AppScope.of(context).appState;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: SchoolCard(
            onTap: data == null ? null : () => _showUserInfo(context, data),
            child: Row(
              children: [
                SchoolAvatar(
                  name: name,
                  avatarUrl: avatarUrl,
                  radius: 22,
                  userId: widget.studentId,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.isAdmin ? 'Администратор' : 'Участник',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isAdmin
                              ? SchoolColors.primary
                              : SchoolColors.muted,
                          fontWeight: widget.isAdmin
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                  if (appState.isTeacher)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: SchoolColors.muted,
                      ),
                      onSelected: (val) {
                        if (val == 'profile') _showUserInfo(context, data!);
                        if (val == 'edit_name') _editStudentName(context, data!);
                        if (val == 'admin') widget.onToggleAdmin();
                        if (val == 'remove') widget.onRemove();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Text(l10n.profile),
                        ),
                        const PopupMenuItem(
                          value: 'edit_name',
                          child: Text('Редактировать имя'),
                        ),
                        PopupMenuItem(
                          value: 'admin',
                          child: Text(
                            widget.isAdmin
                                ? 'Убрать права админа'
                                : 'Сделать администратором',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(color: SchoolColors.red),
                          ),
                        ),
                      ],
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: SchoolColors.muted,
                      ),
                      onPressed: data == null
                          ? null
                          : () => _showUserInfo(context, data),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editStudentName(BuildContext context, Map<String, dynamic> userData) async {
    final repo = AppScope.of(context).repository;
    final controller = TextEditingController(text: userData['name']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать имя ученика'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Имя ученика',
            hintText: 'Иван Иванов',
          ),
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

    if (ok == true && controller.text.trim().isNotEmpty) {
      final newName = controller.text.trim();
      await repo.firestore.collection('users').doc(widget.studentId).update({
        'name': newName,
        'firstName': newName.split(' ')[0],
      });
      if (mounted) {
        setState(() {
          _userFuture = repo.getUserData(widget.studentId);
        });
      }
    }
  }

  void _showUserInfo(BuildContext context, Map<String, dynamic> userData) {
    final l10n = AppLocalizations.of(context)!;
    final name = userData['name']?.toString() ?? l10n.student;
    final email = userData['email']?.toString();
    final createdAt = userData['createdAt'];
    String dateStr = 'неизвестно';
    if (createdAt is Timestamp) {
      dateStr = DateFormat('d MMMM yyyy', 'ru').format(createdAt.toDate());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SchoolColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SchoolAvatar(
                  name: name,
                  avatarUrl: userData['avatarUrl'],
                  radius: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusChip(
                        label: widget.isAdmin ? 'АДМИНИСТРАТОР' : 'УЧЕНИК',
                        color: widget.isAdmin
                            ? SchoolColors.primary
                            : SchoolColors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.email_outlined, text: email ?? 'Нет email'),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: 'Участник с: $dateStr',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SchoolColors.muted),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog({required this.classId});
  final String classId;

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _emailController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final repo = AppScope.of(context).repository;
      final results = await repo.searchUserByEmail(email);
      setState(() {
        _results = results;
        if (results.isEmpty) _error = 'Пользователь не найден';
      });
    } catch (e) {
      setState(() => _error = 'Ошибка поиска: $e');
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _addUser(String userId) async {
    try {
      final repo = AppScope.of(context).repository;
      await repo.addStudentToClass(classId: widget.classId, userId: userId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить ученика'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email ученика',
                hintText: 'student@email.com',
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _search,
                      ),
              ),
              onSubmitted: (_) => _search(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: SchoolColors.red, fontSize: 13),
                ),
              ),
            ..._results.map(
              (user) => ListTile(
                leading: SchoolAvatar(
                  name: user['name']?.toString() ?? '',
                  radius: 18,
                ),
                title: Text(user['name']?.toString() ?? 'Неизвестный'),
                subtitle: Text(
                  user['email']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: FilledButton(
                  onPressed: () => _addUser(user['id'] as String),
                  child: const Text('Добавить'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}
