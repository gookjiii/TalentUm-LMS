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

class WebinarsScreen extends ConsumerWidget {
  const WebinarsScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webinarsAsync = ref.watch(webinarsProvider(classId));
    final appState = ref.watch(schoolAppStateProvider);
    final repo = ref.watch(repositoryProvider);
    final isTeacher = appState.isTeacher;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.firestore.collection('classes').doc(classId).snapshots(),
      builder: (context, classSnap) {
        final isLeadOfClass = appState.isLeadTeacher;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: AppLocalizations.of(context)!.webinars,
                    action: isTeacher ? AppLocalizations.of(context)!.add : null,
                    onActionTap: isTeacher
                        ? () => _showAddDialog(context, ref)
                        : null,
                  ),
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
                    padding: EdgeInsets.symmetric(horizontal: 24),
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
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
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
                        onPressed: () => launchUrl(Uri.parse(videoUrl)),
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
    final result = await FilePicker.platform.pickFiles(
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

        final storage = ref.read(storageProvider);
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
