import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_world/main.dart';

class ChatHeader extends StatefulWidget {
  const ChatHeader({
    super.key,
    required this.classId,
    required this.repository,
    required this.chatController,
    required this.searchController,
    required this.onSearchChanged,
    required this.showResourceSidebar,
    required this.onToggleResources,
    required this.onToggleTopics,
    required this.showTopicsSidebar,
    this.onBack,
    this.onOpenMembers,
  });

  final String classId;
  final SchoolRepository repository;
  final FirebaseChatController chatController;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool showResourceSidebar;
  final VoidCallback onToggleResources;
  final VoidCallback onToggleTopics;
  final bool showTopicsSidebar;
  final VoidCallback? onBack;
  final VoidCallback? onOpenMembers;

  @override
  State<ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<ChatHeader> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;
  bool _isMobileSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    final doc = await widget.repository.firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant ChatHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _isMobileSearching = false;
      _initStream();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initStream() {
    if (widget.classId == 'teachers_lounge') {
      _stream = widget.repository.firestore
          .collection('rooms')
          .doc('global_teachers_lounge')
          .snapshots();
    } else {
      _stream = widget.repository.firestore
          .collection('classes')
          .doc(widget.classId)
          .snapshots();
    }
  }

  Future<void> _openCallRoom(String classId) async {
    final url = Uri.parse('https://meet.jit.si/school_world_$classId');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToOpenCallRoom)),
        );
      }
    }
  }

  Future<void> _clearTeachersLoungeChat() async {
    // Delay to prevent !_debugDuringDeviceUpdate assertion on Flutter Web 
    // when triggered from a PopupMenu or replacing dialogs rapidly
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.clearChat1,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : SchoolColors.darkSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  AppLocalizations.of(context)!.areYouSureYouWant1,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 24, bottom: 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.unknownKey, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.clear),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Delay again before showing the next dialog to prevent mouse tracker crash
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(SchoolColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.clearingChat,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final messagesSnapshot = await widget.repository.firestore
          .collection('rooms')
          .doc('global_teachers_lounge')
          .collection('messages')
          .get();
          
      final batch = widget.repository.firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.teachersChatHasBeenSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;
    final isSearching = widget.chatController.searchQuery.isNotEmpty || _isMobileSearching;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data == null) return const SizedBox.shrink();

        final String name;
        final Color color;
        final int memberCount;

        if (widget.classId == 'teachers_lounge') {
          name = data['name']?.toString() ?? AppLocalizations.of(context)!.teachersRoom;
          color = SchoolColors.primary;
          final userIds = List<String>.from(data['userIds'] ?? []);
          memberCount = userIds.length;
        } else {
          name = data['name']?.toString() ?? AppLocalizations.of(context)!.classText;
          color = parseHexColor(data['coverColor']);
          final studentIds = List<String>.from(data['studentIds'] ?? []);
          final teacherId = data['teacherId'] as String?;
          final allIds = [if (teacherId != null) teacherId, ...studentIds];
          memberCount = allIds.length;
        }

        final statusText = '$memberCount участников, онлайн';

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 16,
            vertical: isMobile ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              if (isMobile) {
                return Row(
                  children: [
                    if (!isSearching) ...[
                      Semantics(
                        label: AppLocalizations.of(context)!.back,
                        button: true,
                        child: IconButton(
                          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        label: AppLocalizations.of(context)!.chatTopics,
                        button: true,
                        child: IconButton(
                          onPressed: widget.onToggleTopics,
                          icon: const Icon(Icons.topic_outlined, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: widget.showTopicsSidebar
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                            foregroundColor: widget.showTopicsSidebar
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Expanded(
                      child: isSearching
                          ? SearchBar(
                              controller: widget.searchController,
                              onChanged: widget.onSearchChanged,
                              hintText: AppLocalizations.of(context)!.search,
                              focusNode: _searchFocusNode,
                              elevation: const WidgetStatePropertyAll(0),
                              backgroundColor: WidgetStatePropertyAll(
                                theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              ),
                              leading: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                                color: theme.colorScheme.primary,
                                onPressed: () {
                                  setState(() {
                                    _isMobileSearching = false;
                                  });
                                  widget.searchController.clear();
                                  widget.onSearchChanged('');
                                  widget.chatController.setSearchQuery('');
                                },
                              ),
                              trailing: [
                                if (isSearching)
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _isMobileSearching = false;
                                      });
                                      widget.searchController.clear();
                                      widget.onSearchChanged('');
                                      widget.chatController.setSearchQuery('');
                                    },
                                  ),
                              ],
                            )
                          : GestureDetector(
                              onTap: widget.onOpenMembers,
                              child: Semantics(
                                label: AppLocalizations.of(context)!.chatInformation,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClassBadge(name: name, color: color, size: 18, radius: 4),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            statusText,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.primary.withOpacity(0.8),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    if (!isSearching) ...[
                      const SizedBox(width: 4),
                      Semantics(
                        label: AppLocalizations.of(context)!.call,
                        button: true,
                        child: IconButton(
                          onPressed: () => _openCallRoom(widget.classId),
                          icon: const Icon(Icons.video_call_rounded, size: 22),
                          color: theme.colorScheme.primary,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        constraints: const BoxConstraints(minWidth: 150),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'search':
                              setState(() {
                                _isMobileSearching = true;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _searchFocusNode.requestFocus();
                              });
                              break;
                            case 'members':
                              if (widget.onOpenMembers != null) {
                                widget.onOpenMembers!();
                              }
                              break;
                            case 'resources':
                              widget.onToggleResources();
                              break;
                            case 'clear':
                              _clearTeachersLoungeChat();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'search',
                            child: Row(
                              children: [
                                Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.of(context)!.searchMessages),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'members',
                            child: Row(
                              children: [
                                Icon(Icons.group_rounded, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.of(context)!.participants),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'resources',
                            child: Row(
                              children: [
                                Icon(
                                  widget.showResourceSidebar
                                      ? Icons.info_rounded
                                      : Icons.info_outline_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.of(context)!.mediaAndFiles),
                              ],
                            ),
                          ),
                          if (widget.classId == 'teachers_lounge' && AppScope.of(context).appState.isLeadTeacher)
                            PopupMenuItem(
                              value: 'clear',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_sweep_rounded,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(context)!.clearChat1,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Semantics(
                    label: AppLocalizations.of(context)!.chatTopics,
                    button: true,
                    child: IconButton.filledTonal(
                      tooltip: AppLocalizations.of(context)!.chatTopics,
                      onPressed: widget.onToggleTopics,
                      icon: Icon(
                        widget.showTopicsSidebar ? Icons.topic : Icons.topic_outlined,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.showTopicsSidebar
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                        foregroundColor: widget.showTopicsSidebar
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onOpenMembers,
                    child: ClassBadge(name: name, color: color, size: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: AppLocalizations.of(context)!.chatInformation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            statusText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SearchBar(
                      controller: widget.searchController,
                      onChanged: widget.onSearchChanged,
                      hintText: AppLocalizations.of(context)!.searchMessages1,
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStatePropertyAll(
                        theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                      leading: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      trailing: [
                        if (isSearching)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              widget.searchController.clear();
                              widget.onSearchChanged('');
                              widget.chatController.setSearchQuery('');
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: AppLocalizations.of(context)!.call,
                    button: true,
                    child: IconButton.filledTonal(
                      tooltip: AppLocalizations.of(context)!.startAVideoCall,
                      onPressed: () => _openCallRoom(widget.classId),
                      icon: const Icon(Icons.video_call_rounded, size: 20),
                      color: theme.colorScheme.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: AppLocalizations.of(context)!.participants,
                    button: true,
                    child: IconButton.filledTonal(
                      tooltip: AppLocalizations.of(context)!.participants,
                      onPressed: widget.onOpenMembers,
                      icon: const Icon(Icons.group_rounded, size: 20),
                      color: theme.colorScheme.onSurfaceVariant,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: AppLocalizations.of(context)!.mediaAndFiles,
                    button: true,
                    child: IconButton.filledTonal(
                      tooltip: AppLocalizations.of(context)!.mediaAndFiles,
                      onPressed: widget.onToggleResources,
                      icon: Icon(
                        widget.showResourceSidebar
                            ? Icons.info_rounded
                            : Icons.info_outline_rounded,
                        size: 20,
                      ),
                      color: widget.showResourceSidebar
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      style: IconButton.styleFrom(
                        backgroundColor: widget.showResourceSidebar
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  if (widget.classId == 'teachers_lounge' && AppScope.of(context).appState.isLeadTeacher) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      label: AppLocalizations.of(context)!.clearChat1,
                      button: true,
                      child: IconButton.filledTonal(
                        tooltip: AppLocalizations.of(context)!.clearTeachersChat,
                        onPressed: _clearTeachersLoungeChat,
                        icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                        color: Colors.redAccent,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showMobileSearch(BuildContext context) {
    // Deprecated in favor of inline SearchBar
  }
}
