import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/providers/app_providers.dart';

/// Provides a stream of journal columns (lessons) for a given class.
final journalColumnsProvider = StreamProvider.autoDispose.family<
    List<DocumentSnapshot<Map<String, dynamic>>>, String>((ref, classId) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value([]);
  final repo = ref.watch(repositoryProvider);
  return repo.journalColumnsStream(classId).map((snapshot) => snapshot.docs);
});

/// Provides a stream of ALL student marks for a given class (teacher view).
final journalMarksProvider = StreamProvider.autoDispose.family<
    List<DocumentSnapshot<Map<String, dynamic>>>, String>((ref, classId) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value([]);
  final repo = ref.watch(repositoryProvider);
  return repo.journalMarksStream(classId).map((snapshot) => snapshot.docs);
});

/// Provides a stream of a single student's marks document (student view).
/// Uses a direct document `get` to satisfy Firestore rules for students.
/// The result is wrapped in a list to match the same shape as [journalMarksProvider].
final journalStudentMarksProvider = StreamProvider.autoDispose.family<
    List<DocumentSnapshot<Map<String, dynamic>>>,
    (String classId, String studentId)>((ref, params) {
  final (classId, studentId) = params;
  final repo = ref.watch(repositoryProvider);
  return repo.journalStudentMarkStream(classId, studentId).map((doc) {
    if (doc.exists) return [doc];
    return [];
  });
});

