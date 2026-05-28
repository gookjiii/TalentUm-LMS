import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/utils/reload_app.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key, required this.onJoinClass});
  final VoidCallback onJoinClass;

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  bool _loading = true;
  Map<String, dynamic> _userData = {};
  int _assignmentsCount = 0;
  String _avgGrade = '—';
  String _classesLabel = 'Без класса';
  bool _teacherRequestSent = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid != null) {
      final doc = await repo.firestore.collection('users').doc(uid).get();

      int aCount = 0;
      double totalScore = 0;
      int gradedCount = 0;

      final submissions = await repo.firestore
          .collection('submissions')
          .where('studentId', isEqualTo: uid)
          .get();
      aCount = submissions.docs.length;

      for (var s in submissions.docs) {
        final score = s.data()['score'];
        if (score is num) {
          totalScore += score;
          gradedCount++;
        }
      }

      String avg = '—';
      if (gradedCount > 0) {
        avg = (totalScore / gradedCount).toStringAsFixed(1);
      }

      // Fetch actual class names dynamically from Firestore to replace hardcoded '9Б класс'
      final classesSnap = await repo.firestore
          .collection('classes')
          .where('studentIds', arrayContains: uid)
          .get();
      final classNames = classesSnap.docs
          .map((d) => d.data()['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      final actualGrade = classNames.isEmpty
          ? 'Без класса'
          : classNames.join(', ');

      final requestDoc = await repo.firestore.collection('teacher_requests').doc(uid).get();

      if (mounted) {
        setState(() {
          _userData = doc.data() ?? {};
          _assignmentsCount = aCount;
          _avgGrade = avg;
          _classesLabel = actualGrade;
          _teacherRequestSent = requestDoc.exists;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final name = _userData['name'] ?? user?.displayName ?? 'Ученик';
    final email = user?.email ?? '';
    final grade = _userData['grade'] ?? _classesLabel;
    final appState = AppScope.of(context).appState;
    final settings = _userData['settings'] as Map<String, dynamic>? ?? {};

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
          children: [
            Text(
              l10n.profile,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Profile Card
            _ProfileCard(
              name: name,
              sub: '$grade · ${l10n.student}',
              isTeacher: false,
              avatarUrl: _userData['avatarUrl'] as String?,
              onEditAvatar: () => _pickAndUploadAvatar(context),
              streak: _userData['streak'] as int? ?? 0,
            ),

            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    label: l10n.avgGrade.toUpperCase(),
                    value: _avgGrade,
                    color: SchoolColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMiniCard(
                    label: l10n.assignments.toUpperCase(),
                    value: _assignmentsCount.toString(),
                    color: SchoolColors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMiniCard(
                    label: l10n.badges.toUpperCase(),
                    value: _userData['badgesCount']?.toString() ?? '0',
                    color: SchoolColors.yellow,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _SettingsGroup(
              label: l10n.studentAccount.split(' ')[1],
              children: [
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  color: SchoolColors.primary,
                  label: 'Личные данные',
                  sub: name,
                  onTap: () => _editName(context, name),
                ),
                _SettingsRow(
                  icon: Icons.email_outlined,
                  color: SchoolColors.yellow,
                  label: l10n.email,
                  sub: email,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Для смены email обратитесь к учителю'),
                    ),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.add_circle_outline_rounded,
                  color: SchoolColors.green,
                  label: l10n.joinClass,
                  sub: 'Использовать код приглашения',
                  onTap: widget.onJoinClass,
                ),
                _SettingsRow(
                  icon: Icons.school_outlined,
                  color: SchoolColors.accent,
                  label: 'Доступ учителя',
                  sub: _teacherRequestSent ? 'Запрос отправлен' : 'Запросить права учителя',
                  onTap: _teacherRequestSent ? null : _requestTeacherAccess,
                  last: true,
                ),
              ],
            ),

            _SettingsGroup(
              label: l10n.notifications,
              children: [
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  color: SchoolColors.red,
                  label: 'Push-уведомления',
                  sub: 'Разрешены для чата и заданий',
                  right: _CustomToggle(
                    on: settings['pushEnabled'] ?? true,
                    onChanged: (v) => _updateSetting('pushEnabled', v),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: SchoolColors.primary,
                  label: 'Новые сообщения',
                  sub: 'Только от учителей',
                  right: _CustomToggle(
                    on: settings['msgNotifs'] ?? true,
                    onChanged: (v) => _updateSetting('msgNotifs', v),
                  ),
                  last: true,
                ),
              ],
            ),

            _SettingsGroup(
              label: 'Оформление',
              children: [
                _SettingsRow(
                  icon: Icons.dark_mode_outlined,
                  color: SchoolColors.accent,
                  label: l10n.darkMode,
                  sub: appState.isDarkMode ? 'Включена' : 'Системная',
                  right: _CustomToggle(
                    on: appState.isDarkMode,
                    onChanged: (v) => appState.toggleDarkMode(),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.language_rounded,
                  color: SchoolColors.green,
                  label: l10n.language,
                  sub: 'Русский (ru)',
                  onTap: () {},
                  last: true,
                ),
              ],
            ),

            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _confirmSignOut(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: SchoolColors.red,
                side: BorderSide(color: SchoolColors.red.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.signOut),
            ),
            const SizedBox(height: 16),
            const Text(
              'School World v 2.4.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: SchoolColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestTeacherAccess() async {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) return;
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Доступ учителя'),
        content: const Text('Отправить запрос на получение прав учителя? Администратор должен будет одобрить его.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
    
    if (ok == true) {
      setState(() => _loading = true);
      await repo.firestore.collection('teacher_requests').doc(uid).set({
        'userId': uid,
        'name': _userData['name'] ?? 'Ученик',
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _loadData();
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) return;

    await repo.firestore.collection('users').doc(uid).set({
      'settings': {key: value},
    }, SetOptions(merge: true));
    _loadData();
  }

  Future<void> _editName(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editProfile),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      if (!context.mounted) return;
      final repo = AppScope.of(context).repository;
      await repo.updateProfile(
        name: controller.text.trim(),
        firstName: controller.text.trim().split(' ')[0],
        lastName: '',
      );
      _loadData();
    }
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    if (!context.mounted) return;
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      final path =
          'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      Map<String, dynamic>? uploadResult;
      if (file.bytes != null) {
        uploadResult = await repo.uploadFileWeb(path, file.bytes!);
      } else if (file.path != null) {
        uploadResult = await repo.uploadFile(path, File(file.path!));
      }

      if (uploadResult != null) {
        final url = uploadResult['url'] as String?;
        if (url != null && url.isNotEmpty) {
          await repo.updateProfile(avatarUrl: url);
        }
      }
      _loadData();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.signOut}?'),
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

    if (ok == true && context.mounted) {
      final scope = AppScope.of(context);
      scope.appState.resetSession();
      await scope.repository.signOut();
      reloadApp();
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.sub,
    this.isTeacher = false,
    this.avatarUrl,
    this.onEditAvatar,
    this.streak = 0,
  });
  final String name, sub;
  final bool isTeacher;
  final String? avatarUrl;
  final VoidCallback? onEditAvatar;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isTeacher ? SchoolColors.red : SchoolColors.primary)
                        .withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              SchoolAvatar(
                name: name,
                avatarUrl: avatarUrl,
                radius: 36,
                onEditAvatar: onEditAvatar,
                showBorder: true,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? SchoolColors.darkMuted
                            : SchoolColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!isTeacher) ...[
                          StatusChip(
                            label: '$streak дней ударно',
                            color: SchoolColors.yellow.withValues(alpha: 0.12),
                            textColor: SchoolColors.yellow,
                            icon: Icons.auto_awesome,
                            iconSize: 11,
                          ),
                          const SizedBox(width: 8),
                        ],
                        StatusChip(
                          label: isTeacher ? 'Учитель' : 'Ученик',
                          color: isTeacher
                              ? SchoolColors.red
                              : SchoolColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatefulWidget {
  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;

  @override
  State<_StatMiniCard> createState() => _StatMiniCardState();
}

class _StatMiniCardState extends State<_StatMiniCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : (_hovered ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            borderRadius: 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 45,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.2),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: widget.color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? SchoolColors.darkMuted
                            : SchoolColors.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatefulWidget {
  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
    this.onTap,
    this.right,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String label, sub;
  final VoidCallback? onTap;
  final Widget? right;
  final bool last;

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: widget.onTap != null
          ? (_) => setState(() => _hovered = true)
          : null,
      onExit: widget.onTap != null
          ? (_) => setState(() => _hovered = false)
          : null,
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _pressed = false)
            : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _hovered
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : widget.color.withValues(alpha: 0.03))
                  : Colors.transparent,
              border: widget.last
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : SchoolColors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hovered
                        ? widget.color.withValues(alpha: 0.18)
                        : widget.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      if (_hovered)
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Icon(widget.icon, size: 19, color: widget.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.sub,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? SchoolColors.darkMuted
                              : SchoolColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                widget.right ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? SchoolColors.darkMuted
                          : SchoolColors.muted,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomToggle extends StatelessWidget {
  const _CustomToggle({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: on,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: SchoolColors.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: SchoolColors.border,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
