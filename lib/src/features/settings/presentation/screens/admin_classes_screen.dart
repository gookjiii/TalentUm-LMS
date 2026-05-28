import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import '../../../classroom/presentation/screens/bulk_class_create_screen.dart';

class AdminClassesScreen extends StatefulWidget {
  const AdminClassesScreen({super.key});

  @override
  State<AdminClassesScreen> createState() => _AdminClassesScreenState();
}

class _AdminClassesScreenState extends State<AdminClassesScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showTeacherSelectionDialog(
    String classId,
    String currentTeacherId,
  ) async {
    final repo = AppScope.of(context).repository;

    // Fetch all teachers
    final snapshot = await repo.firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();
    final leadTeacherSnapshot = await repo.firestore
        .collection('users')
        .where('role', isEqualTo: 'leadTeacher')
        .get();
    final adminSnapshot = await repo.firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    final allTeachers = [
      ...snapshot.docs,
      ...leadTeacherSnapshot.docs,
      ...adminSnapshot.docs,
    ];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Назначить учителя',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: allTeachers.length,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemBuilder: (context, index) {
                    final doc = allTeachers[index];
                    final data = doc.data();
                    final id = doc.id;
                    final name = data['name']?.toString() ?? 'Без имени';
                    final isCurrent = id == currentTeacherId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SchoolAvatar(
                        name: name,
                        avatarUrl: data['avatarUrl']?.toString(),
                        radius: 20,
                        userId: id,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(data['email']?.toString() ?? ''),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: SchoolColors.green,
                            )
                          : null,
                      onTap: () async {
                        Navigator.pop(context);
                        await repo.firestore
                            .collection('classes')
                            .doc(classId)
                            .update({'teacherId': id});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Учитель $name назначен')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Управление классами',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BulkClassCreateScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Создать классы',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SchoolCard(
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск по названию или предмету...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CachedStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                streamFactory: () => repo.firestore.collection('classes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final subject = (data['subject'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(_searchQuery) ||
                        subject.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('Классы не найдены'));
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final id = docs[index].id;
                      final name = data['name']?.toString() ?? 'Без названия';
                      final subject = data['subject']?.toString();
                      final teacherId = data['teacherId']?.toString() ?? '';

                      return SchoolCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: SchoolColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.school_rounded,
                                  color: SchoolColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (subject != null && subject.isNotEmpty)
                                    Text(
                                      subject,
                                      style: const TextStyle(
                                        color: SchoolColors.muted,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ClassActions(
                              classId: id,
                              teacherId: teacherId,
                              className: name,
                              onAssignTeacher: () =>
                                  _showTeacherSelectionDialog(id, teacherId),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate widget so it doesn't get caught in the stream rebuild loop.
class _ClassActions extends StatelessWidget {
  const _ClassActions({
    required this.classId,
    required this.teacherId,
    required this.className,
    required this.onAssignTeacher,
  });

  final String classId;
  final String teacherId;
  final String className;
  final VoidCallback onAssignTeacher;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onAssignTeacher,
      style: FilledButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
      label: const Text('Учитель'),
    );
  }
}
