import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.transparent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMore();
          }
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: _FeedHeader(
                      searchQuery: _searchQuery,
                      onSearchChanged: (v) => setState(() => _searchQuery = v),
                      classId: widget.classId,
                      classes: widget.classes,
                      onClassSelect: widget.onClassSelect,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: _buildPostsList(isDark)),
                              const SizedBox(width: 32),
                              Expanded(flex: 3, child: _buildDeadlinesSidebar(isDark)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDeadlinesSidebar(isDark),
                              const SizedBox(height: 32),
                              _buildPostsList(isDark),
                            ],
                          ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostsList(bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        var posts = snapshot.data?.docs ?? [];

        if (_searchQuery.isNotEmpty) {
          posts = posts.where((doc) {
            final content = doc.data()['content']?.toString().toLowerCase() ?? '';
            return content.contains(_searchQuery);
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Updates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : SchoolColors.text,
              ),
            ),
            const SizedBox(height: 24),
            if (posts.isEmpty && snapshot.connectionState != ConnectionState.waiting)
              EmptyStateWidget(
                icon: Icons.notifications_none_rounded,
                title: AppLocalizations.of(context)!.thereAreNoAnnouncementsYet,
                subtitle: 'No more updates in your feed.',
              )
            else
              ...posts.map((doc) {
                final data = doc.data();
                final cId = data['classId']?.toString();
                final classData = widget.classes.firstWhere(
                  (c) => c['id'] == cId,
                  orElse: () => widget.classes.isNotEmpty ? widget.classes.first : {},
                );

                if (classData.isEmpty) return const SizedBox.shrink();

                // Wrapping PostCard with Glassmorphism
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    borderRadius: 20,
                    padding: EdgeInsets.zero,
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.5),
                    child: PostCard(
                      doc: doc,
                      classData: classData,
                      canManage: false,
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildDeadlinesSidebar(bool isDark) {
    final repo = AppScope.of(context).repository;
    final classIds = widget.classes.map((c) => c['id'].toString()).toList();
    
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.assignmentsForClasses(classIds, limit: 10),
      builder: (context, snapshot) {
        final assignments = snapshot.data?.docs ?? [];
        final now = DateTime.now().millisecondsSinceEpoch;
        
        final upcoming = assignments.where((doc) {
          final dueMs = doc.data()['dueDateMs'] as int?;
          return dueMs != null && dueMs >= now;
        }).toList();
        
        upcoming.sort((a, b) {
          final dueA = a.data()['dueDateMs'] as int? ?? 0;
          final dueB = b.data()['dueDateMs'] as int? ?? 0;
          return dueA.compareTo(dueB);
        });

        final displayDeadlines = upcoming.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Deadlines',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : SchoolColors.text,
                ),
              ),
              const SizedBox(height: 24),
              if (displayDeadlines.isEmpty)
                Text('No upcoming deadlines', style: TextStyle(color: isDark ? Colors.white54 : SchoolColors.muted))
              else
                ...displayDeadlines.map((doc) {
                  final data = doc.data();
                  final title = data['title']?.toString() ?? 'Assignment';
                  final dueMs = data['dueDateMs'] as int?;
                  final dateStr = dueMs != null 
                      ? 'Due ' + DateFormat('MMM dd').format(DateTime.fromMillisecondsSinceEpoch(dueMs))
                      : 'No due date';
                  final cId = data['classId']?.toString();
                  final classData = widget.classes.firstWhere(
                    (c) => c['id'] == cId,
                    orElse: () => {},
                  );
                  final coverColorHex = classData['coverColor']?.toString() ?? '#4F46E5';
                  final color = parseHexColor(coverColorHex);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : SchoolColors.text)),
                                const SizedBox(height: 4),
                                Text(dateStr, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : SchoolColors.muted)),
                              ],
                            ),
                          ),
                          Icon(Icons.access_time_rounded, size: 16, color: isDark ? Colors.white54 : SchoolColors.muted),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: isDark ? Colors.white24 : SchoolColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('View Full Calendar', style: TextStyle(color: isDark ? Colors.white : SchoolColors.text)),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.classId,
    required this.classes,
    required this.onClassSelect,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String classId;
  final List<Map<String, dynamic>> classes;
  final ValueChanged<String> onClassSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // No avatar/name row because StudentShell already contains it in sidebar
        Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            onChanged: (v) => onSearchChanged(v.trim().toLowerCase()),
            style: TextStyle(
              color: isDark ? Colors.white : SchoolColors.text,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: l10n.searchByAdvertisements,
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : SchoolColors.muted,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white54 : SchoolColors.muted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FeedFilterChip(
                label: l10n.allClasses,
                active: classId == 'all',
                onTap: () => onClassSelect('all'),
              ),
              ...classes.map(
                (c) => _FeedFilterChip(
                  label: c['name']?.toString() ?? '',
                  active: c['id'] == classId,
                  onTap: () => onClassSelect(c['id'] as String),
                ),
              ),
            ],
          ),
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: active,
      label: 'Filter: $label',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: active 
                  ? SchoolColors.primary 
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active 
                    ? Colors.white 
                    : (isDark ? Colors.white : SchoolColors.text),
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
