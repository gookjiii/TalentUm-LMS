enum MessageType { text, image, file, audio }

class Message {
  const Message({
    required this.id,
    required this.classId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.attachments,
    required this.createdAt,
    this.editedAt,
    this.deleted = false,
  });

  final String id;
  final String classId;
  final String senderId;
  final MessageType type;
  final String content;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool deleted;
}
