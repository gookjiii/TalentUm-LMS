import 'package:school_world/l10n/app_localizations.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

import './feed_widgets.dart';

class TeacherFeed extends ConsumerStatefulWidget {
  const TeacherFeed({super.key, required this.classId, required this.classes});

  final String classId;
  final List<Map<String, dynamic>> classes;

  @override
  ConsumerState<TeacherFeed> createState() => _TeacherFeedState();
}

class _TeacherFeedState extends ConsumerState<TeacherFeed> {
  String _searchQuery = '';
  final _composerKey = GlobalKey();
  Stream<QuerySnapshot<Map<String, dynamic>>>? _postsStream;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedPosts = [];
  String? _activeClassId;
  int _limit = 20;

  void _updateStreamIfNeeded(String classId) {
    if (_activeClassId != classId) {
      _activeClassId = classId;
      _limit = 20;
      _cachedPosts.clear();
      final repo = AppScope.of(context).repository;
      _postsStream = repo.postsForClass(classId, limit: _limit);
    }
  }

  void _loadMore(int currentCount) {
    if (currentCount < _limit || _activeClassId == null) return;
    setState(() {
      _limit += 20;
      final repo = AppScope.of(context).repository;
      _postsStream = repo.postsForClass(_activeClassId!, limit: _limit);
    });
  }

  void _scrollToComposer() {
    final composerContext = _composerKey.currentContext;
    if (composerContext == null) return;
    Scrollable.ensureVisible(
      composerContext,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _newPostButton({required bool expanded}) {
    final button = FilledButton.icon(
      onPressed: _scrollToComposer,
      style: FilledButton.styleFrom(
        minimumSize: expanded ? const Size.fromHeight(48) : Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? 20 : 16,
          vertical: expanded ? 14 : 10,
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(AppLocalizations.of(context)!.newPost),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(
      schoolAppStateProvider.select((s) => s.selectedClassId),
    );
    final activeClassId = (selectedId != null && selectedId.isNotEmpty)
        ? selectedId
        : widget.classId;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final horizontalPadding = isCompact ? 20.0 : 24.0;
    _updateStreamIfNeeded(activeClassId);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMore(_cachedPosts.length);
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, _) {
                final allClassAsync = ref.watch(teacherClassesStreamProvider);
                final allVisibleClasses = allClassAsync.value ?? [];
                final currentClassName = allVisibleClasses
                    .firstWhere(
                      (c) => c['id'] == activeClassId,
                      orElse: () => {},
                    )['name']
                    ?.toString();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      title: AppLocalizations.of(context)!.ribbon,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.declarationsForYourClasses,
                      classContext: currentClassName,
                      onClassContextTap: allVisibleClasses.length > 1
                          ? () {
                              showClassSwitcher(
                                context: context,
                                classes: allVisibleClasses,
                                currentClassId: activeClassId,
                                onSelect: (id) {
                                  ref
                                      .read(schoolAppStateProvider)
                                      .selectClass(id);
                                },
                              );
                            }
                          : null,
                      trailing: isCompact
                          ? null
                          : _newPostButton(expanded: false),
                      padding: isCompact
                          ? const EdgeInsets.fromLTRB(20, 14, 20, 0)
                          : null,
                    ),
                    if (isCompact)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _newPostButton(expanded: true),
                      ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      )!.searchByAdvertisements,
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? SchoolColors.darkSurface
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  SizedBox(height: isCompact ? 20 : 24),
                  Container(
                    key: _composerKey,
                    child: _InlineComposer(
                      classes: widget.classes,
                      initialClassId: activeClassId,
                    ),
                  ),
                  SizedBox(height: isCompact ? 20 : 24),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _postsStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _cachedPosts = snapshot.data!.docs;
              }
              var posts = snapshot.hasData ? snapshot.data!.docs : _cachedPosts;
              final isInitialLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  _cachedPosts.isEmpty;

              if (_searchQuery.isNotEmpty) {
                posts = posts.where((doc) {
                  final content =
                      doc.data()['content']?.toString().toLowerCase() ?? '';
                  return content.contains(_searchQuery);
                }).toList();
              }

              if (isInitialLoading) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.thereAreNoAnnouncementsYet,
                        style: const TextStyle(color: SchoolColors.muted),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final doc = posts[index];
                    final data = doc.data();
                    final cId = data['classId']?.toString();
                    final classData = widget.classes.firstWhere(
                      (c) => c['id'] == cId,
                      orElse: () =>
                          widget.classes.isNotEmpty ? widget.classes.first : {},
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: RepaintBoundary(
                        child: PostCard(
                          doc: doc,
                          classData: classData,
                          canManage: true,
                        ),
                      ),
                    );
                  }, childCount: posts.length),
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: isCompact ? 136 : 80)),
        ],
      ),
    );
  }
}

class _InlineComposer extends StatefulWidget {
  const _InlineComposer({required this.classes, required this.initialClassId});
  final List<Map<String, dynamic>> classes;
  final String initialClassId;

  @override
  State<_InlineComposer> createState() => _InlineComposerState();
}

class _InlineComposerState extends State<_InlineComposer> {
  final controller = TextEditingController();
  late String selectedClassId = _resolveInitialClass();
  PlatformFile? pickedFile;
  bool isUploading = false;
  bool isPinned = false;

  @override
  void didUpdateWidget(covariant _InlineComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialClassId != widget.initialClassId ||
        selectedClassId.isEmpty ||
        !widget.classes.any((c) => c['id'] == selectedClassId)) {
      setState(() {
        selectedClassId = _resolveInitialClass();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _resolveInitialClass() {
    // Default to first class if initialClassId is empty or not found
    if (widget.initialClassId.isNotEmpty &&
        widget.classes.any((c) => c['id'] == widget.initialClassId)) {
      return widget.initialClassId;
    }
    if (widget.classes.isNotEmpty) {
      return widget.classes.first['id'] as String? ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return SchoolCard(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SchoolAvatar(
                name: AppLocalizations.of(context)!.you,
                userId: AppScope.of(context).repository.uid,
                radius: 20,
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    )!.postAnAnnouncementForClasses,
                    hintStyle: TextStyle(color: SchoolColors.muted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ],
          ),
          if (pickedFile != null)
            Padding(
              padding: EdgeInsets.only(top: 12, left: isCompact ? 0 : 56),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (pickedFile!.bytes != null)
                      Image.memory(
                        pickedFile!.bytes!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    else if (pickedFile!.path != null)
                      Image.file(
                        File(pickedFile!.path!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        onPressed: () => setState(() => pickedFile = null),
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (isCompact)
            _MobileComposerActions(
              classSelector: _buildClassSelector(context, compact: true),
              isUploading: isUploading,
              canPublish:
                  controller.text.trim().isNotEmpty || pickedFile != null,
              isPinned: isPinned,
              hasAttachment: pickedFile != null,
              onPickImage: _pickImage,
              onTogglePinned: () => setState(() => isPinned = !isPinned),
              onPublish: _publish,
            )
          else
            Row(
              children: [
                if (widget.classes.isNotEmpty)
                  _buildClassSelector(context, compact: false),
                const SizedBox(width: 8),
                _ComposerIconButton(
                  tooltip: AppLocalizations.of(context)!.attachAnImage,
                  onPressed: _pickImage,
                  icon: Icons.image_outlined,
                  color: pickedFile != null
                      ? SchoolColors.primary
                      : SchoolColors.muted,
                ),
                _ComposerIconButton(
                  tooltip: AppLocalizations.of(context)!.pinThisAd,
                  onPressed: () => setState(() => isPinned = !isPinned),
                  icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? SchoolColors.orange : SchoolColors.muted,
                ),
                const Spacer(),
                if (isUploading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton(
                    onPressed:
                        controller.text.trim().isEmpty && pickedFile == null
                        ? null
                        : _publish,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.publish),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildClassSelector(BuildContext context, {required bool compact}) {
    if (widget.classes.isEmpty) return const SizedBox.shrink();

    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: widget.classes.any((c) => c['id'] == selectedClassId)
            ? selectedClassId
            : (widget.classes.first['id'] as String),
        isExpanded: compact,
        borderRadius: BorderRadius.circular(12),
        items: widget.classes
            .map(
              (c) => DropdownMenuItem(
                value: c['id'] as String,
                child: Text(
                  c['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: SchoolColors.primary,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => selectedClassId = value!),
      ),
    );

    if (!compact) return dropdown;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: SchoolColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SchoolColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.school_rounded,
            size: 18,
            color: SchoolColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: dropdown),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && mounted) {
      setState(() => pickedFile = result.files.first);
    }
  }

  Future<void> _publish() async {
    final repo = AppScope.of(context).repository;
    setState(() => isUploading = true);
    try {
      Map<String, dynamic>? attachment;
      if (pickedFile != null) {
        final path =
            'classes/$selectedClassId/feed/${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}';
        if (pickedFile!.bytes != null) {
          attachment = await repo.uploadFileWeb(path, pickedFile!.bytes!);
        } else if (pickedFile!.path != null) {
          attachment = await repo.uploadFile(path, File(pickedFile!.path!));
        }
      }

      await repo.createPost(
        classId: selectedClassId,
        content: controller.text.trim(),
        pinned: isPinned,
        attachments: attachment != null
            ? [
                {
                  'type': 'image',
                  ...attachment,
                  'name': pickedFile!.name,
                  'size': pickedFile!.size,
                },
              ]
            : [],
      );
      controller.clear();
      setState(() {
        pickedFile = null;
        isPinned = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      setState(() => isUploading = false);
    }
  }
}

class _MobileComposerActions extends StatelessWidget {
  const _MobileComposerActions({
    required this.classSelector,
    required this.isUploading,
    required this.canPublish,
    required this.isPinned,
    required this.hasAttachment,
    required this.onPickImage,
    required this.onTogglePinned,
    required this.onPublish,
  });

  final Widget classSelector;
  final bool isUploading;
  final bool canPublish;
  final bool isPinned;
  final bool hasAttachment;
  final VoidCallback onPickImage;
  final VoidCallback onTogglePinned;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: classSelector),
            const SizedBox(width: 8),
            _ComposerIconButton(
              tooltip: AppLocalizations.of(context)!.attachAnImage,
              onPressed: onPickImage,
              icon: Icons.image_outlined,
              color: hasAttachment ? SchoolColors.primary : SchoolColors.muted,
            ),
            _ComposerIconButton(
              tooltip: AppLocalizations.of(context)!.pinThisAd,
              onPressed: onTogglePinned,
              icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: isPinned ? SchoolColors.orange : SchoolColors.muted,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isUploading)
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          FilledButton.icon(
            onPressed: canPublish ? onPublish : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.publish),
          ),
      ],
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: color),
      ),
    );
  }
}
