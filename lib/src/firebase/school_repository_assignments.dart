import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'safe_firestore.dart';

mixin SchoolRepositoryAssignments {
  FirebaseFirestore get firestore;
  FirebaseFunctions get functions;
  String? get uid;

  Future<String> createAssignment({
    required String classId,
    required String title,
    required String description,
    required DateTime dueDate,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final res = await functions.httpsCallable('createAssignment').call({
      'classId': classId,
      'title': title,
      'description': description,
      'dueDateMs': dueDate.millisecondsSinceEpoch,
      'attachments': attachments,
    });
    return res.data['assignmentId'] as String;
  }

  Future<String> createSubmission({
    required String assignmentId,
    required String studentId,
    String? content,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final res = await functions.httpsCallable('createSubmission').call({
      'assignmentId': assignmentId,
      'content': content,
      'attachments': attachments,
    });
    return res.data['submissionId'] as String;
  }

  Future<void> updateSubmissionAttachments({
    required String submissionId,
    required List<Map<String, dynamic>> attachments,
  }) async {
    await functions.httpsCallable('updateSubmissionAttachments').call({
      'submissionId': submissionId,
      'attachments': attachments,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> assignmentsForClass(
    String classId, {
    int? limit,
  }) {
    var query = firestore
        .collection('assignments')
        .where('classId', isEqualTo: classId);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.safeSnapshots();
  }

  Future<void> gradeSubmission({
    required String submissionId,
    required double grade,
    required String feedback,
  }) async {
    await functions.httpsCallable('gradeSubmission').call({
      'submissionId': submissionId,
      'grade': grade,
      'feedback': feedback,
    });
  }
}
