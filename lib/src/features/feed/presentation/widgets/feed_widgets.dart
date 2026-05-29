import 'package:school_world/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/utils/open_external_url.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.doc,
    required this.classData,
    required this.canManage,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Map<String, dynamic> classData;
  final bool canManage;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? _authorFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initFuture();
    }
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.data()['authorId'] != widget.doc.data()['authorId']) {
      _initFuture();
    }
  }

  void _initFuture() {
    final repo = AppScope.of(context).repository;
    final authorId = widget.doc.data()['authorId']?.toString() ?? '';
    _authorFuture = repo.firestore.collection('users').doc(authorId).get();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    final authorId = data['authorId']?.toString() ?? AppLocalizations.of(context)!.teacher;
    final content = data['content']?.toString() ?? '';
    final pinned = data['pinned'] == true;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = uid != null && likes.contains(uid);
    final attachments = List<Map<String, dynamic>>.from(
      data['attachments'] ?? [],
    );

    final classColor = parseHexColor(widget.classData['coverColor']);
    final className = widget.classData['name']?.toString() ?? '';

    return SchoolCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _authorFuture,
                builder: (context, userSnap) {
                  final authorName =
                      userSnap.data?.data()?['name']?.toString() ?? authorId;
                  return Expanded(
                    child: Row(
                      children: [
                        SchoolAvatar(
                          name: authorName,
                          color: classColor,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorId == uid ? AppLocalizations.of(context)!.you : authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatTimestamp(data['createdAt']),
                                style: const TextStyle(
                                  color: SchoolColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              if (pinned)
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: StatusChip(
                    label: AppLocalizations.of(context)!.pinned,
                    color: SchoolColors.yellow,
                    icon: Icons.push_pin,
                    iconSize: 10,
                  ),
                ),
              if (widget.canManage) _PostMenu(doc: widget.doc),
            ],
          ),
          const SizedBox(height: 12),
          _PostTag(name: className, color: classColor),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: SchoolColors.text,
            ),
          ),
          if (attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: attachments.first['url'],
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.grey[200]),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _PostReactionRow(
            doc: widget.doc,
            isLiked: isLiked,
            likesCount: likes.length,
            commentsCount: (data['comments'] as List? ?? []).length,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Object? timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return 'сегодня · ${DateFormat.Hm().format(date)}';
      }
      return DateFormat('d MMM · H:mm', 'ru').format(date);
    }
    return AppLocalizations.of(context)!.justNow1;
  }
}

class _PostTag extends StatelessWidget {
  const _PostTag({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostReactionRow extends StatelessWidget {
  const _PostReactionRow({
    required this.doc,
    required this.isLiked,
    required this.likesCount,
    required this.commentsCount,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isLiked;
  final int likesCount;
  final int commentsCount;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => repo.toggleLike(doc.id, isLiked),
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: isLiked ? SchoolColors.red : SchoolColors.muted,
          ),
          label: Text(
            '$likesCount',
            style: TextStyle(
              color: isLiked ? SchoolColors.red : SchoolColors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _showComments(context, doc),
          icon: const Icon(
            Icons.chat_bubble_outline,
            size: 18,
            color: SchoolColors.muted,
          ),
          label: Text(
            '$commentsCount',
            style: const TextStyle(
              color: SchoolColors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.bookmarksWillAppearInThe),
              ),
            );
          },
          icon: const Icon(
            Icons.bookmark_border,
            size: 20,
            color: SchoolColors.muted,
          ),
        ),
      ],
    );
  }

  void _showComments(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentSheet(doc: doc),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _CommentSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.id != widget.doc.id) {
      _initStream();
    }
  }

  void _initStream() {
    final repo = AppScope.of(context).repository;
    _stream = repo.firestore.collection('posts').doc(widget.doc.id).snapshots();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? widget.doc.data();
        final comments = List<Map<String, dynamic>>.from(
          data['comments'] ?? [],
        );
        comments.sort((a, b) {
          final ta = a['createdAt'] as Timestamp?;
          final tb = b['createdAt'] as Timestamp?;
          if (ta == null || tb == null) return 0;
          return tb.compareTo(ta);
        });

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SchoolColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.comments,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                ),
                child: comments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            AppLocalizations.of(context)!.noCommentsYet,
                            style: TextStyle(color: SchoolColors.muted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SchoolAvatar(
                                name: c['authorId']?.toString() ?? 'U',
                                radius: 16,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c['authorId'] == repo.uid
                                              ? AppLocalizations.of(context)!.you
                                              : AppLocalizations.of(context)!.user,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatTime(c['createdAt']),
                                          style: const TextStyle(
                                            color: SchoolColors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c['content']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.addAComment,
                        filled: true,
                        fillColor: SchoolColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_sending)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton.filled(
                      onPressed: () => _send(repo),
                      icon: const Icon(Icons.send_rounded),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _send(SchoolRepository repo) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await repo.addComment(postId: widget.doc.id, content: text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatTime(dynamic t) {
    if (t is! Timestamp) return '';
    final d = t.toDate();
    return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _PostMenu extends StatelessWidget {
  const _PostMenu({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final pinned = doc.data()['pinned'] == true;
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'pin')
          repo.firestore.collection('posts').doc(doc.id).update({
            'pinned': !pinned,
          });
        if (val == 'delete')
          repo.firestore.collection('posts').doc(doc.id).delete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'pin',
          child: Text(pinned ? AppLocalizations.of(context)!.unpin : AppLocalizations.of(context)!.pin),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class _AttachmentCarousel extends StatelessWidget {
  const _AttachmentCarousel({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(left: 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: images[i],
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file});
  final Map<String, dynamic> file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.insert_drive_file_outlined),
      title: Text(file['name'] ?? AppLocalizations.of(context)!.file2),
      onTap: () => openExternalUrl(file['url']),
    );
  }
}
