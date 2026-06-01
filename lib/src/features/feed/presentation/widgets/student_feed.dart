import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import '../../../../screens/profile_screen.dart';

import './feed_widgets.dart';

class StudentFeed extends StatefulWidget {
  const StudentFeed({
    super.key,
    required this.classId,
    required this.classes,
    required this.onClassSelect,
  });
  final String classId;
  final List<Map<String, dynamic>> classes;
  final ValueChanged<String> onClassSelect;

  @override
  State<StudentFeed> createState() => _StudentFeedState();
}

class _StudentFeedState extends State<StudentFeed> {
  String _searchQuery = '';
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
  void didUpdateWidget(covariant StudentFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _limit = 20;
      _initStream();
    }
  }

  void _initStream() {
    final repo = AppScope.of(context).repository;
    setState(() {
      _postsStream = widget.classId == 'all'
          ? repo.firestore
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .limit(_limit)
                .snapshots()
          : repo.postsForClass(widget.classId, limit: _limit);
    });
  }

  void _loadMore() {
    setState(() {
      _limit += 20;
      _initStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? AppLocalizations.of(context)!.student;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SizedBox.expand(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                _loadMore();
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.ribbon,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.announcementsFromYourTeachers,
                                    style: TextStyle(
                                      color: SchoolColors.muted.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SchoolAvatar(
                              name: name,
                              userId: user?.uid,
                              radius: 22,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        TextField(
                          onChanged: (v) => setState(
                            () => _searchQuery = v.trim().toLowerCase(),
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchByAdvertisements,
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? SchoolColors.darkSurface
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FeedFilterChip(
                                label: AppLocalizations.of(context)!.allClasses,
                                active: widget.classId == 'all',
                                onTap: () => widget.onClassSelect('all'),
                              ),
                              ...widget.classes.map(
                                (c) => _FeedFilterChip(
                                  label: c['name']?.toString() ?? '',
                                  active: c['id'] == widget.classId,
                                  onTap: () =>
                                      widget.onClassSelect(c['id'] as String),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(80),
                            child: Text(
                              AppLocalizations.of(context)!.thereAreNoAnnouncementsYet,
                              style: TextStyle(color: SchoolColors.muted),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = posts[index];
                          final data = doc.data();
                          final cId = data['classId']?.toString();
                          final classData = widget.classes.firstWhere(
                            (c) => c['id'] == cId,
                            orElse: () => widget.classes.isNotEmpty
                                ? widget.classes.first
                                : {},
                          );
  
                          if (classData.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PostCard(
                              doc: doc,
                              classData: classData,
                              canManage: false,
                            ),
                          );
                        }, childCount: posts.length),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedFilterChip extends StatelessWidget {
  const _FeedFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: 'Фильтр: $label',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: active,
          onSelected: (_) => onTap(),
          backgroundColor: Colors.white,
          selectedColor: SchoolColors.primary,
          labelStyle: TextStyle(
            color: active ? Colors.white : SchoolColors.muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: active ? SchoolColors.primary : SchoolColors.border,
            ),
          ),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        ),
      ),
    );
  }
}
