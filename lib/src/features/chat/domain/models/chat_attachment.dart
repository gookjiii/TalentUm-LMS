import 'dart:math';
import 'package:file_picker/file_picker.dart';

enum AttachmentType { image, video, file }

class PickedChatAttachment {
  const PickedChatAttachment({
    required this.file,
    required this.name,
    required this.size,
    required this.type,
    required this.mimeType,
  });

  final PlatformFile file;
  final String name;
  final int size;
  final AttachmentType type;
  final String mimeType;

  factory PickedChatAttachment.fromFile(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    final type = switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'gif' => AttachmentType.image,
      'mp4' || 'mov' || 'avi' || 'mkv' || 'webm' => AttachmentType.video,
      _ => AttachmentType.file,
    };

    final mimeType = _mimeTypeForExtension(ext);

    return PickedChatAttachment(
      file: file,
      name: file.name,
      size: file.size,
      type: type,
      mimeType: mimeType,
    );
  }

  String get formattedSize => formatBytes(size);

  static String _mimeTypeForExtension(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      'avi' => 'video/x-msvideo',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'zip' => 'application/zip',
      _ => 'application/octet-stream',
    };
  }

  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
