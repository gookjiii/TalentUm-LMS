import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'iframe_player.dart';
import '../webinars_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class WebinarsScreen extends ConsumerStatefulWidget {
  const WebinarsScreen({super.key, required this.classId});
  final String classId;

  @override
  ConsumerState<WebinarsScreen> createState() => _WebinarsScreenState();
}

class _WebinarsScreenState extends ConsumerState<WebinarsScreen> {
  int _limit = 20;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedWebinars = [];

  @override
  void didUpdateWidget(covariant WebinarsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      setState(() {
        _limit = 20;
        _cachedWebinars.clear();
      });
    }
  }

  void _loadMore(int currentCount) {
    if (currentCount < _limit) return;
    setState(() {
      _limit += 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(schoolAppStateProvider);
    final repo = ref.watch(repositoryProvider);
    final isTeacher = appState.isTeacher;
    final visibleClassesAsync = ref.watch(
      isTeacher ? teacherClassesStreamProvider : studentClassesStreamProvider,
    );
    final visibleClasses = visibleClassesAsync.value ?? const [];
    final visibleIds = visibleClasses.map((c) => c['id']?.toString()).toSet();
    final storedClassId = appState.selectedClassId;
    final effectiveClassId =
        storedClassId != null && visibleIds.contains(storedClassId)
        ? storedClassId
        : (widget.classId.isNotEmpty && visibleIds.contains(widget.classId)
              ? widget.classId
              : (visibleClasses.isEmpty
                    ? null
                    : visibleClasses.first['id']?.toString()));

    // Guard: no valid class selected yet — show locked empty state
    if (effectiveClassId == null) {
      return EmptyState(
        icon: Icons.ondemand_video_outlined,
        title: AppLocalizations.of(context)!.webinars,
        subtitle: AppLocalizations.of(context)!.lessonRecordingsAndVideosWill,
      );
    }

    final webinarsAsync = ref.watch(
      webinarsProvider((effectiveClassId, _limit)),
    );

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.firestore
          .collection('classes')
          .doc(effectiveClassId)
          .snapshots(),
      builder: (context, classSnap) {
        final isLeadOfClass = appState.isLeadTeacher;
        final className = classSnap.data?.data()?['name']?.toString();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
                _loadMore(_cachedWebinars.length);
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final allClassAsync = ref.watch(
                        isTeacher
                            ? teacherClassesStreamProvider
                            : studentClassesStreamProvider,
                      );
                      final allVisibleClasses = allClassAsync.value ?? [];

                      return PageHeader(
                        title: AppLocalizations.of(context)!.webinars,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.lessonRecordingsAndVideosWill,
                        classContext: className,
                        onClassContextTap: allVisibleClasses.length > 1
                            ? () {
                                showClassSwitcher(
                                  context: context,
                                  classes: allVisibleClasses,
                                  currentClassId: effectiveClassId,
                                  onSelect: (id) {
                                    ref
                                        .read(schoolAppStateProvider)
                                        .selectClass(id);
                                  },
                                );
                              }
                            : null,
                        trailing: isTeacher
                            ? SchoolAddButton(
                                onPressed: () => _showAddDialog(
                                  context,
                                  ref,
                                  effectiveClassId,
                                ),
                                tooltip: AppLocalizations.of(context)!.add,
                              )
                            : null,
                      );
                    },
                  ),
                ),
                Builder(
                  builder: (context) {
                    if (webinarsAsync.hasValue) {
                      _cachedWebinars = webinarsAsync.value!;
                    }
                    final docs = webinarsAsync.hasValue
                        ? webinarsAsync.value!
                        : _cachedWebinars;
                    final isInitialLoading =
                        webinarsAsync.isLoading && _cachedWebinars.isEmpty;

                    if (isInitialLoading) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (webinarsAsync.hasError && docs.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text('Ошибка: ${webinarsAsync.error}'),
                        ),
                      );
                    }

                    if (docs.isEmpty) {
                      return SliverFillRemaining(
                        child: EmptyState(
                          icon: Icons.ondemand_video_outlined,
                          title: AppLocalizations.of(context)!.noWebinars,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.lessonRecordingsAndVideosWill,
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final data = docs[index].data();
                          final id = docs[index].id;
                          return _WebinarTile(
                            id: id,
                            title:
                                data['title'] ??
                                AppLocalizations.of(context)!.unknownKey7,
                            description: data['description'],
                            videoUrl: data['videoUrl'] ?? '',
                            driveFileId: data['driveFileId'] as String?,
                            storageProvider: data['storageProvider'] as String?,
                            canDelete: isLeadOfClass,
                            onDelete: () => _deleteWebinar(context, ref, id),
                          );
                        }, childCount: docs.length),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, String classId) {
    showDialog(
      context: context,
      builder: (context) => _AddWebinarDialog(classId: classId),
    );
  }

  Future<void> _deleteWebinar(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteWebinar),
        content: Text(AppLocalizations.of(context)!.thisActionCannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.unknownKey),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: SchoolColors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(repositoryProvider).deleteWebinar(id);
    }
  }
}

class _WebinarTile extends StatelessWidget {
  const _WebinarTile({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.driveFileId,
    this.storageProvider,
    required this.canDelete,
    required this.onDelete,
  });

  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? driveFileId;
  final String? storageProvider;
  final bool canDelete;
  final VoidCallback onDelete;

  static const Set<String> _directVideoExtensions = <String>{
    '.mp4',
    '.mov',
    '.webm',
    '.mkv',
    '.m3u8',
  };

  Uri? _parseVideoUri() {
    final uri = Uri.tryParse(videoUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  bool _isDirectVideoUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('/video/upload/')) return true;
    return _directVideoExtensions.any((ext) => lower.contains(ext));
  }

  String? _extractDriveFileId(String value) {
    if (driveFileId != null && driveFileId!.trim().isNotEmpty) {
      return driveFileId!.trim();
    }
    final clean = value.trim();
    if (clean.isEmpty) return null;

    final uri = Uri.tryParse(clean);
    final queryId = uri?.queryParameters['id'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final patterns = [
      RegExp(
        r'drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'drive\.google\.com\/open\?id=([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'drive\.google\.com\/uc\?.*id=([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'drive\.usercontent\.google\.com\/download\?.*id=([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'docs\.google\.com\/(?:document|spreadsheets|presentation|file)\/d\/([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(clean);
      if (match != null && match.groupCount >= 1) {
        final id = match.group(1);
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return null;
  }

  String? _getEmbedUrl(String url) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    // 1. YouTube & YouTube Shorts
    if (cleanUrl.contains('youtube.com') || cleanUrl.contains('youtu.be')) {
      final shortsRegExp = RegExp(
        r'youtube\.com\/shorts\/([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      );
      final shortsMatch = shortsRegExp.firstMatch(cleanUrl);
      if (shortsMatch != null && shortsMatch.groupCount >= 1) {
        final videoId = shortsMatch.group(1);
        if (videoId != null && videoId.isNotEmpty) {
          return 'https://www.youtube.com/embed/$videoId?autoplay=0&playsinline=1&rel=0';
        }
      }

      final regExp = RegExp(
        r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 2) {
        final videoId = match.group(2);
        if (videoId != null && videoId.length == 11) {
          return 'https://www.youtube.com/embed/$videoId?autoplay=0&playsinline=1&rel=0';
        }
      }
    }

    // 2. RuTube
    if (cleanUrl.contains('rutube.ru')) {
      if (cleanUrl.contains('rutube.ru/play/embed/')) {
        return cleanUrl;
      }

      // 2a. Private/custom RuTube videos (Check FIRST to avoid matching 'private' as videoId in general match)
      final privateRegExp = RegExp(
        r'rutube\.ru/video/private/([a-zA-Z0-9]+)',
        caseSensitive: false,
      );
      final privateMatch = privateRegExp.firstMatch(cleanUrl);
      if (privateMatch != null && privateMatch.groupCount >= 1) {
        final videoId = privateMatch.group(1);
        if (videoId != null) {
          final uri = Uri.parse(cleanUrl);
          final p = uri.queryParameters['p'];
          if (p != null) {
            return 'https://rutube.ru/play/embed/$videoId?p=$p';
          }
          return 'https://rutube.ru/play/embed/$videoId';
        }
      }

      // 2b. General RuTube videos
      final regExp = RegExp(
        r'rutube\.ru/video/([a-zA-Z0-9]+)',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        final videoId = match.group(1);
        if (videoId != null && videoId.toLowerCase() != 'private') {
          return 'https://rutube.ru/play/embed/$videoId';
        }
      }
    }

    // 3. VK Video / VK Clips
    if (cleanUrl.contains('vk.com') || cleanUrl.contains('vk.ru')) {
      if (cleanUrl.contains('video_ext.php')) {
        return cleanUrl;
      }

      // 3a. VK Clips
      final clipRegExp = RegExp(
        r'clip(-?[0-9]+)_([0-9]+)',
        caseSensitive: false,
      );
      final clipMatch = clipRegExp.firstMatch(cleanUrl);
      if (clipMatch != null && clipMatch.groupCount >= 2) {
        final oid = clipMatch.group(1);
        final id = clipMatch.group(2);
        if (oid != null && id != null) {
          return 'https://vk.com/video_ext.php?oid=$oid&id=$id';
        }
      }

      // 3b. VK Video
      final regExp = RegExp(r'video(-?[0-9]+)_([0-9]+)', caseSensitive: false);
      final match = regExp.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 2) {
        final oid = match.group(1);
        final id = match.group(2);
        if (oid != null && id != null) {
          final uri = Uri.parse(cleanUrl);
          final hash = uri.queryParameters['hash'];
          if (hash != null) {
            return 'https://vk.com/video_ext.php?oid=$oid&id=$id&hash=$hash';
          }
          return 'https://vk.com/video_ext.php?oid=$oid&id=$id';
        }
      }
    }

    // 4. Google Drive
    final gDriveId = _extractDriveFileId(cleanUrl);
    if (gDriveId != null && gDriveId.isNotEmpty) {
      return 'https://drive.google.com/file/d/$gDriveId/preview';
    }

    return null;
  }

  Future<void> _openExternal(BuildContext context) async {
    final gDriveId = _extractDriveFileId(videoUrl);
    final targetUrl = (gDriveId != null && gDriveId.isNotEmpty)
        ? 'https://drive.google.com/file/d/$gDriveId/view'
        : videoUrl.trim();

    final uri = Uri.tryParse(targetUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToLoadVideo),
          ),
        );
      }
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToLoadVideo),
        ),
      );
    }
  }

  Future<void> _playVideo(BuildContext context) async {
    final gDriveId = _extractDriveFileId(videoUrl);
    final embedUrl = _getEmbedUrl(videoUrl);
    final directVideo = _isDirectVideoUrl(videoUrl);
    final uri = _parseVideoUri();

    const proxyBaseUrl = String.fromEnvironment(
      'GOOGLE_DRIVE_PROXY_URL',
      defaultValue: 'https://vercel-talentum-backend.vercel.app',
    );

    // If it's a Google Drive video, stream via proxy_video as HTML5 <video> for native mobile playback
    final isGDrive = gDriveId != null && gDriveId.isNotEmpty;
    final streamVideoUrl = isGDrive
        ? '$proxyBaseUrl/api/library/proxy_video?fileId=$gDriveId'
        : null;

    final effectiveSourceUrl = streamVideoUrl ?? embedUrl ?? uri?.toString();
    final effectiveUseVideoElement =
        streamVideoUrl != null || (embedUrl == null && directVideo);

    if (effectiveSourceUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToLoadVideo),
          ),
        );
      }
      return;
    }

    if (kIsWeb && (embedUrl != null || directVideo || isGDrive)) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => _WebinarVideoDialog(
          title: title,
          sourceUrl: effectiveSourceUrl,
          useVideoElement: effectiveUseVideoElement,
          onOpenExternal: () => _openExternal(context),
        ),
      );
      return;
    }

    await _openExternal(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? SchoolColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _playVideo(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: SchoolColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: SchoolColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (description != null && description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: SchoolColors.muted,
                                height: 1.3,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 12,
                              color: SchoolColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.watchVideo,
                              style: TextStyle(
                                fontSize: 11,
                                color: SchoolColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: SchoolColors.muted,
                        ),
                        onPressed: () => _openExternal(context),
                      ),
                      if (canDelete)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: SchoolColors.red,
                            size: 20,
                          ),
                          onPressed: onDelete,
                        ),
                    ],
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

class _WebinarVideoDialog extends StatefulWidget {
  const _WebinarVideoDialog({
    required this.title,
    required this.sourceUrl,
    required this.useVideoElement,
    required this.onOpenExternal,
  });

  final String title;
  final String sourceUrl;
  final bool useVideoElement;
  final Future<void> Function() onOpenExternal;

  @override
  State<_WebinarVideoDialog> createState() => _WebinarVideoDialogState();
}

class _WebinarVideoDialogState extends State<_WebinarVideoDialog> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;
    final iframeStack = Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        IframePlayer(
          sourceUrl: widget.sourceUrl,
          useVideoElement: widget.useVideoElement,
          onReady: () {
            // No-op
          },
          onError: () {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          },
        ),

        if (_hasError)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.failedToLoadVideo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: widget.onOpenExternal,
                    child: Text(AppLocalizations.of(context)!.watchVideo),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    final player = AspectRatio(aspectRatio: 16 / 9, child: iframeStack);

    if (isMobile) {
      return Material(
        color: Colors.black.withValues(alpha: 0.94),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.watchVideo,
                      onPressed: widget.onOpenExternal,
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: player,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 24 : 40,
      ),
      clipBehavior: Clip.antiAlias,
      backgroundColor: theme.brightness == Brightness.dark
          ? SchoolColors.darkSurface
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: theme.brightness == Brightness.dark
                ? SchoolColors.darkSurface
                : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.watchVideo,
                  onPressed: widget.onOpenExternal,
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(child: player),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AddWebinarDialog extends ConsumerStatefulWidget {
  const _AddWebinarDialog({required this.classId});
  final String classId;

  @override
  ConsumerState<_AddWebinarDialog> createState() => _AddWebinarDialogState();
}

class _AddWebinarDialogState extends ConsumerState<_AddWebinarDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();

  bool _uploadMode = false;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.addAWebinar),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.title,
                hintText: AppLocalizations.of(context)!.forExampleLesson1Basics,
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.descriptionOptional,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Mode Selector Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? SchoolColors.darkBg
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _uploadMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_uploadMode
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? SchoolColors.darkSurface
                                    : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_uploadMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context)!.provideLink,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: !_uploadMode
                                ? SchoolColors.primary
                                : SchoolColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _uploadMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _uploadMode
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? SchoolColors.darkSurface
                                    : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _uploadMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context)!.uploadFile,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _uploadMode
                                ? SchoolColors.primary
                                : SchoolColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Mode Fields
            if (!_uploadMode) ...[
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.videoLink,
                  hintText: AppLocalizations.of(
                    context,
                  )!.httpsyoutubecomOrLinkToFile,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ] else ...[
              if (_selectedFile != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.video_library_rounded,
                    color: SchoolColors.primary,
                  ),
                  title: Text(
                    _selectedFile!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: Icon(Icons.attach_file_rounded),
                  label: Text(AppLocalizations.of(context)!.selectVideoFile),
                ),
              if (_isUploading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: SchoolColors.muted.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SchoolColors.primary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.loadingVideo,
                      style: TextStyle(
                        fontSize: 12,
                        color: SchoolColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SchoolColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.unknownKey),
        ),
        ElevatedButton(
          onPressed:
              (_isLoading ||
                  _titleController.text.trim().isEmpty ||
                  (!_uploadMode && _urlController.text.trim().isEmpty) ||
                  (_uploadMode && _selectedFile == null))
              ? null
              : _save,
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'webm', 'mkv'],
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _isUploading = false;
      _uploadProgress = 0;
    });

    try {
      final repo = ref.read(repositoryProvider);
      String finalVideoUrl = _urlController.text.trim();
      Map<String, dynamic>? uploadResult;

      if (_uploadMode) {
        if (_selectedFile == null) {
          throw Exception(AppLocalizations.of(context)!.pleaseSelectAVideoFile);
        }

        setState(() {
          _isUploading = true;
        });

        final storage = ref.read(libraryStorageProvider);
        final path =
            'classes/${widget.classId}/webinars/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';

        if (kIsWeb) {
          uploadResult = await storage.uploadFileWeb(
            path,
            _selectedFile!.bytes!,
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
        } else {
          uploadResult = await storage.uploadFile(
            path,
            File(_selectedFile!.path!),
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
        }
        finalVideoUrl = uploadResult['url'] as String;
      }

      await repo.addWebinar(
        classId: widget.classId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        videoUrl: finalVideoUrl,
        storageProvider: uploadResult?['provider'] as String?,
        storagePath: uploadResult?['path'] as String?,
        driveFileId: uploadResult?['driveFileId'] as String?,
        fileSize:
            (uploadResult?['bytes'] as num?)?.toInt() ??
            (uploadResult?['size'] as num?)?.toInt() ??
            (_selectedFile?.size),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Webinar save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }
}
