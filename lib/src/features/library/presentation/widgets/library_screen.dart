import 'package:school_world/src/utils/responsive_utils.dart';
import 'package:school_world/l10n/app_localizations.dart';
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
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:school_world/src/services/ilovepdf_service.dart';


class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, required this.classId});
  final String classId;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _limit = 20;

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
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

    // Guard: no valid class selected yet
    if (effectiveClassId == null) {
      return EmptyState(
        icon: Icons.library_books_outlined,
        title: AppLocalizations.of(context)!.library,
        subtitle: AppLocalizations.of(context)!.studyMaterialsAndLecturesWill,
      );
    }

    final materialsAsync =
        ref.watch(libraryMaterialsProvider((effectiveClassId, _limit)));

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
                        title: AppLocalizations.of(context)!.library,
                        subtitle: AppLocalizations.of(context)!
                            .studyMaterialsAndLecturesWill,
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
                                onPressed: () => _showUploadDialog(context, ref, effectiveClassId),
                                icon: const Icon(Icons.add_rounded),
                                tooltip: AppLocalizations.of(context)!.add,
                              )
                            : null,
                      );
                    },
                  ),
                ),
                materialsAsync.when(
                  data: (docs) {
                    if (docs.isEmpty) {
                      return SliverFillRemaining(
                        child: EmptyState(
                          icon: Icons.library_books_outlined,
                          title: AppLocalizations.of(context)!.theLibraryIsEmpty,
                          subtitle: AppLocalizations.of(context)!
                              .studyMaterialsAndLecturesWill,
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final data = docs[index].data();
                          final id = docs[index].id;
                          return _MaterialTile(
                            id: id,
                            title: data['title'] ??
                                AppLocalizations.of(context)!.unknownKey7,
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
                    child: Center(child: Text('Ошибка: $err')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUploadDialog(BuildContext context, WidgetRef ref, String classId) {
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
        title: Text(AppLocalizations.of(context)!.deleteMaterial),
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
    final isVideo = ['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext);

    if (isImage) {
      showDialog(
        context: context,
        builder: (_) => ImageViewer(imageUrl: fileUrl),
      );
    } else if (isDoc || isVideo) {
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
    
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withOpacity(isDark ? 0.2 : 0.8),
              accentColor.withOpacity(isDark ? 0.05 : 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(iconData, color: Colors.white, size: 24),
                ),
                if (canDelete)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
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
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
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
  bool _compressPdf = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.addMaterial),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.title,
              hintText: AppLocalizations.of(context)!.forExampleLecture1Introduction,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.descriptionOptional,
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
              label: Text(AppLocalizations.of(context)!.selectFile),
            ),
          if (_selectedFile != null && _selectedFile!.name.toLowerCase().endsWith('.pdf'))
            CheckboxListTile(
              value: _compressPdf,
              onChanged: (val) => setState(() => _compressPdf = val ?? true),
              title: Text(AppLocalizations.of(context)!.compressPdfTitle),
              subtitle: Text(AppLocalizations.of(context)!.compressPdfSubtitle),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: SchoolColors.primary,
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
          child: Text(AppLocalizations.of(context)!.unknownKey),
        ),
        ElevatedButton(
          onPressed:
              (_selectedFile == null ||
                  _titleController.text.isEmpty ||
                  _isUploading)
              ? null
              : _upload,
          child: Text(AppLocalizations.of(context)!.download),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(withData: true, 
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
      final storage = ref.read(libraryStorageProvider);
      final repo = ref.read(repositoryProvider);

      final path =
          'classes/${widget.classId}/library/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';

      Map<String, dynamic> result;
      if (kIsWeb) {
        Uint8List finalBytes = _selectedFile!.bytes!;
        if (_compressPdf && _selectedFile!.name.toLowerCase().endsWith('.pdf') && _selectedFile!.size > 50 * 1024 * 1024) {
          try {
            finalBytes = await ILovePdfService().compressPdf(finalBytes, _selectedFile!.name);
          } catch (e) {
            debugPrint('Lỗi nén PDF Web: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        }
        result = await storage.uploadFileWeb(
          path,
          finalBytes,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
      } else {
        File fileToUpload = File(_selectedFile!.path!);
        if (_compressPdf && _selectedFile!.name.toLowerCase().endsWith('.pdf') && _selectedFile!.size > 50 * 1024 * 1024) {
          try {
            final compressedPath = await PdfManipulator().pdfCompressor(
              params: PDFCompressorParams(
                pdfPath: _selectedFile!.path!,
                imageQuality: 50,
                imageScale: 0.5,
              ),
            );
            if (compressedPath != null && compressedPath.isNotEmpty) {
               fileToUpload = File(compressedPath);
            }
          } catch (e) {
            debugPrint('Lỗi nén PDF: $e');
          }
        }
        
        result = await storage.uploadFile(
          path,
          fileToUpload,
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
