import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/l10n/app_localizations.dart';
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
    } else {
      _selectedClassId = widget.initialClassId ?? widget.classes.first['id'] as String?;
      _view = ChatView.chatRoom;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.desktopMode) {
      return Container(
        color: isDark ? const Color(0xFF0F172A) : Theme.of(context).colorScheme.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 280,
              child: _ChatClassList(
                classes: widget.classes,
                onSelect: _onClassSelect,
                repository: widget.repository,
                appState: widget.appState,
                isSplitView: true,
                selectedClassId: _selectedClassId,
              ),
            ),
            Expanded(
              child: _buildDesktopChat(),
            ),
          ],
        ),
      );
    }

    // Mobile logic
    switch (_view) {
      case ChatView.classList:
        return _ChatClassList(
          classes: widget.classes,
          onSelect: _onClassSelect,
          repository: widget.repository,
          appState: widget.appState,
        );
      case ChatView.chatRoom:
        return _buildDesktopChat(mobileBack: () {
          widget.appState.clearChatContext();
          setState(() => _view = ChatView.classList);
        });
    }
  }

  Widget _buildDesktopChat({VoidCallback? mobileBack}) {
    if (widget.classes.isEmpty) return const SizedBox.shrink();
    final classId =
        _selectedClassId ?? widget.initialClassId ?? widget.classes.first['id'] as String;
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B).withValues(alpha: 0.6) 
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: widget.desktopMode 
            ? const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24))
            : BorderRadius.zero,
      ),
      clipBehavior: Clip.antiAlias,
      child: ClassChatScreen(
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
        onBack: mobileBack,
      ),
    );
  }
}

class _ChatClassList extends StatefulWidget {
  const _ChatClassList({
    required this.classes,
    required this.onSelect,
    required this.repository,
    required this.appState,
    this.isSplitView = false,
    this.selectedClassId,
  });

  final List<Map<String, dynamic>> classes;
  final ValueChanged<String> onSelect;
  final SchoolRepository repository;
  final SchoolAppState appState;
  final bool isSplitView;
  final String? selectedClassId;

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

    final filteredChannels = classesList.where((c) {
      final name = c['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockDirectMessages = [
      ('David Kim', true),
      ('Aisha Khan', false),
      ('Michael Chen', false),
      ('Sarah Johnson', true),
    ];

    Widget content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'ELITE DIGITAL CAMPUS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.2,
                color: isDark ? Colors.white : SchoolColors.text,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : SchoolColors.text),
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildSectionTitle('CHANNELS', isDark),
                if (filteredChannels.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No channels found', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  )
                else
                  ...filteredChannels.map((c) => _SidebarItem(
                        icon: Icons.tag_rounded,
                        label: c['name']?.toString() ?? '',
                        color: parseHexColor(c['coverColor']),
                        isSelected: widget.selectedClassId == c['id'],
                        onTap: () => widget.onSelect(c['id'] as String),
                        isDark: isDark,
                      )),
                const SizedBox(height: 24),
                _buildSectionTitle('DIRECT MESSAGES', isDark),
                ...mockDirectMessages.map((m) => _SidebarItem(
                      icon: Icons.person_rounded,
                      label: m.$1,
                      color: m.$2 ? SchoolColors.green : (isDark ? Colors.white54 : Colors.black54),
                      isSelected: false,
                      onTap: () {},
                      isDark: isDark,
                      isOnline: m.$2,
                    )),
              ],
            ),
          ),
        ],
      ),
    );

    return widget.isSplitView
        ? content
        : Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Theme.of(context).colorScheme.surface,
            body: content,
          );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white54 : Colors.black54,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.isOnline = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool isOnline;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.15)
                : (_hovered
                    ? (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isSelected ? widget.color : (widget.isDark ? Colors.white70 : Colors.black87),
                  ),
                  if (widget.isOnline)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: SchoolColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.isDark ? const Color(0xFF0F172A) : Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isSelected
                        ? (widget.isDark ? Colors.white : Colors.black)
                        : (widget.isDark ? Colors.white70 : Colors.black87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
