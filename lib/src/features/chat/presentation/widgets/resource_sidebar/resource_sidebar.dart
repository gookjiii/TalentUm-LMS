import 'package:school_world/l10n/app_localizations.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/utils/open_external_url.dart';
import 'package:school_world/src/widgets/image_viewer.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/utils/string_extensions.dart';

class ChatResourceSidebar extends StatefulWidget {
  const ChatResourceSidebar({
    super.key,
    required this.roomId,
    required this.repository,
    required this.chatController,
    required this.onClose,
    this.initialTab = 0,
    this.showMembersOnly = false,
  });

  final String roomId;
  final SchoolRepository repository;
  final FirebaseChatController chatController;
  final VoidCallback onClose;
  final int initialTab;
  final bool showMembersOnly;

  @override
  State<ChatResourceSidebar> createState() => _ChatResourceSidebarState();
}

class _ChatResourceSidebarState extends State<ChatResourceSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _showMembers;
  Color _classColor = SchoolColors.primary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _showMembers = widget.showMembersOnly;
    _loadClassColor();
  }

  Future<void> _loadClassColor() async {
    try {
      final roomSnap = await widget.repository.firestore
          .collection('rooms')
          .doc(widget.roomId)
          .get();
      final classId = roomSnap.data()?['classId'] as String? ?? '';
      if (classId.isNotEmpty) {
        final classSnap = await widget.repository.firestore
            .collection('classes')
            .doc(classId)
            .get();
        final coverColorHex = classSnap.data()?['coverColor'] as String? ?? '';
        if (coverColorHex.isNotEmpty) {
          if (mounted) {
            setState(() {
              _classColor = parseHexColor(coverColorHex);
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant ChatResourceSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showMembersOnly != widget.showMembersOnly) {
      setState(() => _showMembers = widget.showMembersOnly);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content;
    if (_showMembers) {
      content = Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _showMembers = false),
                  icon: Icon(Icons.arrow_back_rounded),
                  tooltip: AppLocalizations.of(context)!.toResources,
                ),
                Text(
                  AppLocalizations.of(context)!.participants,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _MembersTabView(
              roomId: widget.roomId,
              repository: widget.repository,
              classColor: _classColor,
            ),
          ),
        ],
      );
    } else {
      content = Column(
        children: [
          _ResourceSidebarHeader(
            onClose: widget.onClose,
            tabController: _tabController,
            classColor: _classColor,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MediaGrid(
                  roomId: widget.roomId,
                  repository: widget.repository,
                  classColor: _classColor,
                ),
                _FilesList(
                  roomId: widget.roomId,
                  repository: widget.repository,
                  classColor: _classColor,
                ),
                _LinksListView(
                  roomId: widget.roomId,
                  repository: widget.repository,
                  classColor: _classColor,
                ),
                _PollsListView(
                  roomId: widget.roomId,
                  repository: widget.repository,
                  classColor: _classColor,
                ),
                _AIAssistantTab(
                  roomId: widget.roomId,
                  repository: widget.repository,
                  classColor: _classColor,
                ),
              ],
            ),
          ),
        ],
      );
    }

    bool isPerformance = false;
    try {
      isPerformance = AppScope.of(context).appState.performanceMode;
    } catch (_) {}

    if (isPerformance) {
      return Material(
        color: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _classColor.withOpacity(0.4),
                width: 2.0,
              ),
            ),
          ),
          child: content,
        ),
      );
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: isDark
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.68),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _classColor.withOpacity(0.25),
                  width: 2.0,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Soft Aurora radial light in background
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _classColor.withOpacity(0.12),
                          _classColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceSidebarHeader extends StatelessWidget {
  const _ResourceSidebarHeader({
    required this.onClose,
    required this.tabController,
    required this.classColor,
  });

  final VoidCallback onClose;
  final TabController tabController;
  final Color classColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.resources,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        TabBar(
          controller: tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: SchoolColors.muted,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          indicator: BoxDecoration(
            color: classColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: classColor.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, size: 16),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.media),
                  ],
                ),
              ),
            ),
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_present_outlined, size: 16),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.files),
                  ],
                ),
              ),
            ),
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_outlined, size: 16),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.links),
                  ],
                ),
              ),
            ),
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.poll_outlined, size: 16),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.polls),
                  ],
                ),
              ),
            ),
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.ai),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaGrid extends StatefulWidget {
  const _MediaGrid({
    required this.roomId,
    required this.repository,
    required this.classColor,
  });

  final String roomId;
  final SchoolRepository repository;
  final Color classColor;

  @override
  State<_MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<_MediaGrid> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _MediaGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _initStream();
    }
  }

  void _initStream() {
    _stream = widget.repository.firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ошибка загрузки медиа: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SchoolColors.red, fontSize: 13),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final type = data['type'] as String? ?? '';
          final meta = data['metadata'] as Map? ?? {};
          final isVideo = type == 'video' || meta['attachmentType'] == 'video';
          return type == 'image' || isVideo;
        }).toList();

        if (docs.isEmpty)
          return _EmptySidebarState(
            icon: Icons.image_outlined,
            label: AppLocalizations.of(context)!.thereWasNoMediaYet,
          );

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final url = data['uri'] as String? ?? '';
            final isVideo =
                data['type'] == 'video' ||
                data['metadata']?['attachmentType'] == 'video';
            return _MediaGridItem(
              url: url,
              isVideo: isVideo,
              classColor: widget.classColor,
            );
          },
        );
      },
    );
  }
}

class _MediaGridItem extends StatefulWidget {
  const _MediaGridItem({
    required this.url,
    required this.isVideo,
    required this.classColor,
  });

  final String url;
  final bool isVideo;
  final Color classColor;

  @override
  State<_MediaGridItem> createState() => _MediaGridItemState();
}

class _MediaGridItemState extends State<_MediaGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.isVideo
            ? openExternalUrl(widget.url)
            : showDialog(
                context: context,
                builder: (_) => ImageViewer(imageUrl: widget.url.toDirectImageUrl),
              ),
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? widget.classColor.withOpacity(0.8)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.classColor.withOpacity(_isHovered ? 0.35 : 0.0),
                  blurRadius: _isHovered ? 10 : 0,
                  spreadRadius: _isHovered ? 1 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.url.toDirectImageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 200,
                    memCacheHeight: 200,
                    placeholder: (context, url) => Container(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: SchoolColors.surface,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 16,
                        color: SchoolColors.muted,
                      ),
                    ),
                  ),
                  if (widget.isVideo)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: _isHovered
                        ? Colors.black.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilesList extends StatefulWidget {
  const _FilesList({
    required this.roomId,
    required this.repository,
    required this.classColor,
  });

  final String roomId;
  final SchoolRepository repository;
  final Color classColor;

  @override
  State<_FilesList> createState() => _FilesListState();
}

class _FilesListState extends State<_FilesList> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _FilesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _initStream();
    }
  }

  void _initStream() {
    _stream = widget.repository.firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ошибка загрузки файлов: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SchoolColors.red, fontSize: 13),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final type = data['type'] as String? ?? '';
          return type == 'file';
        }).toList();

        if (docs.isEmpty)
          return _EmptySidebarState(
            icon: Icons.file_present_outlined,
            label: AppLocalizations.of(context)!.thereAreNoFilesYet,
          );

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final name =
                data['name']?.toString() ??
                data['metadata']?['fileName']?.toString() ??
                AppLocalizations.of(context)!.file2;
            final url = data['uri'] as String? ?? '';
            final size =
                (data['size'] as num?)?.toInt() ??
                (data['metadata']?['fileSize'] as num?)?.toInt() ??
                0;

            return _FileCardItem(
              name: name,
              url: url,
              size: size,
              classColor: widget.classColor,
            );
          },
        );
      },
    );
  }
}

class _FileCardItem extends StatefulWidget {
  const _FileCardItem({
    required this.name,
    required this.url,
    required this.size,
    required this.classColor,
  });

  final String name;
  final String url;
  final int size;
  final Color classColor;

  @override
  State<_FileCardItem> createState() => _FileCardItemState();
}

class _FileCardItemState extends State<_FileCardItem> {
  bool _isHovered = false;

  String get _extension {
    if (widget.name.contains('.')) {
      return widget.name.substring(widget.name.lastIndexOf('.') + 1);
    }
    return '';
  }

  bool get _isImage {
    final ext = _extension.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext);
  }

  bool get _isPdf => _extension.toLowerCase() == 'pdf';
  bool get _isWord => ['doc', 'docx'].contains(_extension.toLowerCase());

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (bytes.toDouble() <= 0)
        ? 0
        : (bytes.toDouble() / 1024).floor().clamp(0, suffixes.length - 1);
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final extensionLabel = _extension.toUpperCase();

    Color fileColor = widget.classColor;
    if (_isPdf) {
      fileColor = SchoolColors.red;
    } else if (_isWord) {
      fileColor = const Color(0xFF2563EB);
    } else if (_isImage) {
      fileColor = SchoolColors.green;
    }

    Widget thumbnail;
    if (_isImage && widget.url.isNotEmpty) {
      thumbnail = CachedNetworkImage(
        imageUrl: widget.url.toDirectImageUrl,
        fit: BoxFit.cover,
        width: 48,
        height: 48,
        memCacheWidth: 120,
        memCacheHeight: 120,
        placeholder: (_, __) => Container(color: Colors.grey.withOpacity(0.1)),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey.withOpacity(0.1),
          child: const Icon(
            Icons.broken_image_outlined,
            size: 16,
            color: SchoolColors.muted,
          ),
        ),
      );
    } else {
      thumbnail = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: fileColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fileColor.withOpacity(0.24)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPdf
                    ? Icons.picture_as_pdf_rounded
                    : _isWord
                    ? Icons.description_rounded
                    : Icons.insert_drive_file_rounded,
                color: fileColor,
                size: 20,
              ),
              if (extensionLabel.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  extensionLabel.substring(
                    0,
                    math.min(extensionLabel.length, 4),
                  ),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: fileColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(_isHovered ? 0.06 : 0.03)
                : Colors.black.withOpacity(_isHovered ? 0.04 : 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.classColor.withOpacity(0.4)
                  : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06)),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.classColor.withOpacity(_isHovered ? 0.12 : 0.0),
                blurRadius: _isHovered ? 8 : 0,
                offset: _isHovered ? const Offset(0, 4) : Offset.zero,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (_isImage && widget.url.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => ImageViewer(imageUrl: widget.url.toDirectImageUrl),
                  );
                } else if (widget.url.isNotEmpty) {
                  openExternalUrl(widget.url);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: thumbnail,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                _formatBytes(widget.size),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SchoolColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.url.isNotEmpty) ...[
                                SizedBox(width: 6),
                                CircleAvatar(
                                  radius: 2,
                                  backgroundColor: SchoolColors.muted,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _isImage ? AppLocalizations.of(context)!.view : AppLocalizations.of(context)!.open,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: fileColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isImage
                          ? Icons.visibility_rounded
                          : Icons.open_in_new_rounded,
                      color: fileColor.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinksListView extends StatefulWidget {
  const _LinksListView({
    required this.roomId,
    required this.repository,
    required this.classColor,
  });

  final String roomId;
  final SchoolRepository repository;
  final Color classColor;

  @override
  State<_LinksListView> createState() => _LinksListViewState();
}

class _LinksListViewState extends State<_LinksListView> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _LinksListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _initStream();
    }
  }

  void _initStream() {
    _stream = widget.repository.firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ошибка загрузки ссылок: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SchoolColors.red, fontSize: 13),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final meta = data['metadata'] as Map? ?? {};
          return meta['isLink'] == true;
        }).toList();

        if (docs.isEmpty)
          return _EmptySidebarState(
            icon: Icons.link_outlined,
            label: AppLocalizations.of(context)!.thereAreNoLinksYet,
          );

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final meta = data['metadata'] as Map? ?? {};
            final linkUrl =
                meta['linkUrl'] as String? ?? data['text'] as String? ?? '';
            final displayText = data['text'] as String? ?? linkUrl;
            final date = (data['createdAt'] as Timestamp?)?.toDate();

            return _LinkCardItem(
              displayText: displayText,
              linkUrl: linkUrl,
              date: date,
              classColor: widget.classColor,
            );
          },
        );
      },
    );
  }
}

class _LinkCardItem extends StatefulWidget {
  const _LinkCardItem({
    required this.displayText,
    required this.linkUrl,
    required this.date,
    required this.classColor,
  });

  final String displayText;
  final String linkUrl;
  final DateTime? date;
  final Color classColor;

  @override
  State<_LinkCardItem> createState() => _LinkCardItemState();
}

class _LinkCardItemState extends State<_LinkCardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(_isHovered ? 0.06 : 0.03)
                : Colors.black.withOpacity(_isHovered ? 0.04 : 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.classColor.withOpacity(0.4)
                  : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06)),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.classColor.withOpacity(_isHovered ? 0.12 : 0.0),
                blurRadius: _isHovered ? 8 : 0,
                offset: _isHovered ? const Offset(0, 4) : Offset.zero,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => openExternalUrl(widget.linkUrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.classColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.classColor.withOpacity(0.24),
                        ),
                      ),
                      child: Icon(
                        Icons.link_rounded,
                        color: widget.classColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.displayText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (widget.date != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(widget.date!),
                              style: const TextStyle(
                                fontSize: 10,
                                color: SchoolColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: widget.classColor.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MembersTabView extends StatefulWidget {
  const _MembersTabView({
    required this.roomId,
    required this.repository,
    required this.classColor,
  });

  final String roomId;
  final SchoolRepository repository;
  final Color classColor;

  @override
  State<_MembersTabView> createState() => _MembersTabViewState();
}

class _MembersTabViewState extends State<_MembersTabView> {
  late Future<List<Map<String, dynamic>>> _membersFuture;
  String _classId = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final l10n = AppLocalizations.of(context)!;
      _membersFuture = _loadMembers(
        teacherLabel: l10n.teacher,
        studentLabel: l10n.student,
        roomNotFoundMsg: l10n.roomNotFound,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadMembers({
    required String teacherLabel,
    required String studentLabel,
    required String roomNotFoundMsg,
  }) async {
    final roomSnap = await widget.repository.firestore
        .collection('rooms')
        .doc(widget.roomId)
        .get();

    if (!roomSnap.exists) {
      throw Exception(roomNotFoundMsg);
    }

    final data = roomSnap.data()!;
    _classId = data['classId'] as String? ?? '';
    List<String> userIds = [];
    List<String> adminIds = [];

    if (_classId.isNotEmpty) {
      final classSnap = await widget.repository.firestore
          .collection('classes')
          .doc(_classId)
          .get();
      if (classSnap.exists) {
        userIds = List<String>.from(classSnap.data()?['studentIds'] ?? []);
        adminIds = List<String>.from(classSnap.data()?['adminIds'] ?? []);
      }
    } else {
      userIds = List<String>.from(data['userIds'] ?? []);
    }

    if (userIds.isEmpty) return [];

    final futures = userIds.map((id) => widget.repository.firestore
        .collection('users')
        .doc(id)
        .get(const GetOptions(source: Source.serverAndCache)));

    final userSnaps = await Future.wait(futures);

    return userSnaps.map((snap) {
      final userData = snap.data() ?? {};
      final firstName = userData['firstName'] as String? ?? '';
      final lastName = userData['lastName'] as String? ?? '';
      final fullName = userData['name'] as String? ??
          (firstName.isEmpty && lastName.isEmpty
              ? (_classId.isEmpty ? teacherLabel : studentLabel)
              : '$firstName $lastName'.trim());

      final role = userData['role'] as String? ?? '';

      return {
        'id': snap.id,
        'name': fullName,
        'isAdmin': adminIds.contains(snap.id),
        'role': role,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ошибка загрузки участников:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SchoolColors.red, fontSize: 13),
              ),
            ),
          );
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return _EmptySidebarState(
            icon: Icons.group_outlined,
            label: AppLocalizations.of(context)!.noParticipantsYet,
          );
        }

        final isTeacher = AppScope.of(context).appState.isTeacher;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: members.length,
          itemBuilder: (context, i) {
            final member = members[i];
            final studentId = member['id'] as String;
            final name = member['name'] as String;
            final isAdmin = member['isAdmin'] as bool;
            final role = member['role'] as String?;

            String roleText = '';
            if (isAdmin) {
              roleText = AppLocalizations.of(context)!.administrator;
            } else {
              switch (role) {
                case 'teacher':
                case 'leadTeacher':
                  roleText = AppLocalizations.of(context)!.teacher;
                  break;
                case 'student':
                  roleText = AppLocalizations.of(context)!.student;
                  break;
                case 'parent':
                  roleText = AppLocalizations.of(context)!.parent1;
                  break;
                case 'admin':
                  roleText = AppLocalizations.of(context)!.administrator;
                  break;
                default:
                  roleText = _classId.isEmpty ? AppLocalizations.of(context)!.teacher : AppLocalizations.of(context)!.student;
              }
            }

            return ListTile(
              leading: SchoolAvatar(
                name: name,
                radius: 18,
                userId: studentId,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                roleText,
                style: const TextStyle(
                  fontSize: 11,
                  color: SchoolColors.muted,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              trailing: isTeacher && _classId.isNotEmpty
                  ? PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                      ),
                      onSelected: (val) {
                        if (val == 'admin') {
                          widget.repository.toggleClassAdmin(
                            classId: _classId,
                            userId: studentId,
                            isAdmin: !isAdmin,
                          );
                          setState(() {
                            _membersFuture = _loadMembers(
                                    teacherLabel: AppLocalizations.of(context)!.teacher,
                                    studentLabel: AppLocalizations.of(context)!.student,
                                    roomNotFoundMsg: AppLocalizations.of(context)!.roomNotFound,
                                  );
                          });
                        } else if (val == 'remove') {
                          _confirmRemove(
                            context,
                            widget.repository,
                            _classId,
                            studentId,
                          ).then((ok) {
                            if (ok == true && mounted) {
                              setState(() {
                                _membersFuture = _loadMembers(
                                    teacherLabel: AppLocalizations.of(context)!.teacher,
                                    studentLabel: AppLocalizations.of(context)!.student,
                                    roomNotFoundMsg: AppLocalizations.of(context)!.roomNotFound,
                                  );
                              });
                            }
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(
                                isAdmin
                                    ? Icons.admin_panel_settings
                                    : Icons.admin_panel_settings_outlined,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                isAdmin
                                    ? AppLocalizations.of(context)!.removeAdmin
                                    : AppLocalizations.of(context)!.makeAdmin,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_remove_rounded,
                                size: 18,
                                color: SchoolColors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.delete,
                                style: TextStyle(
                                  color: SchoolColors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmRemove(
    BuildContext context,
    SchoolRepository repository,
    String classId,
    String studentId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeFromClass),
        content: Text(
          AppLocalizations.of(context)!.areYouSureYouWant2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancellation),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: SchoolColors.red),
            child: Text(AppLocalizations.of(context)!.delete1),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repository.removeUserFromClass(classId: classId, userId: studentId);
      return true;
    }
    return false;
  }
}


class _PollsListView extends StatefulWidget {
  const _PollsListView({
    required this.roomId,
    required this.repository,
    required this.classColor,
  });

  final String roomId;
  final SchoolRepository repository;
  final Color classColor;

  @override
  State<_PollsListView> createState() => _PollsListViewState();
}

class _PollsListViewState extends State<_PollsListView> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _PollsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _initStream();
    }
  }

  void _initStream() {
    _stream = widget.repository.firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ошибка загрузки опросов: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SchoolColors.red, fontSize: 13),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return _EmptySidebarState(
            icon: Icons.poll_outlined,
            label: AppLocalizations.of(context)!.thereAreNoPollsYet,
          );
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) => _PollCard(
            pollId: docs[i].id,
            data: docs[i].data(),
            roomId: widget.roomId,
            repository: widget.repository,
            classColor: widget.classColor,
          ),
        );
      },
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({
    required this.pollId,
    required this.data,
    required this.roomId,
    required this.repository,
    required this.classColor,
  });

  final String pollId;
  final Map<String, dynamic> data;
  final String roomId;
  final SchoolRepository repository;
  final Color classColor;

  @override
  Widget build(BuildContext context) {
    final uid = repository.auth.currentUser?.uid ?? '';
    final question = data['question'] as String? ?? '';
    final options =
        (data['options'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final votes = Map<String, String>.from(data['votes'] as Map? ?? {});
    final myVote = votes[uid];
    final totalVotes = votes.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final opt in options) ...[
              _PollOption(
                optId: opt['id'] as String,
                text: opt['text'] as String,
                isSelected: myVote == opt['id'],
                voteCount: votes.values.where((v) => v == opt['id']).length,
                totalVotes: totalVotes,
                hasVoted: myVote != null,
                classColor: classColor,
                onTap: () async {
                  final ref = repository.firestore
                      .collection('rooms')
                      .doc(roomId)
                      .collection('polls')
                      .doc(pollId);
                  if (myVote == opt['id']) {
                    await ref.update({'votes.$uid': FieldValue.delete()});
                  } else {
                    await ref.update({'votes.$uid': opt['id']});
                  }
                },
              ),
              SizedBox(height: 6),
            ],
            SizedBox(height: 4),
            Text(
              '$totalVotes голос${totalVotes == 1 ? '' : (totalVotes < 5 ? AppLocalizations.of(context)!.a : AppLocalizations.of(context)!.ov)}',
              style: const TextStyle(fontSize: 11, color: SchoolColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollOption extends StatelessWidget {
  const _PollOption({
    required this.optId,
    required this.text,
    required this.isSelected,
    required this.voteCount,
    required this.totalVotes,
    required this.hasVoted,
    required this.classColor,
    required this.onTap,
  });

  final String optId, text;
  final bool isSelected, hasVoted;
  final int voteCount, totalVotes;
  final Color classColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = totalVotes == 0 ? 0.0 : voteCount / totalVotes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? classColor
                : (isDark
                      ? Colors.white.withOpacity(0.12)
                      : SchoolColors.border),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            if (hasVoted)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: pct),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(color: classColor.withOpacity(0.12)),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (hasVoted)
                  Text(
                    '${(pct * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: classColor,
                    ),
                  ),
                if (isSelected) const SizedBox(width: 4),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 16, color: classColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AIAssistantTab extends StatefulWidget {
  const _AIAssistantTab({
    required this.roomId,
    required this.repository,
    required this.classColor,
  });

  final String roomId;
  final SchoolRepository repository;
  final Color classColor;

  @override
  State<_AIAssistantTab> createState() => _AIAssistantTabState();
}

class _AIAssistantTabState extends State<_AIAssistantTab> {
  final _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'content':
          'Привет, я ваш учебный ассистент',
    },
  ];
  bool _loading = false;

  Future<void> _askAI() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _inputController.clear();
      _loading = true;
    });

    // Simulate AI response for now (RAG logic would be here)
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'content':
              AppLocalizations.of(context)!.interestingQuestionBasedOnThe,
        });
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _messages.length) return const _AILoadingIndicator();
              final m = _messages[i];
              final isAI = m['role'] == 'ai';
              return _AIMessageBubble(
                isAI: isAI,
                content: m['content']!,
                classColor: widget.classColor,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.askAi,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _askAI(),
                ),
              ),
              IconButton(
                onPressed: _askAI,
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  color: widget.classColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AIMessageBubble extends StatelessWidget {
  const _AIMessageBubble({
    required this.isAI,
    required this.content,
    required this.classColor,
  });

  final bool isAI;
  final String content;
  final Color classColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor;
    final Color textColor;

    if (isAI) {
      bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5FD);
      textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    } else {
      bgColor = classColor;
      textColor = Colors.white;
    }

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isAI ? const Radius.circular(0) : null,
            bottomRight: !isAI ? const Radius.circular(0) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _AILoadingIndicator extends StatelessWidget {
  const _AILoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _EmptySidebarState extends StatelessWidget {
  const _EmptySidebarState({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: SchoolColors.border),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: SchoolColors.muted),
          ),
        ],
      ),
    );
  }
}
