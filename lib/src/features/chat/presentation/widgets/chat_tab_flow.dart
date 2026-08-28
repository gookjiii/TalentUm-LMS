import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/app_state.dart';
import 'package:school_world/src/features/chat/presentation/screens/class_chat_screen.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

enum ChatView { classList, chatRoom }

class ChatTabFlow extends ConsumerStatefulWidget {
  const ChatTabFlow({
    super.key,
    required this.repository,
    required this.appState,
    required this.classes,
    this.desktopMode = false,
    this.canInitializeRoom = false,
    this.initialClassId,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;
  final List<Map<String, dynamic>> classes;
  final bool desktopMode;
  final bool canInitializeRoom;
  final String? initialClassId;

  @override
  ConsumerState<ChatTabFlow> createState() => _ChatTabFlowState();
}

class _ChatTabFlowState extends ConsumerState<ChatTabFlow> {
  ChatView _view = ChatView.classList;
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _syncInitialView();
  }

  @override
  void didUpdateWidget(covariant ChatTabFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.desktopMode != widget.desktopMode) {
      if (!widget.desktopMode) {
        widget.appState.setChatRoomMobileOpen(_view == ChatView.chatRoom);
      } else {
        widget.appState.setChatRoomMobileOpen(false);
      }
    }
    if (oldWidget.initialClassId != widget.initialClassId && widget.initialClassId != null) {
      _syncInitialView();
      return;
    }
    final selectedClassStillExists =
        _selectedClassId != null &&
        (_selectedClassId == 'teachers_lounge' ||
            widget.classes.any((c) => c['id'] == _selectedClassId));
    if (oldWidget.classes.length != widget.classes.length ||
        !selectedClassStillExists) {
      _syncInitialView();
    }
  }

  void _syncInitialView() {
    if (widget.initialClassId != null &&
        (widget.initialClassId == 'teachers_lounge' ||
            widget.classes.any((c) => c['id'] == widget.initialClassId))) {
      _selectedClassId = widget.initialClassId;
      _view = ChatView.chatRoom;
    } else {
      final restoredClassId = widget.appState.lastChatClassId;
      final restoredClassExists =
          restoredClassId != null &&
          (restoredClassId == 'teachers_lounge' ||
              widget.classes.any((c) => c['id'] == restoredClassId));

      if (restoredClassExists) {
        _selectedClassId = restoredClassId;
        _view = ChatView.chatRoom;
      } else if (widget.appState.isTeacher) {
        _selectedClassId = null;
        _view = ChatView.classList;
      } else if (widget.classes.isEmpty) {
        _selectedClassId = null;
        _view = ChatView.classList;
      } else if (widget.classes.length == 1) {
        _selectedClassId = widget.classes.first['id'] as String?;
        _view = ChatView.chatRoom;
      } else {
        _selectedClassId = null;
        _view = ChatView.classList;
      }
    }
    if (!widget.desktopMode) {
      widget.appState.setChatRoomMobileOpen(_view == ChatView.chatRoom);
    }
  }

  void _onClassSelect(String classId) {
    widget.appState.selectClass(classId);
    widget.appState.saveChatContext(classId: classId, topicId: null);
    setState(() {
      _selectedClassId = classId;
      _view = ChatView.chatRoom;
    });
    if (!widget.desktopMode) {
      widget.appState.setChatRoomMobileOpen(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.desktopMode) {
      return _buildDesktopChat();
    }

    switch (_view) {
      case ChatView.classList:
        return _ChatClassList(
          classes: widget.classes,
          onSelect: _onClassSelect,
          repository: widget.repository,
          appState: widget.appState,
        );
      case ChatView.chatRoom:
        final classData = widget.classes.firstWhere(
          (c) => c['id'] == _selectedClassId,
          orElse: () => {
            'id': 'teachers_lounge',
            'name': AppLocalizations.of(context)!.teachersRoom,
            'chatRoomId': 'global_teachers_lounge',
            'coverColor': '#FF4F46E5',
            'isTeachersLounge': true,
          },
        );
        final roomId = classData['chatRoomId'] as String?;
        return ClassChatScreen(
          key: ValueKey('chat-$_selectedClassId'),
          repository: widget.repository,
          appState: widget.appState,
          classId: _selectedClassId!,
          canInitializeRoom: widget.canInitializeRoom,
          initialTopicId: widget.appState.lastChatClassId == _selectedClassId
              ? widget.appState.lastChatTopicId
              : null,
          preloadedController: (roomId != null && roomId.isNotEmpty)
              ? ref.watch(preloadedChatControllerProvider(roomId).notifier)
              : null,
          // Chat rooms are embedded in the shell rather than pushed as a
          // route. Always handle the header back button here so a single-class
          // student can leave the room as well.
          onBack: () {
            widget.appState.clearChatContext();
            if (!widget.desktopMode) {
              widget.appState.setChatRoomMobileOpen(false);
            }
            if (mounted) {
              setState(() => _view = ChatView.classList);
            }
          },
        );
    }
  }

  Widget _buildDesktopChat() {
    if (widget.classes.isEmpty && !widget.appState.isTeacher) {
      return const SizedBox.shrink();
    }
    final classId = widget.initialClassId ??
        (widget.classes.isNotEmpty
            ? widget.classes.first['id'] as String
            : 'teachers_lounge');
    final classData = widget.classes.firstWhere(
      (c) => c['id'] == classId,
      orElse: () => {
        'id': 'teachers_lounge',
        'name': AppLocalizations.of(context)!.teachersRoom,
        'chatRoomId': 'global_teachers_lounge',
        'coverColor': '#FF4F46E5',
        'isTeachersLounge': true,
      },
    );
    final roomId = classData['chatRoomId'] as String?;

    return ClassChatScreen(
      key: ValueKey('chat-$classId'),
      repository: widget.repository,
      appState: widget.appState,
      classId: classId,
      canInitializeRoom: widget.canInitializeRoom,
      initialTopicId: widget.appState.lastChatClassId == classId
          ? widget.appState.lastChatTopicId
          : null,
      preloadedController: (roomId != null && roomId.isNotEmpty)
          ? ref.watch(preloadedChatControllerProvider(roomId).notifier)
          : null,
    );
  }
}

class _ChatClassList extends StatefulWidget {
  const _ChatClassList({
    required this.classes,
    required this.onSelect,
    required this.repository,
    required this.appState,
  });

  final List<Map<String, dynamic>> classes;
  final ValueChanged<String> onSelect;
  final SchoolRepository repository;
  final SchoolAppState appState;

  @override
  State<_ChatClassList> createState() => _ChatClassListState();
}

class _ChatClassListState extends State<_ChatClassList> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesList = List<Map<String, dynamic>>.from(widget.classes);
    if (widget.appState.isTeacher) {
      final matchesSearch = AppLocalizations.of(
        context,
      )!.teachersRoom1.contains(_searchQuery.toLowerCase());
      if (matchesSearch) {
        classesList.insert(0, {
          'id': 'teachers_lounge',
          'name': AppLocalizations.of(context)!.teachersRoom,
          'chatRoomId': 'global_teachers_lounge',
          'coverColor': '#FF4F46E5',
          'isTeachersLounge': true,
        });
      }
    }

    final filtered = classesList.where((c) {
      final name = c['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppLocalizations.of(context)!.chats,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Positioned.fill(
            child: Container(color: Theme.of(context).colorScheme.surface),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Hero(
                    tag: 'chat_search',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchChats,
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3),
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: AppLocalizations.of(context)!.noChatsFound,
                          subtitle: AppLocalizations.of(context)!.tryAgain,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ClassCard(
                                c: c,
                                repository: widget.repository,
                                onTap: () => widget.onSelect(c['id'] as String),
                              ),
                            );
                          },
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

class _ClassCard extends ConsumerStatefulWidget {
  const _ClassCard({
    required this.c,
    required this.repository,
    required this.onTap,
  });

  final Map<String, dynamic> c;
  final SchoolRepository repository;
  final VoidCallback onTap;

  @override
  ConsumerState<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends ConsumerState<_ClassCard> {
  bool _hovered = false;
  bool _pressed = false;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _lastMessageStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(covariant _ClassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.c['chatRoomId'] != widget.c['chatRoomId']) {
      _initStreams();
    }
  }

  void _initStreams() {
    final roomId = widget.c['chatRoomId'] as String?;
    if (roomId != null && roomId.isNotEmpty) {
      _lastMessageStream = widget.repository.firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots();
    } else {
      _lastMessageStream = null;
    }
  }

  Widget _buildParticipantCount(Map<String, dynamic> c, Color color) {
    if (c['isTeachersLounge'] == true) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: widget.repository.firestore
            .collection('rooms')
            .doc('global_teachers_lounge')
            .snapshots(),
        builder: (context, snap) {
          final userIds = List<String>.from(
            snap.data?.data()?['userIds'] ?? [],
          );
          return _buildParticipantBadge(userIds.length, color);
        },
      );
    } else {
      final studentIds = List<String>.from(c['studentIds'] ?? []);
      final teacherId = c['teacherId'] as String?;
      final count = (teacherId != null ? 1 : 0) + studentIds.length;
      return _buildParticipantBadge(count, color);
    }
  }

  Widget _buildParticipantBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final color = parseHexColor(c['coverColor']);
    final roomId = c['chatRoomId'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: _hovered ? 0.45 : 0.35)
                  : Colors.white.withValues(alpha: _hovered ? 0.75 : 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: _hovered ? 0.15 : 0.08,
                ),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: _hovered ? 0.18 : 0.06),
                  blurRadius: _hovered ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClassBadge(
                        name: c['name'] ?? '?',
                        color: color,
                        size: 52,
                        radius: 14,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final cardRoomId = (c['chatRoomId'] as String?) ?? (c['id'] as String? ?? '');
                        final hasUnread = cardRoomId.isNotEmpty
                            ? (ref.watch(roomUnreadProvider(cardRoomId)).value ?? false)
                            : false;
                        if (!hasUnread) return const SizedBox.shrink();
                        return Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: SchoolColors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: SchoolColors.red.withValues(alpha: 0.9),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final cardRoomId = (c['chatRoomId'] as String?) ?? (c['id'] as String? ?? '');
                              final hasUnread = ref.watch(roomUnreadProvider(cardRoomId)).value ?? false;
                              if (!hasUnread) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: SchoolColors.red,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SchoolColors.red.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          _buildParticipantCount(c, color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (roomId != null && roomId.isNotEmpty)
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _lastMessageStream,
                          builder: (context, msgSnap) {
                            if (msgSnap.hasError) {
                              return Text(
                                AppLocalizations.of(
                                  context,
                                )!.errorLoadingMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SchoolColors.red,
                                ),
                              );
                            }
                            final docs = msgSnap.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return Text(
                                AppLocalizations.of(context)!.noMessagesYet1,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SchoolColors.muted,
                                ),
                              );
                            }
                            final data = docs.first.data();
                            final text = data['text'] as String? ?? '';
                            final authorName =
                                data['authorName'] as String? ?? '';
                            final type = data['type'] as String? ?? 'text';

                            String displaySnippet = text;
                            if (type == 'image') {
                              displaySnippet = AppLocalizations.of(
                                context,
                              )!.photography;
                            } else if (type == 'video') {
                              displaySnippet = AppLocalizations.of(
                                context,
                              )!.video;
                            } else if (type == 'file') {
                              displaySnippet = AppLocalizations.of(
                                context,
                              )!.file1;
                            } else if (type == 'audio') {
                              displaySnippet = AppLocalizations.of(
                                context,
                              )!.voiceMessage1;
                            }

                            final display = authorName.isNotEmpty
                                ? '$authorName: $displaySnippet'
                                : displaySnippet;

                            return Text(
                              display,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        )
                      else
                        Text(
                          AppLocalizations.of(context)!.clickToOpenChat,
                          style: TextStyle(
                            fontSize: 13,
                            color: SchoolColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
