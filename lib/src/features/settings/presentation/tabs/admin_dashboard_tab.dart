import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/firebase/storage_provider.dart';
import '../screens/user_management_screen.dart';
import '../screens/admin_classes_screen.dart';
import '../screens/admin_teacher_requests_screen.dart';

class AdminDashboardTab extends ConsumerStatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Админ-панель',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'Управление системой и аналитика активности',
              style: TextStyle(
                color: SchoolColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            // Stats Layout
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: repo.firestore.collection('users').get(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return _StatCard(
                        title: 'Всего пользователей',
                        value: count.toString(),
                        icon: Icons.people_rounded,
                        color: SchoolColors.primary,
                        loading: snapshot.connectionState == ConnectionState.waiting,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<QuerySnapshot>(
                    future: repo.firestore.collection('rooms').get(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return _StatCard(
                        title: 'Активные чаты',
                        value: count.toString(),
                        icon: Icons.chat_bubble_rounded,
                        color: SchoolColors.green,
                        loading: snapshot.connectionState == ConnectionState.waiting,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<QuerySnapshot>(
                    future: repo.firestore
                        .collectionGroup('messages')
                        .where('createdAt', isGreaterThanOrEqualTo: startOfToday)
                        .get(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return _StatCard(
                        title: 'Сообщений сегодня',
                        value: count.toString(),
                        icon: Icons.auto_graph_rounded,
                        color: SchoolColors.purple,
                        loading: snapshot.connectionState == ConnectionState.waiting,
                      );
                    },
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: repo.firestore.collection('users').get(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return _StatCard(
                          title: 'Всего пользователей',
                          value: count.toString(),
                          icon: Icons.people_rounded,
                          color: SchoolColors.primary,
                          loading: snapshot.connectionState == ConnectionState.waiting,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: repo.firestore.collection('rooms').get(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return _StatCard(
                          title: 'Активные чаты',
                          value: count.toString(),
                          icon: Icons.chat_bubble_rounded,
                          color: SchoolColors.green,
                          loading: snapshot.connectionState == ConnectionState.waiting,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: repo.firestore
                          .collectionGroup('messages')
                          .where('createdAt', isGreaterThanOrEqualTo: startOfToday)
                          .get(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return _StatCard(
                          title: 'Сообщений сегодня',
                          value: count.toString(),
                          icon: Icons.auto_graph_rounded,
                          color: SchoolColors.purple,
                          loading: snapshot.connectionState == ConnectionState.waiting,
                        );
                      },
                    ),
                  ),
                ],
              ),



            const SizedBox(height: 32),
            const SectionHeader(title: 'Брендинг приложения'),
            const SizedBox(height: 16),
            const _BrandingSettingsCard(),

            const SizedBox(height: 32),
            const SectionHeader(title: 'Быстрые действия'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _AdminActionTile(
                  title: 'Пользователи',
                  subtitle: 'Управление ролями и бан',
                  icon: Icons.manage_accounts_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                _AdminActionTile(
                  title: 'Все классы',
                  subtitle: 'Просмотр и модерация',
                  icon: Icons.school_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminClassesScreen(),
                      ),
                    );
                  },
                ),
                _AdminActionTile(
                  title: 'Заявки в учителя',
                  subtitle: 'Модерация запросов',
                  icon: Icons.how_to_reg_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminTeacherRequestsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
            const SectionHeader(title: 'Последние пользователи'),
            const SizedBox(height: 16),
            FutureBuilder<QuerySnapshot>(
              future: repo.firestore
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .get(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SchoolCard(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (docs.isEmpty) {
                  return const SchoolCard(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Нет данных')),
                  );
                }
                return SchoolCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < docs.length; i++) ...[
                        _LogItem(
                          user: docs[i].get('name') ?? 'User',
                          action: 'зарегистрировался',
                          target: '',
                          time: _formatTime(docs[i].get('createdAt')),
                          icon: Icons.person_add_rounded,
                          iconColor: SchoolColors.primary,
                        ),
                        if (i < docs.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts is! Timestamp) return 'недавно';
    final date = ts.toDate();
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('d MMM').format(date);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.loading = false,
  });

  final String title, value;
  final IconData icon;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          if (loading)
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          Text(
            title,
            style: const TextStyle(
              color: SchoolColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionTile extends HookWidget {
  const _AdminActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final color = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isHovered.value ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: AnimatedSlide(
            offset: isHovered.value ? const Offset(0, -0.03) : Offset.zero,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: MediaQuery.sizeOf(context).width < 600 ? double.infinity : 280,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isHovered.value
                      ? color.withValues(alpha: 0.4)
                      : SchoolColors.border.withValues(alpha: 0.6),
                  width: isHovered.value ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHovered.value
                        ? color.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: isHovered.value ? 24 : 10,
                    offset: isHovered.value
                        ? const Offset(0, 12)
                        : const Offset(0, 4),
                    spreadRadius: isHovered.value ? -4 : 0,
                  ),
                  BoxShadow(
                    color: isHovered.value
                        ? color.withValues(alpha: 0.1)
                        : Colors.transparent,
                    blurRadius: isHovered.value ? 8 : 1,
                    offset: isHovered.value ? const Offset(0, 4) : Offset.zero,
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: isHovered.value ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isHovered.value
                              ? [color, color.withValues(alpha: 0.8)]
                              : [
                                  color.withValues(alpha: 0.1),
                                  color.withValues(alpha: 0.05),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(
                              alpha: isHovered.value ? 0.4 : 0.0,
                            ),
                            blurRadius: isHovered.value ? 12 : 1,
                            offset: isHovered.value
                                ? const Offset(0, 4)
                                : Offset.zero,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: isHovered.value ? Colors.white : color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: SchoolColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(left: isHovered.value ? 8.0 : 0.0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isHovered.value ? 1.0 : 0.4,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandingSettingsCard extends StatefulWidget {
  const _BrandingSettingsCard();

  @override
  State<_BrandingSettingsCard> createState() => _BrandingSettingsCardState();
}

class _BrandingSettingsCardState extends State<_BrandingSettingsCard> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _logoUrl;

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;

    setState(() => _loading = true);
    try {
      final file = result.files.first;
      final storageProvider =
          CloudinaryStorageProvider.fromEnvironmentOrFirebase();
      final path = 'system/logo_${DateTime.now().millisecondsSinceEpoch}';

      String downloadUrl;
      if (kIsWeb) {
        if (file.bytes == null) throw Exception('No file bytes');
        final res = await storageProvider.uploadFileWeb(path, file.bytes!);
        downloadUrl = res['url'] as String;
      } else {
        if (file.path == null) throw Exception('No file path');
        final res = await storageProvider.uploadFile(path, File(file.path!));
        downloadUrl = res['url'] as String;
      }

      setState(() => _logoUrl = downloadUrl);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Логотип загружен')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    return CachedStreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      streamFactory: () => repo.systemSettingsStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final currentName = data?['appName'] as String? ?? 'TalentUm';
        final currentLogo = data?['logoUrl'] as String?;
        if (!_loading && _nameController.text.isEmpty) {
          _nameController.text = currentName;
        }
        if (!_loading && _logoUrl == null) {
          _logoUrl = currentLogo;
        }

        return SchoolCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _loading ? null : _pickLogo,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _logoUrl!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const SchoolLogo(size: 64),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: SchoolColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Название приложения',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(),
                            hintText: 'Введите название',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          try {
                            await repo.updateSystemSettings(
                              appName: _nameController.text.trim(),
                              logoUrl: _logoUrl,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Настройки сохранены'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка: $e')),
                              );
                            }
                          } finally {
                            if (context.mounted)
                              setState(() => _loading = false);
                          }
                        },
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Сохранить изменения'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogItem extends StatelessWidget {
  const _LogItem({
    required this.user,
    required this.action,
    required this.target,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  final String user, action, target, time;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: iconColor, size: 20),
      title: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          children: [
            TextSpan(
              text: user,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' $action user '),
            TextSpan(
              text: target,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: SchoolColors.muted, fontSize: 11),
      ),
    );
  }
}


