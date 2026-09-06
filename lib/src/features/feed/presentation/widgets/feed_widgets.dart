import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/utils/string_extensions.dart';

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
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _authorStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initStream();
    }
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.data()['authorId'] != widget.doc.data()['authorId']) {
      _initStream();
    }
  }

  void _initStream() {
    final repo = AppScope.of(context).repository;
    final authorId = widget.doc.data()['authorId']?.toString() ?? '';
    if (authorId.isNotEmpty) {
      _authorStream = repo.firestore.collection('users').doc(authorId).snapshots();
    } else {
      _authorStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    final rawAuthorId = data['authorId']?.toString();
    final authorId = rawAuthorId ?? '';
    final isAuthor = uid != null && uid == authorId;
    final canShowMenu = widget.canManage || isAuthor;

    final content = data['content']?.toString() ?? '';
    final pinned = data['pinned'] == true;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = uid != null && likes.contains(uid);
    final attachments = List<Map<String, dynamic>>.from(
      data['attachments'] ?? [],
    );

    final classColor = parseHexColor(widget.classData['coverColor']);
    final className = widget.classData['name']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SchoolCard(
      padding: const EdgeInsets.all(20),
      color: pinned
          ? (isDark ? const Color(0xFF231B38) : const Color(0xFFFAF7FF))
          : null,
      borderColor: pinned
          ? SchoolColors.primary.withValues(alpha: isDark ? 0.45 : 0.35)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _authorStream,
                builder: (context, userSnap) {
                  final authorName =
                      userSnap.data?.data()?['name']?.toString() ??
                          (authorId.isNotEmpty
                              ? authorId
                              : AppLocalizations.of(context)!.teacher);
                  return Expanded(
                    child: Row(
                      children: [
                        SchoolAvatar(
                          name: authorName,
                          userId: authorId.isNotEmpty ? authorId : null,
                          color: classColor,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAuthor
                                    ? AppLocalizations.of(context)!.you
                                    : authorName,
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
                  padding: const EdgeInsets.only(right: 8),
                  child: StatusChip(
                    label: AppLocalizations.of(context)!.pinned,
                    color: SchoolColors.primary,
                    icon: Icons.push_pin,
                    iconSize: 10,
                  ),
                ),
              if (canShowMenu)
                _PostMenu(
                  doc: widget.doc,
                  canManage: widget.canManage,
                  isAuthor: isAuthor,
                ),
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
                  imageUrl: (attachments.first['url'] as String)
                      .toDirectImageUrl
                      .toOptimizedCloudinary(
                        performance: AppScope.of(
                          context,
                        ).appState.performanceMode,
                      ),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Theme.of(context).dividerColor.withValues(
                      alpha: 0.05,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _PostReactionRow(
            doc: widget.doc,
            isLiked: isLiked,
            likesCount: likes.length,
            commentsCount: data['commentsCount'] ?? 0,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Material(
          color: isLiked
              ? (isDark ? const Color(0xFF451A20) : const Color(0xFFFEE2E2))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              repo.toggleLike(doc.id, isLiked);
            },
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isLiked
                      ? SchoolColors.red.withValues(alpha: 0.3)
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 17,
                    color: isLiked
                        ? SchoolColors.red
                        : (isDark ? Colors.white70 : SchoolColors.muted),
                  ),
                  if (likesCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$likesCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLiked
                            ? SchoolColors.red
                            : (isDark
                                ? Colors.white70
                                : SchoolColors.textSecondary),
                        fontWeight:
                            isLiked ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            onTap: () => _showComments(context, doc),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: isDark ? Colors.white70 : SchoolColors.muted,
                  ),
                  if (commentsCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$commentsCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white70
                            : SchoolColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.bookmarksWillAppearInThe,
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.bookmark_border_rounded,
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
                                userId: c['authorId']?.toString(),
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
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.you
                                              : AppLocalizations.of(
                                                  context,
                                                )!.user,
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
  const _PostMenu({
    required this.doc,
    required this.canManage,
    required this.isAuthor,
  });
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool canManage;
  final bool isAuthor;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final pinned = doc.data()['pinned'] == true;
    final l10n = AppLocalizations.of(context)!;

    final canPin = canManage;
    final canEdit = canManage || isAuthor;
    final canDelete = canManage || isAuthor;

    return PopupMenuButton<String>(
      tooltip: l10n.unknownKey6,
      icon: const Icon(Icons.more_horiz_rounded, color: SchoolColors.muted),
      onSelected: (val) async {
        if (val == 'pin') {
          repo.firestore.collection('posts').doc(doc.id).update({
            'pinned': !pinned,
          });
        } else if (val == 'edit') {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: _EditPostSheet(
                doc: doc,
                canManagePin: canManage,
              ),
            ),
          );
        } else if (val == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.delete),
              content: Text('${l10n.delete}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    l10n.delete,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await repo.deletePost(doc.id);
          }
        }
      },
      itemBuilder: (_) => [
        if (canPin)
          PopupMenuItem(
            value: 'pin',
            child: Text(
              pinned ? l10n.unpin : l10n.pin,
            ),
          ),
        if (canEdit)
          PopupMenuItem(
            value: 'edit',
            child: Text(l10n.edit),
          ),
        if (canDelete)
          PopupMenuItem(
            value: 'delete',
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}

class _EditPostSheet extends StatefulWidget {
  const _EditPostSheet({
    required this.doc,
    required this.canManagePin,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool canManagePin;

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late final TextEditingController _controller;
  late bool _isPinned;
  List<Map<String, dynamic>> _existingAttachments = [];
  PlatformFile? _pickedFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data();
    _controller = TextEditingController(text: data['content']?.toString() ?? '');
    _isPinned = data['pinned'] == true;
    _existingAttachments = List<Map<String, dynamic>>.from(data['attachments'] ?? []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.80;
    final l10n = AppLocalizations.of(context)!;
    final canSave = _controller.text.trim().isNotEmpty ||
        _pickedFile != null ||
        _existingAttachments.isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 600),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header: Title + Close ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.edit,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Scrollable body ──
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      minLines: 2,
                      maxLines: 8,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l10n.postAnAnnouncementForClasses,
                        filled: true,
                        fillColor: SchoolColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_existingAttachments.isNotEmpty && _pickedFile == null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: (_existingAttachments.first['url'] as String)
                                  .toDirectImageUrl
                                  .toOptimizedCloudinary(
                                    performance: AppScope.of(context).appState.performanceMode,
                                  ),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filled(
                                onPressed: () => setState(() => _existingAttachments.clear()),
                                icon: const Icon(Icons.close, size: 18),
                                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_pickedFile != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            if (_pickedFile!.bytes != null)
                              Image.memory(
                                _pickedFile!.bytes!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            else if (_pickedFile!.path != null)
                              Image.file(
                                File(_pickedFile!.path!),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filled(
                                onPressed: () => setState(() => _pickedFile = null),
                                icon: const Icon(Icons.close, size: 18),
                                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Bottom bar: Attach + Pin + Save ──
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null) {
                      setState(() {
                        _pickedFile = result.files.first;
                        _existingAttachments.clear();
                      });
                    }
                  },
                  icon: Icon(
                    Icons.image_outlined,
                    color: (_pickedFile != null || _existingAttachments.isNotEmpty)
                        ? SchoolColors.primary
                        : SchoolColors.muted,
                  ),
                ),
                if (widget.canManagePin)
                  IconButton(
                    onPressed: () => setState(() => _isPinned = !_isPinned),
                    icon: Icon(
                      _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: _isPinned ? SchoolColors.orange : SchoolColors.muted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Save button: full width, always visible ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: _isSaving
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : FilledButton.icon(
                      onPressed: canSave ? _save : null,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        l10n.save,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final repo = AppScope.of(context).repository;
    setState(() => _isSaving = true);
    try {
      List<Map<String, dynamic>> finalAttachments = List.from(_existingAttachments);
      if (_pickedFile != null) {
        final classId = widget.doc.data()['classId']?.toString() ?? 'common';
        final path =
            'classes/$classId/feed/${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
        Map<String, dynamic>? uploaded;
        if (_pickedFile!.bytes != null) {
          uploaded = await repo.uploadFileWeb(path, _pickedFile!.bytes!);
        } else if (_pickedFile!.path != null) {
          uploaded = await repo.uploadFile(path, File(_pickedFile!.path!));
        }
        if (uploaded != null) {
          finalAttachments = [
            {
              'type': 'image',
              ...uploaded,
              'name': _pickedFile!.name,
              'size': _pickedFile!.size,
            }
          ];
        }
      }

      await repo.updatePost(
        postId: widget.doc.id,
        content: _controller.text.trim(),
        pinned: _isPinned,
        attachments: finalAttachments,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
