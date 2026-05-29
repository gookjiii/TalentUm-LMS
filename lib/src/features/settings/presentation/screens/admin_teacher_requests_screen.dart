import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';

class AdminTeacherRequestsScreen extends ConsumerStatefulWidget {
  const AdminTeacherRequestsScreen({super.key});

  @override
  ConsumerState<AdminTeacherRequestsScreen> createState() => _AdminTeacherRequestsScreenState();
}

class _AdminTeacherRequestsScreenState extends ConsumerState<AdminTeacherRequestsScreen> {
  Future<void> _approveRequest(String userId, String requestId) async {
    final repo = ref.read(repositoryProvider);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Make user a teacher
      await repo.firestore.collection('users').doc(userId).update({
        'role': 'teacher',
      });

      // Delete the request
      await repo.firestore.collection('teacher_requests').doc(requestId).delete();

      if (mounted) {
        Navigator.pop(context); // spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.teachersLicenseIssued)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final repo = ref.read(repositoryProvider);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Delete the request
      await repo.firestore.collection('teacher_requests').doc(requestId).delete();

      if (mounted) {
        Navigator.pop(context); // spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.applicationRejected)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.applicationsForTeachers),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<QuerySnapshot>(
        stream: repo.firestore.collection('teacher_requests').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_outlined,
              title: AppLocalizations.of(context)!.noApplications,
              subtitle: AppLocalizations.of(context)!.allRequestsProcessed,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final requestId = docs[index].id;
              final userId = data['userId'] as String;
              final name = data['name'] as String? ?? AppLocalizations.of(context)!.student;
              final email = data['email'] as String? ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: SchoolColors.accent.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_outline, color: SchoolColors.accent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: const TextStyle(color: SchoolColors.muted, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _approveRequest(userId, requestId),
                        icon: const Icon(Icons.check_circle_outline, color: SchoolColors.green),
                        tooltip: AppLocalizations.of(context)!.approve,
                      ),
                      IconButton(
                        onPressed: () => _rejectRequest(requestId),
                        icon: const Icon(Icons.cancel_outlined, color: SchoolColors.red),
                        tooltip: AppLocalizations.of(context)!.reject,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
