import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:school_world/src/features/chat/domain/models/chat_attachment.dart';
import 'package:school_world/src/theme.dart';

class PendingAttachmentPreview extends StatelessWidget {
  const PendingAttachmentPreview({
    super.key,
    required this.attachment,
    required this.onCancel,
  });
  final PickedChatAttachment attachment;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SchoolColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SchoolColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _PreviewThumb(attachment: attachment),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${attachment.type.name.toUpperCase()} · ${attachment.formattedSize}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: SchoolColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: SchoolColors.muted,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _PreviewThumb extends StatelessWidget {
  const _PreviewThumb({required this.attachment});
  final PickedChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final icon = switch (attachment.type) {
      AttachmentType.image => Icons.image_rounded,
      AttachmentType.video => Icons.play_circle_outline_rounded,
      _ => Icons.insert_drive_file_rounded,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: SchoolColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: (attachment.type == AttachmentType.image)
          ? (kIsWeb && attachment.file.bytes != null
                ? Image.memory(attachment.file.bytes!, fit: BoxFit.cover)
                : (attachment.file.path != null
                      ? Image.file(
                          File(attachment.file.path!),
                          fit: BoxFit.cover,
                        )
                      : Icon(icon, color: SchoolColors.primary, size: 22)))
          : Icon(icon, color: SchoolColors.primary, size: 22),
    );
  }
}
