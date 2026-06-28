import 'package:school_world/l10n/app_localizations.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/utils/responsive_utils.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

import './feed_widgets.dart';

class TeacherFeed extends StatefulWidget {
  const TeacherFeed({super.key, required this.classId, required this.classes});

  final String classId;
  final List<Map<String, dynamic>> classes;

  @override
  State<TeacherFeed> createState() => _TeacherFeedState();
}

class _TeacherFeedState extends State<TeacherFeed> {
  String _searchQuery = '';
  final _composerKey = GlobalKey();
  Stream<QuerySnapshot<Map<String, dynamic>>>? _postsStream;
  bool _initialized = false;
  int _limit = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initStream();
    }
  }

  @override
  void didUpdateWidget(covariant TeacherFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _limit = 20;
      _initStream();
    }
  }

  void _initStream() {
    final repo = AppScope.of(context).repository;
    setState(
      () => _postsStream = repo.postsForClass(widget.classId, limit: _limit),
    );
  }

  void _loadMore() {
    setState(() {
      _limit += 20;
      _initStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMore();
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
                final effectiveClassId =
                    ref.watch(
                      schoolAppStateProvider.select((s) => s.selectedClassId),
                    ) ??
                    widget.classId;
                final currentClassName = allVisibleClasses
                    .firstWhere(
                      (c) => c['id'] == effectiveClassId,
                      orElse: () => {},
                    )['name']
                    ?.toString();

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: PageHeader(
                    padding: EdgeInsets.zero,
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
                              currentClassId: effectiveClassId,
                              onSelect: (id) {
                                ref
                                    .read(schoolAppStateProvider)
                                    .selectClass(id);
                              },
                            );
                          }
                        : null,
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  SchoolCard(
                    padding: EdgeInsets.all(context.isMobile ? 16 : 20),
                    borderRadius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        TextField(
                          onChanged: (v) => setState(
                            () => _searchQuery = v.trim().toLowerCase(),
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.searchByAdvertisements,
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? SchoolColors.darkSurface
                                : SchoolColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InlineComposer(
                    key: _composerKey,
                    classes: widget.classes,
                    initialClassId: widget.classId,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _postsStream,
            builder: (context, snapshot) {
              var posts = snapshot.data?.docs ?? [];

              if (_searchQuery.isNotEmpty) {
                posts = posts.where((doc) {
                  final content =
                      doc.data()['content']?.toString().toLowerCase() ?? '';
                  return content.contains(_searchQuery);
                }).toList();
              }

              if (posts.isEmpty &&
                  snapshot.connectionState != ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: EmptyState(
                      icon: Icons.campaign_outlined,
                      title: AppLocalizations.of(
                        context,
                      )!.thereAreNoAnnouncementsYet,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.declarationsForYourClasses,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalPadding,
                  0,
                  context.horizontalPadding,
                  MediaQuery.paddingOf(context).bottom,
                ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _InlineComposer extends StatefulWidget {
  const _InlineComposer({super.key, required this.classes, required this.initialClassId});
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
    if (selectedClassId.isEmpty ||
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? SchoolColors.darkSurfaceElevated : SchoolColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? SchoolColors.darkBorder : SchoolColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.newPost.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: SchoolColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SchoolAvatar(
                name: AppLocalizations.of(context)!.you,
                userId: AppScope.of(context).repository.uid,
                radius: 20,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? SchoolColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? SchoolColors.darkBorder : SchoolColors.border),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      )!.postAnAnnouncementForClasses,
                      hintStyle: const TextStyle(color: SchoolColors.muted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
          if (pickedFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 56),
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
          Row(
            children: [
              Semantics(
                label: AppLocalizations.of(context)!.attachAnImage,
                button: true,
                child: IconButton(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null)
                      setState(() => pickedFile = result.files.first);
                  },
                  icon: Icon(
                    Icons.image_outlined,
                    color: pickedFile != null
                        ? SchoolColors.primary
                        : SchoolColors.muted,
                  ),
                ),
              ),
              Semantics(
                label: AppLocalizations.of(context)!.pinThisAd,
                button: true,
                child: IconButton(
                  onPressed: () => setState(() => isPinned = !isPinned),
                  icon: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? SchoolColors.orange : SchoolColors.muted,
                  ),
                ),
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
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: Text(AppLocalizations.of(context)!.publish),
                ),
            ],
          ),
        ],
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.uploadError(e.toString()))));
      }
    } finally {
      setState(() => isUploading = false);
    }
  }
}

