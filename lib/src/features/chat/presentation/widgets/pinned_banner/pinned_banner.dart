import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class PinnedBanner extends StatefulWidget {
  const PinnedBanner({
    super.key,
    required this.classId,
    required this.repository,
    required this.chatController,
  });
  final String classId;
  final SchoolRepository repository;
  final FirebaseChatController chatController;

  @override
  State<PinnedBanner> createState() => _PinnedBannerState();
}

class _PinnedBannerState extends State<PinnedBanner> {
  int _currentIndex = 0;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant PinnedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatController.roomId != widget.chatController.roomId) {
      _initStream();
    }
  }

  void _initStream() {
    _stream = widget.repository.firestore
        .collection('rooms')
        .doc(widget.chatController.roomId)
        .snapshots();
  }

  void _showPinnedMessages(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinnedMessagesSheet(
        classId: widget.classId,
        repository: widget.repository,
        chatController: widget.chatController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final roomData = snapshot.data?.data();
        final pinnedIds = List<String>.from(
          roomData?['pinnedMessageIds'] ?? [],
        );
        if (pinnedIds.isEmpty) return const SizedBox.shrink();

        // Ensure index is valid
        if (_currentIndex >= pinnedIds.length) {
          _currentIndex = pinnedIds.length - 1;
        }
        if (_currentIndex < 0) _currentIndex = 0;

        final pinnedId = pinnedIds.reversed.toList()[_currentIndex];

        return FutureBuilder<Message?>(
          future: _fetchMessage(pinnedId),
          builder: (context, msgSnap) {
            final msg = msgSnap.data;
            if (msg == null) return const SizedBox.shrink();

            String content = '';
            bool hasAttachment = false;
            if (msg is TextMessage) {
              content = msg.text;
            } else if (msg is ImageMessage) {
              content = 'Фотография';
              hasAttachment = true;
            } else if (msg is FileMessage) {
              content = msg.name;
              hasAttachment = true;
            }

            return InkWell(
              onTap: () => widget.chatController.scrollToMessage(msg.id),
              onLongPress: () => _showPinnedMessages(context),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.2 : 0.03,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Container(
                      width: 2.5,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Закреплённое сообщение',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              if (pinnedIds.length > 1) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '#${pinnedIds.length - _currentIndex}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            hasAttachment ? '📎 $content' : content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pinnedIds.length > 1)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex =
                                (_currentIndex + 1) % pinnedIds.length;
                          });
                        },
                        icon: const Icon(Icons.skip_next_rounded, size: 20),
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                    IconButton(
                      onPressed: () =>
                          widget.chatController.unpinMessage(msg.id),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Message?> _fetchMessage(String messageId) async {
    // First check local controller
    final local = widget.chatController.messages.where(
      (m) => m.id == messageId,
    );
    if (local.isNotEmpty) return local.first;

    // Fetch from Firestore
    final doc = await widget.repository.firestore
        .collection('rooms')
        .doc(widget.chatController.roomId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!doc.exists) return null;
    return widget.chatController.toMessage(doc.id, doc.data()!);
  }
}

class PinnedMessagesSheet extends StatefulWidget {
  const PinnedMessagesSheet({
    super.key,
    required this.classId,
    required this.repository,
    required this.chatController,
  });
  final String classId;
  final SchoolRepository repository;
  final FirebaseChatController chatController;

  @override
  State<PinnedMessagesSheet> createState() => _PinnedMessagesSheetState();
}

class _PinnedMessagesSheetState extends State<PinnedMessagesSheet> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant PinnedMessagesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatController.roomId != widget.chatController.roomId) {
      _initStream();
    }
  }

  void _initStream() {
    _stream = widget.repository.firestore
        .collection('rooms')
        .doc(widget.chatController.roomId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Container(
      height: size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.push_pin_rounded, color: SchoolColors.orange),
                const SizedBox(width: 12),
                Text(
                  'Закреплённые сообщения',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final roomData = snapshot.data?.data();
                final pinnedIds = List<String>.from(
                  roomData?['pinnedMessageIds'] ?? [],
                );

                if (pinnedIds.isEmpty) {
                  return const _EmptyPinnedState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: pinnedIds.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final messageId = pinnedIds.reversed.toList()[index];
                    return FutureBuilder<Message?>(
                      future: _fetchSingleMessage(messageId),
                      builder: (context, msgSnap) {
                        final msg = msgSnap.data;
                        if (msg == null) return const SizedBox.shrink();
                        return PinnedChatMessageItem(
                          message: msg,
                          repository: widget.repository,
                          chatController: widget.chatController,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Message?> _fetchSingleMessage(String messageId) async {
    final local = widget.chatController.messages.where((m) => m.id == messageId);
    if (local.isNotEmpty) return local.first;

    final doc = await widget.repository.firestore
        .collection('rooms')
        .doc(widget.chatController.roomId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!doc.exists) return null;
    return widget.chatController.toMessage(doc.id, doc.data()!);
  }
}

class PinnedChatMessageItem extends StatelessWidget {
  const PinnedChatMessageItem({
    super.key,
    required this.message,
    required this.repository,
    required this.chatController,
  });
  final Message message;
  final SchoolRepository repository;
  final FirebaseChatController chatController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String content = '';
    IconData? icon;
    if (message is TextMessage) {
      content = (message as TextMessage).text;
    } else if (message is ImageMessage) {
      content = 'Фотография';
      icon = Icons.image_rounded;
    } else if (message is FileMessage) {
      content = (message as FileMessage).name;
      icon = Icons.insert_drive_file_rounded;
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        chatController.scrollToMessage(message.id);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SchoolAvatar(name: message.authorId, radius: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: repository.getUserData(message.authorId),
                    builder: (context, snap) {
                      return Text(
                        snap.data?['name']?.toString() ?? '...',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                Text(
                  _formatTime(message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => chatController.unpinMessage(message.id),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPinnedState extends StatelessWidget {
  const _EmptyPinnedState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.push_pin_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет закреплённых сообщений',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime? dt) {
  if (dt == null) return '';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
