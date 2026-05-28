import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';

class TopicSidebar extends StatefulWidget {
  const TopicSidebar({
    super.key,
    required this.chatController,
    required this.isTeacher,
    required this.currentUserId,
    this.onTopicChanged,
  });

  final FirebaseChatController chatController;
  final bool isTeacher;
  final String currentUserId;
  final ValueChanged<String?>? onTopicChanged;

  @override
  State<TopicSidebar> createState() => _TopicSidebarState();
}

class _TopicSidebarState extends State<TopicSidebar> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _topicsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant TopicSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatController.roomId != widget.chatController.roomId) {
      _initStream();
    }
  }

  void _initStream() {
    _topicsStream = widget.chatController.firestore
        .collection('rooms')
        .doc(widget.chatController.roomId)
        .collection('topics')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final activeTopicId = widget.chatController.currentTopicId;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.topics,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (widget.isTeacher)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 22,
                    ),
                    onPressed: () => _createTopic(context),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: l10n.createTopic,
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _topicsStream,
              builder: (context, snapshot) {
                final topics = snapshot.data?.docs ?? [];
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _TopicItem(
                      title: l10n.mainChat,
                      icon: Icons.forum_rounded,
                      isActive: activeTopicId == null,
                      onTap: () {
                        widget.chatController.setTopicId(null);
                        widget.onTopicChanged?.call(null);
                      },
                    ),
                    if (topics.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ),
                      ...topics.map((doc) {
                        final data = doc.data();
                        final name = data['name']?.toString() ?? '';
                        return _TopicItem(
                          title: name,
                          icon: Icons.tag_rounded,
                          isActive: activeTopicId == doc.id,
                          onTap: () {
                            widget.chatController.setTopicId(doc.id);
                            widget.onTopicChanged?.call(doc.id);
                          },
                          onDelete: widget.isTeacher
                              ? () => _deleteTopic(context, doc.id, name)
                              : null,
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _createTopic(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newTopic),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                await widget.chatController.firestore
                    .collection('rooms')
                    .doc(widget.chatController.roomId)
                    .collection('topics')
                    .add({
                      'name': name,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy': widget.currentUserId,
                    });
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _deleteTopic(BuildContext context, String topicId, String topicName) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тему?'),
        content: Text('Вы уверены, что хотите удалить тему "$topicName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              if (widget.chatController.currentTopicId == topicId) {
                widget.chatController.setTopicId(null);
                widget.onTopicChanged?.call(null);
              }
              await widget.chatController.firestore
                  .collection('rooms')
                  .doc(widget.chatController.roomId)
                  .collection('topics')
                  .doc(topicId)
                  .delete();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _TopicItem extends StatelessWidget {
  const _TopicItem({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.onDelete,
  });

  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: isActive
            ? theme.colorScheme.primary.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(
            icon,
            size: 18,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              fontSize: 14,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  color: Colors.redAccent.withOpacity(0.7),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
              if (isActive && onDelete != null) const SizedBox(width: 8),
              if (isActive)
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
