import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/src/app_state.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import 'package:school_world/src/features/chat/domain/models/chat_attachment.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/features/chat/data/reactions_notifier.dart';
import 'package:school_world/src/utils/open_external_url.dart';
import 'package:school_world/src/widgets/image_viewer.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/providers/connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:school_world/src/theme.dart';

import '../widgets/chat_message_list/chat_message_list.dart';
import '../widgets/chat_bubble/chat_bubble_builders.dart';
import '../widgets/chat_input/chat_input.dart';
import '../widgets/chat_header/chat_header.dart';
import '../widgets/pinned_banner/pinned_banner.dart';
import '../widgets/resource_sidebar/resource_sidebar.dart';
import '../widgets/topic_sidebar.dart';

class ClassChatScreen extends ConsumerStatefulWidget {
  const ClassChatScreen({
    super.key,
    required this.repository,
    required this.appState,
    required this.classId,
    required this.canInitializeRoom,
    this.preloadedController,
    this.initialTopicId,
    this.initialShowTopicsSidebar = false,
    this.onBack,
    this.onTopicChanged,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;
  final String classId;
  final bool canInitializeRoom;
  final FirebaseChatController? preloadedController;
  final String? initialTopicId;
  final bool initialShowTopicsSidebar;
  final VoidCallback? onBack;
  final ValueChanged<String?>? onTopicChanged;

  @override
  ConsumerState<ClassChatScreen> createState() => _ClassChatScreenState();
}

class _ClassChatScreenState extends ConsumerState<ClassChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;
  String? _errorMessage;
  String? _roomId;
  String? _roomName;
  Message? _replyingTo;
  Message? _editingMessage;
  FirebaseChatController? _chatController;

  final Map<String, User> _userCache = {};
  final Set<String> _seenMarkQueued = {};
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showResourceSidebar = false;
  bool _showTopicsSidebar = false;
  bool _topicsInitialized = false;
  int _sidebarInitialTab = 0;
  bool _isTeacher = false;
  PickedChatAttachment? _pendingAttachment;
  bool _uploading = false;
  bool _loadingRoom = false;
  Color? _classColor;
  String? _classTeacherId;

  late ChatBubbleBuilders _bubbleBuilders;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_topicsInitialized) {
      _topicsInitialized = true;
      final wide = MediaQuery.sizeOf(context).width >= 700;
      _showTopicsSidebar = widget.initialShowTopicsSidebar || wide;
    }
  }

  @override
  void didUpdateWidget(ClassChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      if (oldWidget.preloadedController == null) {
        _chatController?.stopListening();
        _chatController?.dispose();
      }
      _chatController = null;
      _textController.clear();
      _searchController.clear();
      _seenMarkQueued.clear();
      _userCache.clear();
      _loadingRoom = false; // allow fresh load for new classId
      setState(() {
        _roomId = null;
        _roomName = null;
        _loading = true;
        _errorMessage = null;
        _replyingTo = null;
        _editingMessage = null;
        _pendingAttachment = null;
      });
      _loadRoom();
    } else if (oldWidget.preloadedController != widget.preloadedController) {
      if (oldWidget.preloadedController == null) {
        _chatController?.stopListening();
        _chatController?.dispose();
      }
      _chatController = widget.preloadedController;
      if (_chatController != null) {
        final id = widget.repository.uid ?? '';
        _bubbleBuilders = ChatBubbleBuilders(
          chatController: _chatController!,
          myUid: id,
          resolveUser: _resolveUser,
          showMessageOptions: _showMessageOptions,
          onReply: (msg) => setState(() => _replyingTo = msg),
          openAttachment: _openAttachment,
          roomId: _roomId ?? '',
          classColor: _classColor ?? Colors.blue,
        );
      }
      setState(() {});
    }
  }

  void _persistChatContext() {
    widget.appState.selectClass(widget.classId);
    widget.appState.saveChatContext(
      classId: widget.classId,
      topicId: _chatController?.currentTopicId,
    );
  }

  @override
  void dispose() {
    if (widget.preloadedController == null) {
      _chatController?.stopListening();
      _chatController?.dispose();
    }
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoom() async {
    if (_loadingRoom) return;
    _loadingRoom = true;
    final capturedClassId = widget.classId;

    final id = widget.repository.uid;
    if (id == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingRoom = false;
        });
      }
      return;
    }

    try {
      String? roomId;
      String roomName;
      Color color;
      String? teacherId;

      if (widget.classId == 'teachers_lounge') {
        roomId = 'global_teachers_lounge';
        roomName = 'Учительская';
        color = SchoolColors.primary;
        
        final roomDoc = await widget.repository.firestore.collection('rooms').doc(roomId).get();
        if (!roomDoc.exists) {
          await widget.repository.firestore.collection('rooms').doc(roomId).set({
            'name': roomName,
            'type': 'group',
            'userIds': [id],
            'metadata': {'isTeachersLounge': true},
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await widget.repository.firestore.collection('rooms').doc(roomId).set({
            'userIds': FieldValue.arrayUnion([id]),
          }, SetOptions(merge: true));
        }
      } else {
        final classDoc = await widget.repository.firestore
            .collection('classes')
            .doc(widget.classId)
            .get();

        if (!mounted || widget.classId != capturedClassId) return;

        if (!classDoc.exists) throw 'Класс не найден';

        teacherId = classDoc.data()?['teacherId'] as String?;
        roomId = classDoc.data()?['chatRoomId'] as String?;
        roomName = classDoc.data()?['name']?.toString() ?? 'Чат класса';
        color = parseHexColor(classDoc.data()?['coverColor']);
      }

      if (roomId == null) {
        if (!widget.canInitializeRoom) {
          if (mounted) {
            setState(() {
              _loading = false;
              _errorMessage =
                  'Chat has not been initialized by the teacher yet.';
            });
          }
          return;
        }
        final room = await widget.repository.firestore.collection('rooms').add({
          'name': roomName,
          'type': 'group',
          'userIds': [id],
          'metadata': {'classId': widget.classId},
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted || widget.classId != capturedClassId) return;

        roomId = room.id;
        await widget.repository.firestore
            .collection('classes')
            .doc(widget.classId)
            .set({'chatRoomId': roomId}, SetOptions(merge: true));
      } else {
        await widget.repository.firestore.collection('rooms').doc(roomId).set({
          'userIds': FieldValue.arrayUnion([id]),
        }, SetOptions(merge: true));
      }

      if (!mounted || widget.classId != capturedClassId) return;

      final controller =
          widget.preloadedController ??
          FirebaseChatController(
            firestore: widget.repository.firestore,
            roomId: roomId,
            topicId: widget.initialTopicId,
            onMessagesUpdated: _markMessagesSeen,
          );

      if (widget.preloadedController == null) {
        controller.startListening();
      } else if (widget.initialTopicId != controller.currentTopicId) {
        controller.setTopicId(widget.initialTopicId);
      }

      _persistChatContext();

      _bubbleBuilders = ChatBubbleBuilders(
        chatController: controller,
        myUid: id,
        resolveUser: _resolveUser,
        showMessageOptions: _showMessageOptions,
        onReply: (msg) => setState(() => _replyingTo = msg),
        openAttachment: _openAttachment,
        roomId: roomId,
        classColor: color,
      );

      setState(() {
        _roomId = roomId;
        _roomName = roomName;
        _chatController = controller;
        _isTeacher = widget.appState.isTeacher;
        _classColor = color;
        _classTeacherId = teacherId;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('ClassChatScreen _loadRoom error: $e\n$st');
      if (mounted && widget.classId == capturedClassId) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted && widget.classId == capturedClassId) {
        setState(() => _loadingRoom = false);
      }
    }
  }

  void _markMessagesSeen(List<Message> msgs) {
    if (!mounted || _roomId == null) return;
    final myUid = widget.repository.uid;
    if (myUid == null) return;

    for (final msg in msgs) {
      if (msg.authorId == myUid) continue;
      if (_seenMarkQueued.contains(msg.id)) continue;
      final seenBy = List<String>.from(msg.metadata?['seenBy'] ?? []);
      if (!seenBy.contains(myUid)) {
        _seenMarkQueued.add(msg.id);
        widget.repository.markMessageAsSeen(_roomId!, msg.id);
      }
    }
  }

  Future<User?> _resolveUser(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    try {
      final d = await widget.repository.resolveUserCached(userId);
      final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
      final user = User(
        id: userId,
        name: name.isEmpty ? null : name,
        imageSource: d['imageUrl'] as String? ?? d['avatarUrl'] as String?,
      );
      _userCache[userId] = user;
      return user;
    } catch (_) {
      return User(id: userId);
    }
  }

  String _resolveUserName(String authorId) =>
      _userCache[authorId]?.name ?? 'Участник';

  Future<void> _showCreatePollDialog() async {
    final questionCtrl = TextEditingController();
    final opts = [TextEditingController(), TextEditingController()];
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Новый опрос'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionCtrl,
                  decoration: const InputDecoration(labelText: 'Вопрос'),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < opts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: opts[i],
                      decoration: InputDecoration(
                        labelText: 'Вариант ${i + 1}',
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: opts.length < 6
                      ? () => setS(() => opts.add(TextEditingController()))
                      : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Добавить вариант'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                final question = questionCtrl.text.trim();
                final validOpts = opts
                    .map((c) => c.text.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                if (question.isEmpty || validOpts.length < 2) return;
                final uid = widget.repository.auth.currentUser!.uid;
                final pollRef = await widget.repository.firestore
                    .collection('rooms')
                    .doc(_chatController!.roomId)
                    .collection('polls')
                    .add({
                      'question': question,
                      'options': [
                        for (int i = 0; i < validOpts.length; i++)
                          {'id': 'opt_$i', 'text': validOpts[i]},
                      ],
                      'votes': {},
                      'creatorId': uid,
                      'createdAt': FieldValue.serverTimestamp(),
                      'isClosed': false,
                    });
                final optLines = validOpts.map((o) => '▫ $o').join('\n');
                await _chatController!.sendText(
                  uid,
                  '📊 Опрос: $question\n$optLines\n\n→ Откройте вкладку «Опросы» для голосования',
                  metadata: {'isPollAnnouncement': true, 'pollId': pollRef.id},
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      final file = PlatformFile(
        name: photo.name,
        size: bytes.length,
        bytes: bytes,
        path: photo.path,
      );
      setState(() => _pendingAttachment = PickedChatAttachment.fromFile(file));
    } catch (_) {
      // Camera unavailable or permission denied — fail silently
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    final uid = widget.repository.uid;
    if (_chatController == null || uid == null || uid.isEmpty) return;
    if (text.isEmpty && _pendingAttachment == null) return;

    if (_editingMessage != null) {
      await _chatController!.editText(_editingMessage!.id, text);
      setState(() => _editingMessage = null);
      _textController.clear();
      return;
    }

    final attachment = _pendingAttachment;
    final confirmedText = text;

    setState(() {
      _uploading = true;
      _pendingAttachment = null;
      _textController.clear();
    });

    try {
      final metadata = _replyingTo != null
          ? {
              'replyToId': _replyingTo!.id,
              'replyToText': _replyingTo is TextMessage
                  ? (_replyingTo as TextMessage).text
                  : 'Вложение',
              'replyToSenderId': _replyingTo!.authorId,
            }
          : null;

      if (attachment != null) {
        final path =
            'classes/${widget.classId}/messages/${DateTime.now().millisecondsSinceEpoch}_${attachment.name}';
        final uploadPath = attachment.type == AttachmentType.image
            ? _asJpegPath(path)
            : path;

        Map<String, dynamic>? resultData;
        if (attachment.type == AttachmentType.image) {
          final bytes = await _compressedImageBytes(attachment.file);
          if (bytes != null)
            resultData = await widget.repository.uploadFileWeb(
              uploadPath,
              bytes,
            );
        } else if (attachment.file.bytes != null) {
          resultData = await widget.repository.uploadFileWeb(
            uploadPath,
            attachment.file.bytes!,
          );
        } else if (attachment.file.path != null) {
          resultData = await widget.repository.uploadFile(
            uploadPath,
            File(attachment.file.path!),
          );
        }

        if (resultData != null) {
          final meta = {
            ...?metadata,
            'attachmentType': attachment.type.name,
            'fileName': attachment.name,
            'fileSize': attachment.size,
            if (confirmedText.isNotEmpty) 'text': confirmedText,
          };
          await _chatController!.sendFile(
            authorId: uid,
            uri: resultData['url'] as String,
            name: attachment.name,
            size: attachment.size,
            type: attachment.type.name,
            metadata: meta,
          );
        }
      } else {
        final textMeta = Map<String, dynamic>.from(metadata ?? {});
        final linkMatch = RegExp(
          r'https?://\S+',
          caseSensitive: false,
        ).firstMatch(confirmedText);
        if (linkMatch != null) {
          textMeta['isLink'] = true;
          textMeta['linkUrl'] = linkMatch.group(0);
        }
        await _chatController!.sendText(
          uid,
          confirmedText,
          metadata: textMeta.isEmpty ? null : textMeta,
        );
      }
      if (mounted) setState(() => _replyingTo = null);
    } catch (e) {
      debugPrint('Send error: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _startEditing(Message msg) {
    if (msg is! TextMessage) return;
    setState(() {
      _editingMessage = msg;
      _textController.text = msg.text;
      _replyingTo = null;
    });
  }

  Future<void> _confirmDelete(Message msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сообщение?'),
        content: const Text('Вы действительно хотите удалить это сообщение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: SchoolColors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _chatController?.deleteMessage(msg.id);
  }

  void _showMessageOptions(Message msg, {Offset? position}) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '👏'];
    final isMe = msg.authorId == widget.repository.uid;
    final isLeadOfClass = widget.appState.isTeacher ||
        (_classTeacherId != null && _classTeacherId == widget.repository.uid);

    if (position == null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: emojis
                        .map(
                          (e) => InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _addReaction(msg.id, e);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.reply_rounded),
                  title: Text(l10n.reply),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _replyingTo = msg);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: Text(l10n.pin),
                  onTap: () {
                    Navigator.pop(context);
                    _chatController?.pinMessage(msg.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: Text(l10n.copyText),
                  onTap: () async {
                    Navigator.pop(context);
                    if (msg is TextMessage) {
                      await Clipboard.setData(ClipboardData(text: msg.text));
                    }
                  },
                ),
                if (isMe || isLeadOfClass) ...[
                  if (isMe)
                    ListTile(
                      leading: const Icon(Icons.edit_rounded),
                      title: Text(l10n.editProfile.split(' ')[0]),
                      onTap: () {
                        Navigator.pop(context);
                        _startEditing(msg);
                      },
                    ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      l10n.deletePost.split(' ')[0],
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete(msg);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } else {
      final size = MediaQuery.sizeOf(context);
      const menuWidth = 240.0;
      const reactionWidth = 320.0;

      // Calculate best position
      double left = position.dx;
      if (left + reactionWidth > size.width - 16) {
        left = size.width - reactionWidth - 16;
      }
      if (left < 16) left = 16;

      double top = position.dy;
      bool showAbove = top > size.height / 2;

      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.1),
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(),
              ),
            ),
            Positioned(
              left: left,
              top: showAbove ? top - 320 : top,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: emojis
                            .map(
                              (e) => GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _addReaction(msg.id, e);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: menuWidth,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.reply_rounded,
                            label: l10n.reply,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _replyingTo = msg);
                            },
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.push_pin_outlined,
                            label: 'Закрепить',
                            onTap: () {
                              Navigator.pop(context);
                              _chatController?.pinMessage(msg.id);
                            },
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.copy_rounded,
                            label: l10n.copyText,
                            onTap: () async {
                              Navigator.pop(context);
                              if (msg is TextMessage) {
                                await Clipboard.setData(
                                  ClipboardData(text: msg.text),
                                );
                              }
                            },
                          ),
                          if (isMe || isLeadOfClass) ...[
                            if (isMe)
                              _buildMenuItem(
                                context,
                                icon: Icons.edit_rounded,
                                label: 'Изменить',
                                onTap: () {
                                  Navigator.pop(context);
                                  _startEditing(msg);
                                },
                              ),
                            _buildMenuItem(
                              context,
                              icon: Icons.delete_outline_rounded,
                              label: 'Удалить',
                              color: Colors.red,
                              onTap: () {
                                Navigator.pop(context);
                                _confirmDelete(msg);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    final uid = widget.repository.uid;
    if (uid == null || _roomId == null) return;
    await ref
        .read(reactionsProvider(_roomId!).notifier)
        .toggle(messageId: messageId, emoji: emoji, userId: uid);
  }

  Future<void> _openAttachment(String url) async => await openExternalUrl(url);

  String _asJpegPath(String path) => path.contains('.')
      ? '${path.substring(0, path.lastIndexOf('.'))}.jpg'
      : '$path.jpg';

  Future<Uint8List?> _compressedImageBytes(PlatformFile file) async {
    Uint8List? bytes = file.bytes;
    if (bytes == null && !kIsWeb && file.path != null)
      bytes = await File(file.path!).readAsBytes();
    if (bytes == null) return null;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final resized = img.copyResize(decoded, width: 1600);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
    } catch (_) {
      return bytes;
    }
  }

  Future<void> _handleAudioSend(String path, Duration duration) async {
    final uid = widget.repository.uid;
    if (_chatController == null || uid == null) return;

    setState(() => _uploading = true);
    try {
      final uploadPath =
          'classes/${widget.classId}/messages/${DateTime.now().millisecondsSinceEpoch}_voice.m4a';

      Map<String, dynamic>? result;
      if (kIsWeb) {
        final response = await Dio().get<List<int>>(
          path,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = Uint8List.fromList(response.data!);
        result = await widget.repository.uploadFileWeb(uploadPath, bytes);
      } else {
        result = await widget.repository.uploadFile(uploadPath, File(path));
      }

      if (result != null) {
        await _chatController!.sendAudio(
          authorId: uid,
          uri: result['url'] as String,
          duration: duration,
          replyToId: _replyingTo?.id,
        );
        if (mounted) setState(() => _replyingTo = null);
      }
    } catch (e) {
      debugPrint('Audio send error: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadRoom, child: Text(l10n.tryAgain)),
              ],
            ),
          ),
        ),
      );
    }
    if (_chatController == null)
      return Scaffold(body: Center(child: Text(l10n.initializationFailed)));

    final chatContent = Column(
      children: [
        if (_chatController != null)
          ListenableBuilder(
            listenable: _chatController!.searchListenable,
            builder: (context, _) => _SearchResultsPanel(
              chatController: _chatController!,
              resolveUserName: _resolveUserName,
            ),
          ),
        Expanded(
          child: ChatMessageList(
            currentUserId: widget.repository.uid ?? '',
            resolveUser: _resolveUser,
            chatController: _chatController!,
            textMessageBuilder: _bubbleBuilders.buildTextMessage,
            imageMessageBuilder: _bubbleBuilders.buildImageMessage,
            fileMessageBuilder: _bubbleBuilders.buildFileMessage,
            audioMessageBuilder: _bubbleBuilders.buildAudioMessage,
            onImageTap: (m) => showDialog(
              context: context,
              builder: (_) => ImageViewer(imageUrl: m.source),
            ),
            onMessageLongPress: _showMessageOptions,
            onMessageSwipe: (msg) => setState(() => _replyingTo = msg),
          ),
        ),
        ChatInput(
          controller: _textController,
          onSend: _handleSend,
          onAttachment: () async {
            final res = await FilePicker.platform.pickFiles(withData: true);
            if (res != null)
              setState(
                () => _pendingAttachment = PickedChatAttachment.fromFile(
                  res.files.first,
                ),
              );
          },
          onCamera: kIsWeb ? null : _onCamera,
          onCreatePoll: _isTeacher ? _showCreatePollDialog : null,
          replyingTo: _replyingTo,
          onCancelReply: () => setState(() => _replyingTo = null),
          editingMessage: _editingMessage,
          onCancelEditing: () => setState(() => _editingMessage = null),
          pendingAttachment: _pendingAttachment,
          onCancelAttachment: () => setState(() => _pendingAttachment = null),
          isUploading: _uploading,
          className: _roomName ?? '',
          onTypingChanged: (typing) =>
              _chatController?.setTypingStatus(widget.repository.uid!, typing),
          onAudioSend: _handleAudioSend,
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: Builder(
          builder: (context) {
            return ChatHeader(
              classId: widget.classId,
              repository: widget.repository,
              chatController: _chatController!,
              searchController: _searchController,
              onSearchChanged: (v) => _chatController?.setSearchQuery(v),
              showResourceSidebar: isMobile
                  ? (_scaffoldKey.currentState?.isEndDrawerOpen ?? false)
                  : _showResourceSidebar,
              onToggleResources: () {
                if (isMobile) {
                  if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _sidebarInitialTab = 0);
                    _scaffoldKey.currentState?.openEndDrawer();
                  }
                } else {
                  setState(() {
                    if (_showResourceSidebar && _sidebarInitialTab == 3) {
                      _sidebarInitialTab = 0;
                    } else {
                      _showResourceSidebar = !_showResourceSidebar;
                      if (_showResourceSidebar) _sidebarInitialTab = 0;
                    }
                  });
                }
              },
              onToggleTopics: () {
                if (isMobile) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() {
                    _showTopicsSidebar = !_showTopicsSidebar;
                  });
                }
              },
              showTopicsSidebar: isMobile
                  ? (_scaffoldKey.currentState?.isDrawerOpen ?? false)
                  : _showTopicsSidebar,
              onBack: widget.onBack,
              onOpenMembers: () {
                setState(() {
                  _showResourceSidebar = true;
                  _sidebarInitialTab =
                      3; // Use 3 as index for members if we decide to keep it in tabs, or handle it in Sidebar
                });
                if (isMobile) {
                  _scaffoldKey.currentState?.openEndDrawer();
                }
              },
            );
          },
        ),
      ),
      drawer: isMobile
          ? Drawer(
              width: 300,
              child: TopicSidebar(
                chatController: _chatController!,
                isTeacher: _isTeacher,
                currentUserId: widget.repository.uid ?? '',
                onTopicChanged: (tid) {
                  _persistChatContext();
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            )
          : null,
      endDrawer: isMobile
          ? Drawer(
              width: screenWidth * 0.85,
              child: ChatResourceSidebar(
                roomId: _roomId!,
                repository: widget.repository,
                chatController: _chatController!,
                onClose: () => Navigator.pop(context),
                initialTab: _sidebarInitialTab == 3 ? 0 : _sidebarInitialTab,
                showMembersOnly: _sidebarInitialTab == 3,
              ),
            )
          : null,
      body: Column(
        children: [
          _ConnectivityBanner(),
          PinnedBanner(
            classId: widget.classId,
            repository: widget.repository,
            chatController: _chatController!,
          ),
          Expanded(
            child: Row(
              children: [
                if (_showTopicsSidebar && !isMobile)
                  SizedBox(
                    width: 280,
                    child: TopicSidebar(
                      chatController: _chatController!,
                      isTeacher: _isTeacher,
                      currentUserId: widget.repository.uid ?? '',
                      onTopicChanged: (tid) {
                        _persistChatContext();
                        setState(() {});
                      },
                    ),
                  ),
                Expanded(child: chatContent),
                if (_showResourceSidebar && !isMobile)
                  SizedBox(
                    width: 380,
                    child: ChatResourceSidebar(
                      roomId: _roomId!,
                      repository: widget.repository,
                      chatController: _chatController!,
                      onClose: () =>
                          setState(() => _showResourceSidebar = false),
                      initialTab: _sidebarInitialTab == 3
                          ? 0
                          : _sidebarInitialTab,
                      showMembersOnly: _sidebarInitialTab == 3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectivityBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    return connectivity.maybeWhen(
      data: (res) => res.contains(ConnectivityResult.none)
          ? Container(
              color: Colors.orange.shade700,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Нет подключения',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _SearchResultsPanel extends StatelessWidget {
  const _SearchResultsPanel({
    required this.chatController,
    required this.resolveUserName,
  });
  final FirebaseChatController chatController;
  final String Function(String) resolveUserName;

  @override
  Widget build(BuildContext context) {
    final results = chatController.searchResults;
    final currentIndex = chatController.searchIndex;
    if (chatController.searchQuery.isEmpty || results.isEmpty)
      return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, listIndex) {
          // results[0] = oldest, results[length-1] = newest → display newest first
          final controllerIndex = results.length - 1 - listIndex;
          final msgId = results[controllerIndex];
          final msg = chatController.getMessageById(msgId);
          if (msg == null) return const SizedBox.shrink();

          final isSelected = currentIndex == controllerIndex;
          final authorName = resolveUserName(msg.authorId);
          final String snippet;
          if (msg is TextMessage) {
            snippet = msg.text;
          } else if (msg is ImageMessage) {
            snippet = '📷 Изображение';
          } else {
            snippet = '📎 Файл';
          }
          final date = msg.createdAt != null
              ? DateFormat(
                  'd MMM, HH:mm',
                  'ru',
                ).format(msg.createdAt!.toLocal())
              : '';

          return InkWell(
            onTap: () => chatController.jumpToSearchIndex(controllerIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withOpacity(0.35)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        authorName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
