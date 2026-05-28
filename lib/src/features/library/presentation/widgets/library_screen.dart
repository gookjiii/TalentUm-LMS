import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/widgets/document_preview_dialog.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../library_providers.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:school_world/src/widgets/image_viewer.dart';


class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(libraryMaterialsProvider(classId));
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
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Библиотека',
                    action: isTeacher ? 'Добавить' : null,
                    onActionTap: isTeacher
                        ? () => _showUploadDialog(context, ref)
                        : null,
                  ),
                ),
              ),
              materialsAsync.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.library_books_outlined,
                        title: 'Библиотека пуста',
                        subtitle:
                            'Здесь будут отображаться учебные материалы и лекции.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final data = docs[index].data();
                        final id = docs[index].id;
                        return _MaterialTile(
                          id: id,
                          title: data['title'] ?? 'Без названия',
                          description: data['description'],
                          fileUrl: data['fileUrl'] ?? '',
                          fileName: data['fileName'],
                          canDelete: isLeadOfClass,
                          onDelete: () => _deleteMaterial(context, ref, id),
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

  void _showUploadDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _UploadMaterialDialog(classId: classId),
    );
  }

  Future<void> _deleteMaterial(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить материал?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: SchoolColors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(repositoryProvider).deleteLibraryMaterial(id);
    }
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    this.fileName,
    required this.canDelete,
    required this.onDelete,
  });

  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final String? fileName;
  final bool canDelete;
  final VoidCallback onDelete;

  void _handleTap(BuildContext context) {
    final ext = (fileName ?? title).split('.').last.toLowerCase();
    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext);
    final isDoc = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'csv'].contains(ext);

    if (isImage) {
      showDialog(
        context: context,
        builder: (_) => ImageViewer(imageUrl: fileUrl),
      );
    } else if (isDoc) {
      showDialog(
        context: context,
        builder: (_) => DocumentPreviewDialog(
          url: fileUrl,
          fileName: fileName ?? title,
        ),
      );
    } else {
      launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = (fileName ?? title).split('.').last.toLowerCase();
    
    IconData iconData = Icons.insert_drive_file_rounded;
    Color accentColor = SchoolColors.muted;
    
    if (ext == 'pdf') {
      iconData = Icons.picture_as_pdf_rounded;
      accentColor = SchoolColors.red;
    } else if (['doc', 'docx'].contains(ext)) {
      iconData = Icons.description_rounded;
      accentColor = const Color(0xFF2563EB); // Word Blue
    } else if (['ppt', 'pptx'].contains(ext)) {
      iconData = Icons.slideshow_rounded;
      accentColor = const Color(0xFFEA580C); // PPT Orange
    } else if (['xls', 'xlsx'].contains(ext)) {
      iconData = Icons.table_view_rounded;
      accentColor = const Color(0xFF16A34A); // Excel Green
    } else if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext)) {
      iconData = Icons.image_rounded;
      accentColor = const Color(0xFF0D9488); // Teal
    } else if (['mp3', 'wav', 'm4a'].contains(ext)) {
      iconData = Icons.audiotrack_rounded;
      accentColor = const Color(0xFF8B5CF6); // Purple
    } else if (['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext)) {
      iconData = Icons.video_library_rounded;
      accentColor = const Color(0xFFEF4444); // Red
    } else if (['zip', 'rar', '7z'].contains(ext)) {
      iconData = Icons.folder_zip_rounded;
      accentColor = const Color(0xFFF59E0B); // Amber
    }
    
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
            onTap: () => _handleTap(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      iconData,
                      color: accentColor,
                      size: 28,
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
                        if (fileName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.file_present_rounded,
                                  size: 12,
                                  color: SchoolColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    fileName!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).hintColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: SchoolColors.muted,
                        ),
                        onPressed: () => _handleTap(context),
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

class _UploadMaterialDialog extends ConsumerStatefulWidget {
  const _UploadMaterialDialog({required this.classId});
  final String classId;

  @override
  ConsumerState<_UploadMaterialDialog> createState() =>
      _UploadMaterialDialogState();
}

class _UploadMaterialDialogState extends ConsumerState<_UploadMaterialDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить материал'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Заголовок',
              hintText: 'например: Лекция 1. Введение',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Описание (необязательно)',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          if (_selectedFile != null)
            Builder(
              builder: (context) {
                final ext = _selectedFile!.name.split('.').last.toLowerCase();
                IconData iconData = Icons.insert_drive_file_rounded;
                Color accentColor = SchoolColors.muted;
                if (ext == 'pdf') {
                  iconData = Icons.picture_as_pdf_rounded;
                  accentColor = SchoolColors.red;
                } else if (['doc', 'docx'].contains(ext)) {
                  iconData = Icons.description_rounded;
                  accentColor = const Color(0xFF2563EB); // Word Blue
                } else if (['ppt', 'pptx'].contains(ext)) {
                  iconData = Icons.slideshow_rounded;
                  accentColor = const Color(0xFFEA580C); // PPT Orange
                } else if (['xls', 'xlsx'].contains(ext)) {
                  iconData = Icons.table_view_rounded;
                  accentColor = const Color(0xFF16A34A); // Excel Green
                } else if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext)) {
                  iconData = Icons.image_rounded;
                  accentColor = const Color(0xFF0D9488); // Teal
                } else if (['mp3', 'wav', 'm4a'].contains(ext)) {
                  iconData = Icons.audiotrack_rounded;
                  accentColor = const Color(0xFF8B5CF6); // Purple
                } else if (['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext)) {
                  iconData = Icons.video_library_rounded;
                  accentColor = const Color(0xFFEF4444); // Red
                } else if (['zip', 'rar', '7z'].contains(ext)) {
                  iconData = Icons.folder_zip_rounded;
                  accentColor = const Color(0xFFF59E0B); // Amber
                }
                return ListTile(
                  leading: Icon(
                    iconData,
                    color: accentColor,
                  ),
                  title: Text(_selectedFile!.name),
                  subtitle: Text(
                    '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
                );
              },
            )
          else
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Выбрать файл'),
            ),
          if (_isUploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 8),
            Text('Загрузка: ${(_uploadProgress * 100).toInt()}%'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed:
              (_selectedFile == null ||
                  _titleController.text.isEmpty ||
                  _isUploading)
              ? null
              : _upload,
          child: const Text('Загрузить'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'txt',
        'png',
        'jpg',
        'jpeg',
        'gif',
        'webp',
        'bmp',
        'mp3',
        'wav',
        'm4a',
        'mp4',
        'mov',
        'avi',
        'webm',
        'mkv',
        'zip',
        'rar',
        '7z',
      ],
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _upload() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final storage = ref.read(storageProvider);
      final repo = ref.read(repositoryProvider);

      final path =
          'classes/${widget.classId}/library/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';

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

      final url = result['url'] as String;

      await repo.addLibraryMaterial(
        classId: widget.classId,
        title: _titleController.text,
        description: _descController.text,
        fileUrl: url,
        fileName: _selectedFile!.name,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при загрузке: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
