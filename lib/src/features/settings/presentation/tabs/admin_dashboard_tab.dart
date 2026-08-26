import 'package:school_world/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static const String _defaultProxyUrl =
      'https://vercel-talentum-backend.vercel.app';
  static const double _defaultGoogleLimit = 15.0 * 1024 * 1024 * 1024; // 15 GB
  static const double _defaultCloudinaryLimit =
      25.0 * 1024 * 1024 * 1024; // 25 GB
  static const double _defaultFirebaseLimit = 5.0 * 1024 * 1024 * 1024; // 5 GB

  bool _loadingStorage = false;
  bool _cleaningStorage = false;
  Map<String, dynamic>? _storageStats;

  @override
  void initState() {
    super.initState();
    _fetchStorageStats();
  }

  String _resolveProxyUrl() {
    const configured = String.fromEnvironment('GOOGLE_DRIVE_PROXY_URL');
    if (configured.isNotEmpty) return configured;
    return _defaultProxyUrl;
  }

  Future<void> _fetchStorageStats() async {
    setState(() => _loadingStorage = true);
    Map<String, dynamic>? resultStats;

    try {
      final proxyUrl = _resolveProxyUrl();
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

      if (idToken != null && idToken.isNotEmpty) {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        final res = await dio.get(
          '$proxyUrl/api/admin/storage_stats',
          options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        );

        if (res.data != null) {
          Map<String, dynamic> parsedData;
          if (res.data is Map) {
            parsedData = Map<String, dynamic>.from(res.data as Map);
          } else if (res.data is String) {
            parsedData = jsonDecode(res.data as String) as Map<String, dynamic>;
          } else {
            parsedData = {};
          }

          resultStats = parsedData;
        }
      }
    } catch (e) {
      debugPrint('Backend storage_stats failed, using Firestore fallback: $e');
    }

    // If backend was unreachable or returned empty/zero stats, perform client-side Firestore scan
    try {
      final firestoreFallback = await _fetchFirestoreStorageStatsFallback();
      if (resultStats == null) {
        resultStats = firestoreFallback;
      } else {
        final driveMap =
            resultStats['googleDrive'] is Map
                ? resultStats['googleDrive'] as Map
                : null;
        final cloudMap =
            resultStats['cloudinary'] is Map
                ? resultStats['cloudinary'] as Map
                : null;
        final fbMap =
            resultStats['firebase'] is Map
                ? resultStats['firebase'] as Map
                : null;

        final rawDriveLimit = _toByteCount(driveMap?['limit']);
        final rawCloudLimit = _toByteCount(cloudMap?['limit']);
        final rawFbLimit = _toByteCount(fbMap?['limit']);

        final backendDrive = _toByteCount(driveMap?['used']);
        final backendCloud = _toByteCount(cloudMap?['used']);
        final backendFb = _toByteCount(fbMap?['used']);

        final fsDrive = _toByteCount(firestoreFallback['googleDrive']?['used']);
        final fsCloud = _toByteCount(firestoreFallback['cloudinary']?['used']);
        final fsFb = _toByteCount(firestoreFallback['firebase']?['used']);

        resultStats = {
          'googleDrive': {
            'limit': rawDriveLimit > 0 ? rawDriveLimit : _defaultGoogleLimit,
            'used': math.max(backendDrive, fsDrive),
          },
          'cloudinary': {
            'limit': rawCloudLimit > 0 ? rawCloudLimit : _defaultCloudinaryLimit,
            'used': math.max(backendCloud, fsCloud),
          },
          'firebase': {
            'limit': rawFbLimit > 0 ? rawFbLimit : _defaultFirebaseLimit,
            'used': math.max(backendFb, fsFb),
          },
        };
      }
    } catch (fsErr) {
      debugPrint('Firestore storage fallback error: $fsErr');
    }

    if (mounted) {
      setState(() {
        _storageStats =
            resultStats ??
            {
              'googleDrive': {'limit': _defaultGoogleLimit, 'used': 0.0},
              'cloudinary': {'limit': _defaultCloudinaryLimit, 'used': 0.0},
              'firebase': {'limit': _defaultFirebaseLimit, 'used': 0.0},
            };
        _loadingStorage = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchFirestoreStorageStatsFallback() async {
    final firestore = FirebaseFirestore.instance;
    double driveBytes = 0;
    double cloudinaryBytes = 0;
    double firebaseBytes = 0;

    void categorize(String url, double sz) {
      if (sz <= 0) return;
      final lower = url.toLowerCase();
      if (lower.contains('cloudinary.com') ||
          lower.contains('res.cloudinary.com')) {
        cloudinaryBytes += sz;
      } else if (lower.contains('firebasestorage.googleapis.com') ||
          lower.contains('storage.googleapis.com')) {
        firebaseBytes += sz;
      } else if (lower.contains('drive.google.com') ||
          lower.contains('docs.google.com') ||
          lower.contains('/api/library/')) {
        driveBytes += sz;
      } else {
        // Default unrecognized large files to drive
        driveBytes += sz;
      }
    }

    // 1. drive_uploads collection
    try {
      final snap = await firestore.collection('drive_uploads').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final sz = _toByteCount(d['size'] ?? d['fileSize']);
        final url =
            (d['webContentLink'] ?? d['url'] ?? d['webViewLink'] ?? '')
                .toString();
        categorize(url, sz);
      }
    } catch (_) {}

    // 2. library_materials and legacy library collections
    for (final col in ['library_materials', 'library']) {
      try {
        final snap = await firestore.collection(col).get();
        for (final doc in snap.docs) {
          final d = doc.data();
          final sz = _toByteCount(d['fileSize'] ?? d['size']);
          final url = (d['fileUrl'] ?? d['url'] ?? '').toString();
          categorize(url, sz);
        }
      } catch (_) {}
    }

    // 3. posts
    try {
      final snap = await firestore.collection('posts').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final atts = d['attachments'];
        if (atts is Iterable) {
          for (final att in atts) {
            if (att is Map) {
              final sz = _toByteCount(att['size'] ?? att['fileSize']);
              final url = (att['url'] ?? att['uri'] ?? '').toString();
              categorize(url, sz);
            }
          }
        }
        final singleUrl = (d['url'] ?? '').toString();
        if (singleUrl.isNotEmpty) {
          categorize(singleUrl, _toByteCount(d['size'] ?? d['fileSize']));
        }
      }
    } catch (_) {}

    // 4. webinars
    try {
      final snap = await firestore.collection('webinars').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final sz = _toByteCount(d['fileSize'] ?? d['size']);
        final url = (d['videoUrl'] ?? d['url'] ?? '').toString();
        categorize(url, sz);
      }
    } catch (_) {}

    // 5. assignments (teacher attachments)
    try {
      final snap = await firestore.collection('assignments').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final atts = d['attachments'];
        if (atts is Iterable) {
          for (final att in atts) {
            if (att is Map) {
              final sz = _toByteCount(att['size'] ?? att['fileSize']);
              final url = (att['url'] ?? att['uri'] ?? '').toString();
              categorize(url, sz);
            }
          }
        }
      }
    } catch (_) {}

    // 6. submissions (student homework attachments)
    try {
      final snap = await firestore.collection('submissions').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final atts = d['attachments'];
        if (atts is Iterable) {
          for (final att in atts) {
            if (att is Map) {
              final sz = _toByteCount(att['size'] ?? att['fileSize']);
              final url = (att['url'] ?? att['uri'] ?? '').toString();
              categorize(url, sz);
            }
          }
        }
      }
    } catch (_) {}

    // 7. Users avatars
    try {
      final snap = await firestore.collection('users').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final avatarUrl = (d['avatarUrl'] ?? d['photoURL'] ?? d['avatar'] ?? '').toString();
        if (avatarUrl.isNotEmpty) {
          categorize(avatarUrl, 100 * 1024); // Estimate ~100KB per avatar if size unspecified
        }
      }
    } catch (_) {}

    // 8. Messages attachments
    try {
      final snap = await firestore.collectionGroup('messages').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final meta = d['metadata'];
        final metaSize = meta is Map ? meta['fileSize'] : null;
        final sz = _toByteCount(d['size'] ?? d['fileSize'] ?? metaSize);
        final url = (d['uri'] ?? d['source'] ?? d['url'] ?? '').toString();
        categorize(url, sz);
      }
    } catch (_) {
      try {
        final roomsSnap = await firestore.collection('rooms').limit(20).get();
        for (final roomDoc in roomsSnap.docs) {
          final msgSnap =
              await firestore
                  .collection('rooms')
                  .doc(roomDoc.id)
                  .collection('messages')
                  .limit(100)
                  .get();
          for (final doc in msgSnap.docs) {
            final d = doc.data();
            final meta = d['metadata'];
            final metaSize = meta is Map ? meta['fileSize'] : null;
            final sz = _toByteCount(d['size'] ?? d['fileSize'] ?? metaSize);
            final url = (d['uri'] ?? d['source'] ?? d['url'] ?? '').toString();
            categorize(url, sz);
          }
        }
      } catch (_) {}
    }

    return {
      'googleDrive': {'limit': _defaultGoogleLimit, 'used': driveBytes},
      'cloudinary': {'limit': _defaultCloudinaryLimit, 'used': cloudinaryBytes},
      'firebase': {'limit': _defaultFirebaseLimit, 'used': firebaseBytes},
    };
  }

  Future<void> _cleanStorage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmCleanup),
            content: Text(AppLocalizations.of(context)!.confirmCleanupDesc),
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
      final proxyUrl = _resolveProxyUrl();
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        final dio = Dio();
        final res = await dio.post(
          '$proxyUrl/api/admin/storage_cleanup',
          data: {'dryRun': false},
          options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        );

        Map<String, dynamic> parsedData;
        if (res.data is Map) {
          parsedData = Map<String, dynamic>.from(res.data as Map);
        } else if (res.data is String) {
          parsedData = jsonDecode(res.data as String) as Map<String, dynamic>;
        } else {
          parsedData = {};
        }

        final summary = parsedData['summary'] ?? {};
        final totalFiles = summary['totalFilesDeleted'] ?? 0;
        final totalBytesSaved = summary['totalBytesSaved'] ?? 0;
        final formattedSize = _formatBytes(totalBytesSaved);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.cleanupSuccess(totalFiles.toString(), formattedSize),
              ),
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
            content: Text(
              AppLocalizations.of(context)!.cleanupFailed(e.toString()),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cleaningStorage = false);
    }
  }

  String _formatBytes(dynamic bytes, [int decimals = 2]) {
    final intBytes = _toByteCount(bytes);
    if (intBytes <= 0) return '0 B';
    const constSuffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (math.log(intBytes) / math.log(1024)).floor().clamp(
      0,
      constSuffixes.length - 1,
    );
    return '${(intBytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${constSuffixes[i]}';
  }

  double _toByteCount(dynamic value) {
    if (value is num && value.isFinite && value > 0) return value.toDouble();
    if (value is String) {
      final parsed = num.tryParse(value.replaceAll(',', '').trim());
      if (parsed != null && parsed.isFinite && parsed > 0) {
        return parsed.toDouble();
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // The admin tab may be mounted while the locale delegate is being
      // attached. Do not let the transient null localization crash the shell.
      return const Center(child: CircularProgressIndicator());
    }
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
              title: l10n.adminPanel,
              subtitle: l10n.systemManagementAndActivityAnalytics,
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
                          future: repo.firestore
                              .collection('users')
                              .count()
                              .get()
                              .then((res) => res.count),
                          title: AppLocalizations.of(context)!.totalUsers,
                          icon: Icons.people_rounded,
                          color: SchoolColors.primary,
                        ),
                        const SizedBox(height: 16),
                        _StatFuture(
                          future: repo.firestore
                              .collection('rooms')
                              .count()
                              .get()
                              .then((res) => res.count),
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
                              .count()
                              .get()
                              .then((res) => res.count)
                              .catchError((e) {
                                debugPrint(
                                  'Missing index for messages today: $e',
                                );
                                return null;
                              }),
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
                            future: repo.firestore
                                .collection('users')
                                .count()
                                .get()
                                .then((res) => res.count),
                            title: AppLocalizations.of(context)!.totalUsers,
                            icon: Icons.people_rounded,
                            color: SchoolColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatFuture(
                            future: repo.firestore
                                .collection('rooms')
                                .count()
                                .get()
                                .then((res) => res.count),
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
                                .count()
                                .get()
                                .then((res) => res.count)
                                .catchError((e) {
                                  debugPrint(
                                    'Missing index for messages today: $e',
                                  );
                                  return null;
                                }),
                            title: AppLocalizations.of(context)!.postsToday,
                            icon: Icons.auto_graph_rounded,
                            color: SchoolColors.purple,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),
                  SectionHeader(
                    title: AppLocalizations.of(context)!.appBranding,
                  ),
                  const SizedBox(height: 16),
                  _BrandingSettingsCard(),

                  const SizedBox(height: 32),
                  SectionHeader(
                    title: AppLocalizations.of(context)!.cloudStorageManagement,
                    action: _loadingStorage
                        ? null
                        : AppLocalizations.of(context)!.retry,
                    onActionTap: _loadingStorage ? null : _fetchStorageStats,
                  ),
                  const SizedBox(height: 16),
                  _buildStorageManagementCard(),
                  const SizedBox(height: 32),
                  SectionHeader(
                    title: AppLocalizations.of(context)!.quickActions1,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _AdminActionTile(
                        title: AppLocalizations.of(context)!.users,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.roleManagementAndBan,
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
                        subtitle: AppLocalizations.of(
                          context,
                        )!.reviewAndModeration,
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
                        title: AppLocalizations.of(
                          context,
                        )!.applicationsForTeachers,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.moderationOfRequests,
                        icon: Icons.how_to_reg_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminTeacherRequestsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  SectionHeader(
                    title: AppLocalizations.of(context)!.latestUsers,
                  ),
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
                                action: AppLocalizations.of(
                                  context,
                                )!.registered,
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

    final googleUsed = _toByteCount(_storageStats?['googleDrive']?['used']);
    final rawGoogleLimit = _toByteCount(
      _storageStats?['googleDrive']?['limit'],
    );
    final googleLimit =
        rawGoogleLimit > 0 ? rawGoogleLimit : _defaultGoogleLimit;
    final googlePct =
        googleLimit > 0 ? (googleUsed / googleLimit).clamp(0.0, 1.0) : 0.0;

    final cloudinaryUsed = _toByteCount(_storageStats?['cloudinary']?['used']);
    final rawCloudinaryLimit = _toByteCount(
      _storageStats?['cloudinary']?['limit'],
    );
    final cloudinaryLimit =
        rawCloudinaryLimit > 0 ? rawCloudinaryLimit : _defaultCloudinaryLimit;
    final cloudinaryPct =
        cloudinaryLimit > 0
            ? (cloudinaryUsed / cloudinaryLimit).clamp(0.0, 1.0)
            : 0.0;

    final firebaseUsed = _toByteCount(_storageStats?['firebase']?['used']);
    final rawFirebaseLimit = _toByteCount(_storageStats?['firebase']?['limit']);
    final firebaseLimit =
        rawFirebaseLimit > 0 ? rawFirebaseLimit : _defaultFirebaseLimit;
    final firebasePct =
        firebaseLimit > 0
            ? (firebaseUsed / firebaseLimit).clamp(0.0, 1.0)
            : 0.0;

    return SchoolCard(
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
              icon:
                  _cleaningStorage
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
                _cleaningStorage
                    ? AppLocalizations.of(context)!.cleaningUpStorage
                    : AppLocalizations.of(context)!.cleanUpRedundantData,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
    final limitBytes = _toByteCount(limit);
    final limitStr = limitBytes > 0 ? _formatBytes(limitBytes) : '—';
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
              '${_formatBytes(used)} / $limitStr',
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

  final Future<int?> future;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: future,
      builder: (context, snapshot) {
        final count = snapshot.data;
        return _StatCard(
          title: title,
          value:
              snapshot.hasError ||
                  (snapshot.connectionState == ConnectionState.done &&
                      count == null)
              ? 'Err'
              : (count?.toString() ?? '0'),
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
              width: MediaQuery.sizeOf(context).width < 600
                  ? double.infinity
                  : 280,
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
    final result = await FilePicker.pickFiles(
      withData: true,
      type: FileType.image,
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.logoLoaded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.uploadError(e.toString()),
            ),
          ),
        );
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
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SchoolLogo(size: 64);
                                  },
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
                                  content: Text(
                                    AppLocalizations.of(context)!.settingsSaved,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.errorPrefix(e.toString()),
                                  ),
                                ),
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
