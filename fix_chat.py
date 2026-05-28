with open('lib/src/screens/class_chat_screen.dart', 'r') as f:
    c = f.read()

# Define exactly what to replace
old = """  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final senderId = data['senderId'] as String? ?? '?';
    final initial = senderId.isNotEmpty ? senderId[0].toUpperCase() : '?';
    final text = data['text'] as String? ?? '';
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final attachments =
        List<Map<String, dynamic>>.from(data['attachments'] ?? []);
    final reactions = data['reactions'] as Map<String, dynamic>? ?? {};
    final seenBy = List<String>.from(data['seenBy'] ?? []);
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final timeLabel = createdAt != null
        ? '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';"""

new = """  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final senderId = data['senderId'] as String? ?? '?';
    final initial = senderId.isNotEmpty ? senderId[0].toUpperCase() : '?';
    final text = data['text'] as String? ?? '';
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final attachments =
        List<Map<String, dynamic>>.from(data['attachments'] ?? []);
    final reactions = data['reactions'] as Map<String, dynamic>? ?? {};
    final seenBy = List<String>.from(data['seenBy'] ?? []);
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final timeLabel = createdAt != null
        ? '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (!isMe && uid != null && !seenBy.contains(uid)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        repo.markAsSeen(data['id'] ?? '');
      });
    }"""

c = c.replace(old, new)
with open('lib/src/screens/class_chat_screen.dart', 'w') as f:
    f.write(c)
