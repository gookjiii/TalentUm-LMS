import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_world/l10n/app_localizations.dart';
import '../../main.dart';
import '../theme.dart';
import '../widgets/school_widgets.dart';

class TeacherAccessCard extends StatelessWidget {
  const TeacherAccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final uid = repo.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: repo.firestore.collection('teacher_requests').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final hasRequested = snapshot.hasData && (snapshot.data?.exists ?? false);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context)!;

        return GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SchoolColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_outlined, color: SchoolColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.teacherAccess,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          hasRequested ? l10n.requestSent : l10n.requestTeacherPermissions,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!hasRequested)
                    Flexible(
                      child: FilledButton(
                        onPressed: () => _requestTeacherAccess(context, uid, repo),
                        style: FilledButton.styleFrom(
                          backgroundColor: SchoolColors.accent,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(l10n.send),
                      ),
                    )
                  else
                    const Icon(Icons.check_circle_rounded, color: SchoolColors.green),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestTeacherAccess(BuildContext context, String uid, dynamic repo) async {
    final l10n = AppLocalizations.of(context)!;
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherAccess),
        content: Text(l10n.submitARequestForA),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
    
    if (ok == true) {
      final user = FirebaseAuth.instance.currentUser;
      final doc = await repo.firestore.collection('users').doc(uid).get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      
      await repo.firestore.collection('teacher_requests').doc(uid).set({
        'userId': uid,
        'name': data['name'] ?? l10n.student,
        'email': user?.email ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestSent)),
        );
      }
    }
  }
}
