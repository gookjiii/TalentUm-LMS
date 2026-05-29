import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/src/app_state.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/features/feed/presentation/widgets/feed_widgets.dart';
import 'profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    required this.repository,
    required this.appState,
    required this.classId,
  });

  final SchoolRepository repository;
  final SchoolAppState appState;
  final String classId;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

enum _FeedFilter { all, pinned, mine, liked }

class _FeedScreenState extends State<FeedScreen> {
  _FeedFilter _filter = _FeedFilter.all;

  bool get _isTeacher => widget.appState.role == 'teacher';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    final userName =
        widget.repository.auth.currentUser?.displayName ?? AppLocalizations.of(context)!.user;

    return Scaffold(
      backgroundColor: SchoolColors.bg,
      appBar: isMobile ? null : AppBar(title: Text(l10n.feed)),
      body: CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        streamFactory: () => widget.repository.postsForClass(widget.classId),
        keys: [widget.classId],
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final posts = _filteredPosts(snapshot.data!.docs);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.feed,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SchoolAvatar(
                            name: userName,
                            userId: widget.repository.uid,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FilterBar(
                        selected: _filter,
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                    ],
                  ),
                ),
              ),
              if (posts.isEmpty)
                SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context)!.empty)))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: widget.repository.getClassData(widget.classId),
                        builder: (context, classSnap) {
                          final classData =
                              classSnap.data ??
                              {'name': widget.classId, 'coverColor': '#1a73e8'};
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PostCard(
                              doc: posts[index],
                              classData: classData,
                              canManage: _isTeacher,
                            ),
                          );
                        },
                      );
                    }, childCount: posts.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredPosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> posts,
  ) {
    final uid = widget.repository.uid;
    return posts.where((doc) {
      final data = doc.data();
      final likes = List<String>.from(data['likes'] ?? []);
      return switch (_filter) {
        _FeedFilter.all => true,
        _FeedFilter.pinned => data['pinned'] == true,
        _FeedFilter.mine => data['authorId'] == uid,
        _FeedFilter.liked => uid != null && likes.contains(uid),
      };
    }).toList();
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});
  final _FeedFilter selected;
  final ValueChanged<_FeedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _FeedFilter.values
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected == f,
                  label: Text(f.name),
                  onSelected: (_) => onChanged(f),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
