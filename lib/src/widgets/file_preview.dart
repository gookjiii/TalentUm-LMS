import 'package:school_world/l10n/app_localizations.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/utils/open_external_url.dart';
import 'package:school_world/src/widgets/image_viewer.dart';
import 'package:school_world/src/widgets/document_preview_dialog.dart';


/// Formatting helper for file sizes.
String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB'];
  final i = (bytes.toDouble() <= 0)
      ? 0
      : (bytes.toDouble() / 1024).floor().clamp(0, suffixes.length - 1);
  return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
}

/// A highly polished, modern file and document preview card for student and teacher spaces.
/// Supports both local picked files ([PlatformFile]) and remote Firebase attachments ([Map<String, dynamic>]).
class FilePreviewWidget extends StatelessWidget {
  const FilePreviewWidget({
    super.key,
    this.localFile,
    this.remoteFile,
    this.onRemove,
  });

  /// The local picked file (from FilePicker).
  final PlatformFile? localFile;

  /// The remote saved file map from Firestore.
  final Map<String, dynamic>? remoteFile;

  /// Optional removal callback. If provided, renders a delete/remove button.
  final VoidCallback? onRemove;

  bool get isRemote => remoteFile != null;

  String get name {
    if (isRemote) return remoteFile!['name']?.toString() ?? 'Вложение';
    return localFile?.name ?? 'Вложение';
  }

  int get size {
    if (isRemote) return (remoteFile!['size'] as num?)?.toInt() ?? 0;
    return localFile?.size ?? 0;
  }

  String get url {
    if (isRemote)
      return remoteFile!['url']?.toString() ??
          remoteFile!['uri']?.toString() ??
          '';
    return '';
  }

  /// Check if the file is an image format.
  bool get isImage {
    final ext = _extension.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext);
  }

  bool get isPdf => _extension.toLowerCase() == 'pdf';

  bool get isWord {
    final ext = _extension.toLowerCase();
    return ['doc', 'docx'].contains(ext);
  }

  String get _extension {
    final n = name;
    if (n.contains('.')) {
      return n.substring(n.lastIndexOf('.') + 1);
    }
    return '';
  }

  void _handleTap(BuildContext context) {
    if (isImage) {
      if (isRemote) {
        showDialog(
          context: context,
          builder: (_) => ImageViewer(imageUrl: url),
        );
      } else {
        // Preview local image
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: kIsWeb
                        ? (localFile!.bytes != null
                              ? Image.memory(localFile!.bytes!)
                              : const SizedBox.shrink())
                        : (localFile!.path != null
                              ? Image.file(File(localFile!.path!))
                              : const SizedBox.shrink()),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else if (isRemote && url.isNotEmpty) {
      final isDoc = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'csv'].contains(_extension.toLowerCase());
      if (isDoc) {
        showDialog(
          context: context,
          builder: (_) => DocumentPreviewDialog(
            url: url,
            fileName: name,
          ),
        );
      } else {
        openExternalUrl(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Card background decoration and styling
    final baseBgColor = isDark ? Colors.grey.shade900 : Colors.white;
    final extensionLabel = _extension.toUpperCase();

    // HSL based accent colors for files
    Color docAccentColor = SchoolColors.primary;
    if (isPdf) {
      docAccentColor = SchoolColors.red;
    } else if (isWord) {
      docAccentColor = const Color(0xFF2563EB); // Word Blue
    } else if (isImage) {
      docAccentColor = SchoolColors.green;
    }

    Widget previewThumbnail;

    if (isImage) {
      if (isRemote) {
        previewThumbnail = CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          placeholder: (_, __) => Container(
            color: theme.colorScheme.surfaceVariant,
            width: 56,
            height: 56,
          ),
          errorWidget: (_, __, ___) => Container(
            color: theme.colorScheme.surfaceVariant,
            width: 56,
            height: 56,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 20,
              color: SchoolColors.muted,
            ),
          ),
        );
      } else {
        // Local image thumbnail
        previewThumbnail = SizedBox(
          width: 56,
          height: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? (localFile!.bytes != null
                      ? Image.memory(localFile!.bytes!, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: SchoolColors.muted))
                : (localFile!.path != null
                      ? Image.file(File(localFile!.path!), fit: BoxFit.cover)
                      : const Icon(Icons.image, color: SchoolColors.muted)),
          ),
        );
      }
    } else {
      // Document tag / badge icon
      previewThumbnail = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: docAccentColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: docAccentColor.withOpacity(0.24)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPdf
                    ? Icons.picture_as_pdf_rounded
                    : isWord
                    ? Icons.description_rounded
                    : Icons.insert_drive_file_rounded,
                color: docAccentColor,
                size: 24,
              ),
              if (extensionLabel.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  extensionLabel.substring(
                    0,
                    math.min(extensionLabel.length, 4),
                  ),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: docAccentColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: baseBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : SchoolColors.border,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleTap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: previewThumbnail,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            _formatBytes(size),
                            style: const TextStyle(
                              fontSize: 11,
                              color: SchoolColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isRemote && url.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 2,
                              backgroundColor: SchoolColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isImage ? AppLocalizations.of(context)!.view : AppLocalizations.of(context)!.open,
                              style: TextStyle(
                                fontSize: 11,
                                color: docAccentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else if (isRemote && url.isNotEmpty)
                  Icon(
                    isImage
                        ? Icons.visibility_rounded
                        : Icons.open_in_new_rounded,
                    color: docAccentColor.withOpacity(0.7),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
