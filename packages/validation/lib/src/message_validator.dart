import 'validation_result.dart';

class MessageValidator {
  static const maxTextLength = 2000;
  static const maxAttachments = 10;
  static const allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  static ValidationResult validateText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return invalid('Message cannot be empty');
    if (trimmed.length > maxTextLength) return invalid('Message too long');
    return valid;
  }

  static ValidationResult validateAttachments({
    required int count,
    required Iterable<String> mimeTypes,
  }) {
    if (count > maxAttachments) return invalid('Too many attachments');
    for (final mimeType in mimeTypes) {
      if (!allowedMimeTypes.contains(mimeType)) {
        return invalid('Attachment type not allowed');
      }
    }
    return valid;
  }
}
