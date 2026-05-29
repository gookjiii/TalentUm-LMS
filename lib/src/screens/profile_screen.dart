import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';

import '../../main.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  bool _uploading = false;
  bool _editMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = AppScope.of(context).repository;
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _editMode ? Icons.close_rounded : Icons.edit_outlined,
                key: ValueKey(_editMode),
              ),
            ),
            onPressed: () => setState(() => _editMode = !_editMode),
            tooltip: _editMode ? AppLocalizations.of(context)!.unknownKey : AppLocalizations.of(context)!.edit,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        streamFactory: () => repo.userDocStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const BrandedLoader();
          }

          final data = snapshot.data?.data() ?? {};
          final name =
              data['name']?.toString() ?? user?.displayName ?? AppLocalizations.of(context)!.user;
          final email = user?.email ?? '';
          final role = data['role']?.toString() ?? 'student';
          final avatarUrl = data['avatarUrl']?.toString();

          if (_nameController.text.isEmpty) {
            _nameController.text = name;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero banner ─────────────────────────────────
                _ProfileHero(
                  name: name,
                  email: email,
                  role: role,
                  avatarUrl: avatarUrl,
                  uploading: _uploading,
                  onPickAvatar: _pickAndUploadAvatar,
                  isDark: isDark,
                  l10n: l10n,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        // ── Edit form (animated expand) ──────────
                        AnimatedSize(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeInOutCubic,
                          child: _editMode
                              ? _EditForm(
                                  controller: _nameController,
                                  loading: _loading,
                                  onSave: _updateProfile,
                                  l10n: l10n,
                                )
                              : const SizedBox.shrink(),
                        ),

                        // ── Stats (students only) ────────────────
                        if (role == 'student') ...[
                          const SizedBox(height: 20),
                          _StatsRow(data: data, l10n: l10n),
                        ],

                        const SizedBox(height: 20),

                        // ── Actions ──────────────────────────────
                        SchoolCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _ProfileTile(
                                icon: Icons.logout_rounded,
                                label: l10n.signOut,
                                iconColor: SchoolColors.red,
                                labelColor: SchoolColors.red,
                                onTap: () => _signOut(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    setState(() => _uploading = true);
    try {
      final file = result.files.first;
      final repo = AppScope.of(context).repository;
      final uid = repo.uid;
      if (uid == null) throw Exception(AppLocalizations.of(context)!.notLoggedIn);

      final path =
          'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      Map<String, dynamic>? uploadResult;
      if (file.bytes != null) {
        uploadResult = await repo.uploadFileWeb(path, file.bytes!);
      } else if (file.path != null) {
        uploadResult = await repo.uploadFile(path, File(file.path!));
      }

      if (uploadResult != null && uploadResult['url'] != null) {
        await repo.firestore.collection('users').doc(uid).update({
          'avatarUrl': uploadResult['url'],
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.avatarUpdated)));
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUploadAvatar(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _updateProfile() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.nameEmptyError)));
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = AppScope.of(context).repository;
      final uid = repo.uid;
      if (uid == null) throw Exception(AppLocalizations.of(context)!.notLoggedIn);

      await repo.firestore.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
      });
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        _nameController.text.trim(),
      );

      if (mounted) {
        setState(() => _editMode = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileUpdatedDesc)));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateProfile(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.confirmSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: SchoolColors.red,
              minimumSize: const Size(100, 44),
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AppScope.of(context).repository.auth.signOut();
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────────────────────────
class _ProfileHero extends StatefulWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
    required this.uploading,
    required this.onPickAvatar,
    required this.isDark,
    required this.l10n,
  });

  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback onPickAvatar;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  bool _avatarHovered = false;

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.role == 'teacher';
    final roleColor = isTeacher ? SchoolColors.green : SchoolColors.primary;
    final roleLabel = isTeacher ? widget.l10n.teacher : widget.l10n.student;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTeacher
              ? [const Color(0xFF065F46), const Color(0xFF059669)]
              : [const Color(0xFF1D4ED8), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative blob
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              child: Column(
                children: [
                  // Avatar
                  MouseRegion(
                    onEnter: (_) => setState(() => _avatarHovered = true),
                    onExit: (_) => setState(() => _avatarHovered = false),
                    child: GestureDetector(
                      onTap: widget.onPickAvatar,
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: _avatarHovered ? 0.8 : 0.4,
                                ),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.avatarUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: widget.avatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          _DefaultAvatar(name: widget.name),
                                    )
                                  : _DefaultAvatar(name: widget.name),
                            ),
                          ),
                          // Upload overlay
                          if (widget.uploading)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black45,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          // Camera icon on hover
                          if (!widget.uploading)
                            Positioned.fill(
                              child: AnimatedOpacity(
                                opacity: _avatarHovered ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 180),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.45),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          // Edit badge
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: roleColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: roleColor.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTeacher
                              ? Icons.school_rounded
                              : Icons.person_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SchoolColors.primary,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EDIT FORM
// ─────────────────────────────────────────────────────────────────
class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.controller,
    required this.loading,
    required this.onSave,
    required this.l10n,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSave;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.editProfile,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.name,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          loading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(l10n.saveChanges),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data, required this.l10n});
  final Map<String, dynamic> data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final classIds = List<String>.from(data['classIds'] ?? []);
    final repo = AppScope.of(context).repository;

    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.class_outlined,
            label: l10n.todaysClasses,
            value: classIds.length,
            color: SchoolColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<QuerySnapshot?>(
            future: classIds.isEmpty
                ? Future<QuerySnapshot?>.value(null)
                : repo.firestore
                      .collection('assignments')
                      .where('classId', whereIn: classIds)
                      .get(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return _MiniStatCard(
                icon: Icons.assignment_outlined,
                label: l10n.assignments,
                value: count,
                color: SchoolColors.orange,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          GradientIconBox(
            icon: icon,
            colors: [color, Color.lerp(color, Colors.white, 0.3) ?? color],
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(height: 10),
          AnimatedCounter(
            value: value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: SchoolColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PROFILE TILE
// ─────────────────────────────────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              (iconColor ??
                      (isDark ? SchoolColors.darkMuted : SchoolColors.muted))
                  .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color:
              iconColor ??
              (isDark ? SchoolColors.darkMuted : SchoolColors.muted),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: labelColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
