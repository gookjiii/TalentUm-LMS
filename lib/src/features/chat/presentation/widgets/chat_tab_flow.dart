import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    required this.desktopMode,
    required this.canInitializeRoom,
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
    final selectedClassStillExists =
        _selectedClassId != null &&
        widget.classes.any((c) => c['id'] == _selectedClassId);
    if (oldWidget.classes.length != widget.classes.length ||
        !selectedClassStillExists) {
      _syncInitialView();
    }
  }

  void _syncInitialView() {
    final restoredClassId = widget.appState.lastChatClassId;
    final restoredClassExists =
        restoredClassId != null &&
        widget.classes.any((c) => c['id'] == restoredClassId);

    if (restoredClassExists) {
      _selectedClassId = restoredClassId;
      _view = ChatView.chatRoom;
      return;
    }

    if (widget.classes.isEmpty) {
      _selectedClassId = null;
      _view = ChatView.classList;
      return;
    }

    if (widget.classes.length == 1) {
      _selectedClassId = widget.classes.first['id'] as String?;
      _view = ChatView.chatRoom;
      return;
    }

    _selectedClassId = null;
    _view = ChatView.classList;
  }

  void _onClassSelect(String classId) {
    widget.appState.selectClass(classId);
    widget.appState.saveChatContext(classId: classId, topicId: null);
    setState(() {
      _selectedClassId = classId;
      _view = ChatView.chatRoom;
    });
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
          preloadedController: (roomId != null && roomId.isNotEmpty)
              ? ref.watch(preloadedChatControllerProvider(roomId))
              : null,
          onBack: widget.classes.length > 1 || _selectedClassId == 'teachers_lounge'
              ? () => setState(() => _view = ChatView.classList)
              : null,
        );
    }
  }

  Widget _buildDesktopChat() {
    if (widget.classes.isEmpty) return const SizedBox.shrink();
    final classId =
        widget.initialClassId ?? widget.classes.first['id'] as String;
    final classData = widget.classes.firstWhere(
      (c) => c['id'] == classId,
      orElse: () => widget.classes.first,
    );
    final roomId = classData['chatRoomId'] as String?;

    return ClassChatScreen(
      key: ValueKey('chat-$classId'),
      repository: widget.repository,
      appState: widget.appState,
      classId: classId,
      canInitializeRoom: widget.canInitializeRoom,
      preloadedController: (roomId != null && roomId.isNotEmpty)
          ? ref.watch(preloadedChatControllerProvider(roomId))
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
      final matchesSearch = AppLocalizations.of(context)!.teachersRoom1.contains(_searchQuery.toLowerCase());
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
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Aurora Animated Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF0F172A), Color(0xFF1E1E38)]
                      : const [Color(0xFFF8FAFC), Color(0xFFEDF2F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1F2563EB), Color(0x002563EB)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1F7C3AED), Color(0x007C3AED)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchChats,
                        hintStyle: const TextStyle(color: SchoolColors.muted),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: SchoolColors.muted,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),

                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: SchoolColors.border,
                              ),
                              SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context)!.noChatsFound,
                                style: TextStyle(
                                  color: SchoolColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            return _ClassCard(
                              c: c,
                              repository: widget.repository,
                              onTap: () => widget.onSelect(c['id'] as String),
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

class _ClassCard extends StatefulWidget {
  const _ClassCard({
    required this.c,
    required this.repository,
    required this.onTap,
  });

  final Map<String, dynamic> c;
  final SchoolRepository repository;
  final VoidCallback onTap;

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _hovered = false;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _lastMessageStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _allMessagesStream;

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

      _allMessagesStream = widget.repository.firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .snapshots();
    } else {
      _lastMessageStream = null;
      _allMessagesStream = null;
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
          final userIds = List<String>.from(snap.data?.data()?['userIds'] ?? []);
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 11,
            color: color,
          ),
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
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: _hovered ? 0.45 : 0.35)
                  : Colors.white.withValues(alpha: _hovered ? 0.75 : 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: _hovered ? 0.15 : 0.08,
                ),
                width: 1.2,
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
                  ),
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
                          const SizedBox(width: 8),
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
                                AppLocalizations.of(context)!.errorLoadingMessage,
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
                            if (type == 'image')
                              displaySnippet = AppLocalizations.of(context)!.photography;
                            else if (type == 'video')
                              displaySnippet = AppLocalizations.of(context)!.video;
                            else if (type == 'file')
                              displaySnippet = AppLocalizations.of(context)!.file1;
                            else if (type == 'audio')
                              displaySnippet = AppLocalizations.of(context)!.voiceMessage1;

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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (roomId != null && roomId.isNotEmpty)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _lastMessageStream,
                        builder: (context, msgSnap) {
                          final docs = msgSnap.data?.docs ?? [];
                          if (docs.isEmpty) return const SizedBox.shrink();
                          final data = docs.first.data();
                          final time = (data['createdAt'] as Timestamp?)
                              ?.toDate();
                          if (time == null) return const SizedBox.shrink();
                          final timeStr = DateFormat('HH:mm').format(time);
                          return Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: SchoolColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 6),
                    if (roomId != null && roomId.isNotEmpty)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _allMessagesStream,
                        builder: (context, unreadSnap) {
                          final docs = unreadSnap.data?.docs ?? [];
                          final uid = widget.repository.uid ?? '';
                          final count = docs.where((doc) {
                            final seenBy = List<String>.from(
                              doc.data()['metadata']?['seenBy'] ?? [],
                            );
                            return !seenBy.contains(uid) &&
                                doc.data()['authorId'] != uid;
                          }).length;

                          if (count == 0)
                            return const SizedBox(width: 24, height: 24);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SchoolColors.red,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: SchoolColors.red.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
