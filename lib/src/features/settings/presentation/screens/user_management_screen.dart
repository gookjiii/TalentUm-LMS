import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.users,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SchoolCard(
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchByNameEmailOr,
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
                streamFactory: () => repo.firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final email = (data['email'] ?? '')
                        .toString()
                        .toLowerCase();
                    final id = doc.id.toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        id.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)!.noUsersFound));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final id = docs[index].id;
                      return _UserListTile(id: id, data: data);
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

class _UserListTile extends StatelessWidget {
  const _UserListTile({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final role = data['role']?.toString() ?? 'student';
    final name = data['name']?.toString() ?? AppLocalizations.of(context)!.unknownKey6;
    final email = data['email']?.toString() ?? AppLocalizations.of(context)!.noEmail;
    final avatarUrl = data['avatarUrl']?.toString();
    final isBanned = data['isBanned'] == true;

    return SchoolCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              SchoolAvatar(
                name: name,
                avatarUrl: avatarUrl,
                radius: 24,
                userId: id,
              ),
              if (isBanned)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    decoration: isBanned ? TextDecoration.lineThrough : null,
                    color: isBanned ? SchoolColors.muted : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email,
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
          if (isBanned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Text(
                'BANNED',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            _RoleBadge(role: role),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: SchoolColors.muted,
            ),
            onSelected: (val) async {
              if (val == 'make_admin') {
                await repo.firestore.collection('users').doc(id).update({
                  'role': 'admin',
                });
              } else if (val == 'make_teacher') {
                await repo.firestore.collection('users').doc(id).update({
                  'role': 'teacher',
                });
              } else if (val == 'make_student') {
                await repo.firestore.collection('users').doc(id).update({
                  'role': 'student',
                });
              } else if (val == 'ban') {
                await repo.firestore.collection('users').doc(id).update({
                  'isBanned': true,
                });
              } else if (val == 'unban') {
                await repo.firestore.collection('users').doc(id).update({
                  'isBanned': false,
                });
              }
            },
            itemBuilder: (context) => [
              if (!isBanned) ...[
                if (role != 'admin')
                  PopupMenuItem(
                    value: 'make_admin',
                    child: Text(AppLocalizations.of(context)!.makeAdmin),
                  ),
                if (role != 'teacher')
                  PopupMenuItem(
                    value: 'make_teacher',
                    child: Text(AppLocalizations.of(context)!.makeItATeacher),
                  ),
                if (role != 'student')
                  PopupMenuItem(
                    value: 'make_student',
                    child: Text(AppLocalizations.of(context)!.makeAStudent),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'ban',
                  child: Text(
                    AppLocalizations.of(context)!.block,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ] else ...[
                PopupMenuItem(
                  value: 'unban',
                  child: Text(
                    AppLocalizations.of(context)!.unblock,
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (role) {
      case 'admin':
      case 'leadTeacher':
        color = SchoolColors.primary;
        label = 'ADMIN';
        break;
      case 'teacher':
        color = SchoolColors.green;
        label = 'TEACHER';
        break;
      default:
        color = SchoolColors.muted;
        label = 'STUDENT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
