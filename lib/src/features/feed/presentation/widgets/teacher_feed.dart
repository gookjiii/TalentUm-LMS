import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
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
      _initStream();
    }
  }

  void _initStream() {
    final repo = AppScope.of(context).repository;
    setState(() => _postsStream = repo.postsForClass(widget.classId));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobileHeader = constraints.maxWidth < 500;
                    const headerTitle = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Лента',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Объявления для ваших классов',
                          style: TextStyle(
                            color: SchoolColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );

                    final newPostButton = FilledButton.icon(
                      onPressed: () {
                        if (_composerKey.currentContext != null) {
                          Scrollable.ensureVisible(
                            _composerKey.currentContext!,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Новый пост'),
                    );

                    if (isMobileHeader) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerTitle,
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: newPostButton,
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(child: headerTitle),
                        const SizedBox(width: 16),
                        newPostButton,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                TextField(
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Поиск по объявлениям...',
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
                const SizedBox(height: 24),
                Container(
                  key: _composerKey,
                  child: _InlineComposer(
                    classes: widget.classes,
                    initialClassId: widget.classId,
                  ),
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
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Text(
                      'Объявлений пока нет.',
                      style: TextStyle(color: SchoolColors.muted),
                    ),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    child: PostCard(
                      doc: doc,
                      classData: classData,
                      canManage: true,
                    ),
                  );
                }, childCount: posts.length),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
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
    return SchoolCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SchoolAvatar(name: 'Вы', radius: 20),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Опубликуйте объявление для классов…',
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
              if (widget.classes.isNotEmpty)
                DropdownButton<String>(
                  value: widget.classes.any((c) => c['id'] == selectedClassId)
                      ? selectedClassId
                      : (widget.classes.first['id'] as String),
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  items: widget.classes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text(
                            c['name']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: SchoolColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedClassId = v!),
                ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Прикрепить изображение',
                button: true,
                child: IconButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
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
                label: 'Закрепить объявление',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Опубликовать'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      setState(() => isUploading = false);
    }
  }
}
