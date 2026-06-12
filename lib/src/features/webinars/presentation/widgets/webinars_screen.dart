import 'package:school_world/src/utils/responsive_utils.dart';
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
import 'dart:ui' as ui;
class WebinarsScreen extends ConsumerStatefulWidget {
  const WebinarsScreen({super.key, required this.classId});
  final String classId;

  @override
  ConsumerState<WebinarsScreen> createState() => _WebinarsScreenState();
}

class _WebinarsScreenState extends ConsumerState<WebinarsScreen> {
  int _limit = 20;

  @override
  void didUpdateWidget(covariant WebinarsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      setState(() {
        _limit = 20;
      });
    }
  }

  void _loadMore() {
    setState(() {
      _limit += 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveClassId =
        (ref.watch(schoolAppStateProvider.select((s) => s.selectedClassId))?.isNotEmpty == true
            ? ref.watch(schoolAppStateProvider.select((s) => s.selectedClassId))
            : null) ??
        (widget.classId.isNotEmpty ? widget.classId : null);
    final appState = ref.watch(schoolAppStateProvider);
    final repo = ref.watch(repositoryProvider);
    final isTeacher = appState.isTeacher;

    // Guard: no valid class selected yet — show locked empty state
    if (effectiveClassId == null) {
      return EmptyState(
        icon: Icons.ondemand_video_outlined,
        title: AppLocalizations.of(context)!.webinars,
        subtitle: AppLocalizations.of(context)!.lessonRecordingsAndVideosWill,
      );
    }

    final webinarsAsync = ref.watch(webinarsProvider((effectiveClassId, _limit)));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.firestore.collection('classes').doc(effectiveClassId).snapshots(),
      builder: (context, classSnap) {
        final isLeadOfClass = appState.isLeadTeacher;
        final className = classSnap.data?.data()?['name']?.toString();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                _loadMore();
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final allClassAsync = ref.watch(isTeacher ? teacherClassesStreamProvider : studentClassesStreamProvider);
                      final allVisibleClasses = allClassAsync.value ?? [];
                      
                      return PageHeader(
                        title: AppLocalizations.of(context)!.webinars,
                        subtitle: AppLocalizations.of(context)!.lessonRecordingsAndVideosWill,
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
                            ? IconButton.filledTonal(
                                onPressed: () => _showAddDialog(context, ref, effectiveClassId),
                                icon: const Icon(Icons.add_rounded),
                                tooltip: AppLocalizations.of(context)!.add,
                              )
                            : null,
                      );
                    },
                  ),
                ),
                webinarsAsync.when(
                  data: (docs) {
                    if (docs.isEmpty) {
                      return SliverFillRemaining(
                        child: EmptyState(
                          icon: Icons.ondemand_video_outlined,
                          title: AppLocalizations.of(context)!.noWebinars,
                          subtitle:
                              AppLocalizations.of(context)!.lessonRecordingsAndVideosWill,
                        ),
                      );
                    }
  
                    return SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final data = docs[index].data();
                          final id = docs[index].id;
                          return _WebinarTile(
                            id: id,
                            title: data['title'] ?? AppLocalizations.of(context)!.unknownKey7,
                            description: data['description'],
                            videoUrl: data['videoUrl'] ?? '',
                            canDelete: isLeadOfClass,
                            onDelete: () => _deleteWebinar(context, ref, id),
                          );
                        }, childCount: docs.length),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                      child: Center(child: Text('Ошибка: $err'))),
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
    required this.canDelete,
    required this.onDelete,
  });

  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final bool canDelete;
  final VoidCallback onDelete;

  String? _getEmbedUrl(String url) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    // 1. YouTube
    if (cleanUrl.contains('youtube.com') || cleanUrl.contains('youtu.be')) {
      final regExp = RegExp(
        r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 2) {
        final videoId = match.group(2);
        if (videoId != null && videoId.length == 11) {
          return 'https://www.youtube.com/embed/$videoId';
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
      final regExp = RegExp(
        r'video(-?[0-9]+)_([0-9]+)',
        caseSensitive: false,
      );
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
    if (cleanUrl.contains('drive.google.com')) {
      final regExp = RegExp(
        r'drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(cleanUrl);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        if (fileId != null) {
          return 'https://drive.google.com/file/d/$fileId/preview';
        }
      }
    }

    return null;
  }

  void _playVideo(BuildContext context) {
    final embedUrl = _getEmbedUrl(videoUrl);
    if (embedUrl != null && kIsWeb) {
      showDialog(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: isDark ? SchoolColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    IframePlayer(embedUrl: embedUrl),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      launchUrl(Uri.parse(videoUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _playVideo(context),
      child: Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? AppColors.darkSurface : Colors.white,
          image: DecorationImage(
            image: const NetworkImage('https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=1000'), // Placeholder thumbnail
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          children: [
            // Delete Button
            if (canDelete)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  ),
                ),
              ),
            // Play Button (Glass)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            // Content Gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Video', // or duration
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
                                  )
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
                                  )
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
                  hintText: AppLocalizations.of(context)!.httpsyoutubecomOrLinkToFile,
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
                  valueColor: AlwaysStoppedAnimation<Color>(SchoolColors.primary),
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
          onPressed: (_isLoading ||
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
    final result = await FilePicker.pickFiles(withData: true, 
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
      
      if (_uploadMode) {
        if (_selectedFile == null) {
          throw Exception(AppLocalizations.of(context)!.pleaseSelectAVideoFile);
        }
        
        setState(() {
          _isUploading = true;
        });

        final storage = ref.read(libraryStorageProvider);
        final path = 'classes/${widget.classId}/webinars/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';

        Map<String, dynamic> result;
        if (kIsWeb) {
          result = await storage.uploadFileWeb(
            path,
            _selectedFile!.bytes!,
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
        } else {
          result = await storage.uploadFile(
            path,
            File(_selectedFile!.path!),
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
        }
        finalVideoUrl = result['url'] as String;
      }
      
      await repo.addWebinar(
        classId: widget.classId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        videoUrl: finalVideoUrl,
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
