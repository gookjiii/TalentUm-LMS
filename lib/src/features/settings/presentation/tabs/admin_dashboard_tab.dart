import 'package:school_world/l10n/app_localizations.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
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
import 'package:school_world/src/utils/string_extensions.dart';
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
  bool _loadingStorage = false;
  bool _cleaningStorage = false;
  Map<String, dynamic>? _storageStats;

  @override
  void initState() {
    super.initState();
    _fetchStorageStats();
  }

  Future<void> _fetchStorageStats() async {
    setState(() => _loadingStorage = true);
    try {
      const apiSecret = String.fromEnvironment('APP_API_SECRET');
      const proxyUrl = String.fromEnvironment('GOOGLE_DRIVE_PROXY_URL');
      if (proxyUrl.isNotEmpty && apiSecret.isNotEmpty) {
        final dio = Dio();
        final res = await dio.get(
          '$proxyUrl/api/admin/storage_stats',
          options: Options(
            headers: {'Authorization': 'Bearer $apiSecret'},
          ),
        );
        if (mounted) {
          setState(() {
            _storageStats = res.data as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching storage stats: $e');
    } finally {
      if (mounted) setState(() => _loadingStorage = false);
    }
  }

  Future<void> _cleanStorage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmCleanup),
        content: Text(
          AppLocalizations.of(context)!.confirmCleanupDesc,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.startCleanup),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cleaningStorage = true);
    try {
      const apiSecret = String.fromEnvironment('APP_API_SECRET');
      const proxyUrl = String.fromEnvironment('GOOGLE_DRIVE_PROXY_URL');
      if (proxyUrl.isNotEmpty && apiSecret.isNotEmpty) {
        final dio = Dio();
        final res = await dio.post(
          '$proxyUrl/api/admin/storage_cleanup',
          data: {'dryRun': false},
          options: Options(
            headers: {'Authorization': 'Bearer $apiSecret'},
          ),
        );
        
        final summary = (res.data as Map<String, dynamic>)['summary'];
        final totalFiles = summary['totalFilesDeleted'] ?? 0;
        final totalBytesSaved = summary['totalBytesSaved'] ?? 0;
        final formattedSize = _formatBytes(totalBytesSaved);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.cleanupSuccess(totalFiles.toString(), formattedSize)),
              backgroundColor: SchoolColors.green,
            ),
          );
        }
        _fetchStorageStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cleanupFailed(e.toString())),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cleaningStorage = false);
    }
  }

  String _formatBytes(dynamic bytes, [int decimals = 2]) {
    if (bytes == null) return '0 B';
    final intBytes = bytes is int ? bytes : (int.tryParse(bytes.toString()) ?? 0);
    if (intBytes <= 0) return '0 B';
    const constSuffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (math.log(intBytes) / math.log(1024)).floor();
    return '${(intBytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${constSuffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: AppLocalizations.of(context)!.adminPanel,
              subtitle: AppLocalizations.of(context)!
                  .systemManagementAndActivityAnalytics,
              padding: EdgeInsets.all(isMobile ? 16 : 32),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Layout
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatFuture(
                          future: repo.firestore.collection('users').get(),
                          title: AppLocalizations.of(context)!.totalUsers,
                          icon: Icons.people_rounded,
                          color: SchoolColors.primary,
                        ),
                        const SizedBox(height: 16),
                        _StatFuture(
                          future: repo.firestore.collection('rooms').get(),
                          title: AppLocalizations.of(context)!.activeChats,
                          icon: Icons.chat_bubble_rounded,
                          color: SchoolColors.green,
                        ),
                        const SizedBox(height: 16),
                        _StatFuture(
                          future: repo.firestore
                              .collectionGroup('messages')
                              .where(
                                'createdAt',
                                isGreaterThanOrEqualTo: startOfToday,
                              )
                              .get(),
                          title: AppLocalizations.of(context)!.postsToday,
                          icon: Icons.edit_calendar_rounded,
                          color: SchoolColors.orange,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _StatFuture(
                            future: repo.firestore.collection('users').get(),
                            title: AppLocalizations.of(context)!.totalUsers,
                            icon: Icons.people_rounded,
                            color: SchoolColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatFuture(
                            future: repo.firestore.collection('rooms').get(),
                            title: AppLocalizations.of(context)!.activeChats,
                            icon: Icons.chat_bubble_rounded,
                            color: SchoolColors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatFuture(
                            future: repo.firestore
                                .collectionGroup('messages')
                                .where(
                                  'createdAt',
                                  isGreaterThanOrEqualTo: startOfToday,
                                )
                                .get(),
                            title: AppLocalizations.of(context)!.postsToday,
                            icon: Icons.auto_graph_rounded,
                            color: SchoolColors.purple,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),
                  SectionHeader(title: AppLocalizations.of(context)!.appBranding),
                  const SizedBox(height: 16),
                  _BrandingSettingsCard(),

                  const SizedBox(height: 32),
                  SectionHeader(title: AppLocalizations.of(context)!.cloudStorageManagement),
                  const SizedBox(height: 16),
                  _buildStorageManagementCard(),
                  const SizedBox(height: 32),
                  SectionHeader(title: AppLocalizations.of(context)!.quickActions1),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _AdminActionTile(
                        title: AppLocalizations.of(context)!.users,
                        subtitle:
                            AppLocalizations.of(context)!.roleManagementAndBan,
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
                        title: AppLocalizations.of(context)!.allClasses,
                        subtitle:
                            AppLocalizations.of(context)!.reviewAndModeration,
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
                        title: AppLocalizations.of(context)!.applicationsForTeachers,
                        subtitle:
                            AppLocalizations.of(context)!.moderationOfRequests,
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
                  SectionHeader(title: AppLocalizations.of(context)!.latestUsers),
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
                        return SchoolCard(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.noData),
                          ),
                        );
                      }
                      return SchoolCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (int i = 0; i < docs.length; i++) ...[
                              _LogItem(
                                user: docs[i].get('name') ?? 'User',
                                action: AppLocalizations.of(context)!.registered,
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
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts is! Timestamp) return AppLocalizations.of(context)!.recently;
    final date = ts.toDate();
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('d MMM').format(date);
  }

  Widget _buildStorageManagementCard() {
    if (_loadingStorage && _storageStats == null) {
      return SchoolCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.loadingCloudStorageStats,
                style: const TextStyle(
                  color: SchoolColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final googleUsed = _storageStats?['googleDrive']?['used'] ?? 0;
    final googleLimit = _storageStats?['googleDrive']?['limit'] ?? 1; // avoid divide by zero
    final googlePct = (googleUsed / googleLimit).clamp(0.0, 1.0);

    final cloudinaryUsed = _storageStats?['cloudinary']?['used'] ?? 0;
    final cloudinaryLimit = _storageStats?['cloudinary']?['limit'] ?? 1;
    final cloudinaryPct = (cloudinaryUsed / cloudinaryLimit).clamp(0.0, 1.0);

    final firebaseUsed = _storageStats?['firebase']?['used'] ?? 0;
    final firebaseLimit = _storageStats?['firebase']?['limit'] ?? 1;
    final firebasePct = (firebaseUsed / firebaseLimit).clamp(0.0, 1.0);

    return SchoolCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStorageRow(
            title: 'Google Drive',
            subtitle: AppLocalizations.of(context)!.googleDriveSubtitle,
            used: googleUsed,
            limit: googleLimit,
            percent: googlePct,
            color: SchoolColors.primary,
            icon: Icons.add_to_drive_rounded,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildStorageRow(
            title: 'Cloudinary',
            subtitle: AppLocalizations.of(context)!.cloudinarySubtitle,
            used: cloudinaryUsed,
            limit: cloudinaryLimit,
            percent: cloudinaryPct,
            color: SchoolColors.orange,
            icon: Icons.cloud_queue_rounded,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildStorageRow(
            title: 'Firebase Storage',
            subtitle: AppLocalizations.of(context)!.firebaseStorageSubtitle,
            used: firebaseUsed,
            limit: firebaseLimit,
            percent: firebasePct,
            color: SchoolColors.purple,
            icon: Icons.storage_rounded,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _cleaningStorage ? null : _cleanStorage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: SchoolColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _cleaningStorage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cleaning_services_rounded, size: 18),
              label: Text(
                _cleaningStorage ? AppLocalizations.of(context)!.cleaningUpStorage : AppLocalizations.of(context)!.cleanUpRedundantData,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRow({
    required String title,
    required String subtitle,
    required dynamic used,
    required dynamic limit,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: SchoolColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${_formatBytes(used)} / ${_formatBytes(limit)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: SchoolColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatFuture extends StatelessWidget {
  const _StatFuture({
    required this.future,
    required this.title,
    required this.icon,
    required this.color,
  });

  final Future<QuerySnapshot> future;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: future,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _StatCard(
          title: title,
          value: count.toString(),
          icon: icon,
          color: color,
          loading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
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
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.logoLoaded)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.uploadError(e.toString()))));
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
                                  _logoUrl!.toDirectImageUrl,
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
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.applicationName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)!.enterAName,
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
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.settingsSaved),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString()))),
                              );
                            }
                          } finally {
                            if (context.mounted)
                              setState(() => _loading = false);
                          }
                        },
                  icon: _loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.save_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.saveChanges1),
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


