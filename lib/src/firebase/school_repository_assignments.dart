import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'safe_firestore.dart';
import 'package:school_world/src/firebase/push_notification_manager.dart';

/// Homework grades are stored as percentages, from 0 through 100 inclusive.
/// Keeping the validation here makes every grading entry point consistent.
bool isValidSubmissionGrade(double grade) {
  return grade.isFinite && grade >= 0 && grade <= 100;
}

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
    final assignmentId = res.data['assignmentId'] as String;

    // Fire-and-forget push notification
    _sendClassNotification(classId, 'Новое задание: $title', description);

    return assignmentId;
  }

  Future<void> _sendClassNotification(
    String classId,
    String title,
    String body,
  ) async {
    try {
      final classDoc = await firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return;
      final data = classDoc.data()!;
      final List<dynamic> studentIds = data['studentIds'] ?? [];
      final List<dynamic> parentIds = data['parentIds'] ?? [];

      final targetUserIds = [
        ...studentIds,
        ...parentIds,
      ].map((id) => id.toString()).toSet().toList();

      if (targetUserIds.isEmpty) return;

      final className = data['name'] ?? '';
      final finalTitle = className.isNotEmpty ? '$className - $title' : title;

      await PushNotificationManager.sendPushNotification(
        userIds: targetUserIds,
        title: finalTitle,
        body: body,
        data: {'classId': classId},
      );
    } catch (e) {
      // ignore
    }
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

  Stream<QuerySnapshot<Map<String, dynamic>>> assignmentsForClasses(
    List<String> classIds, {
    int? limit,
  }) {
    if (classIds.isEmpty) return const Stream.empty();

    // Firestore whereIn supports up to 30 elements
    var query = firestore
        .collection('assignments')
        .where('classId', whereIn: classIds.take(30).toList());

    if (limit != null) {
      query = query.limit(limit);
    }
    return query.safeSnapshots();
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
    if (!isValidSubmissionGrade(grade)) {
      throw ArgumentError.value(grade, 'grade', 'must be between 0 and 100');
    }
    if (uid == null) {
      throw StateError('An authenticated teacher is required to grade work.');
    }

    // This used to invoke a non-existent `gradeSubmission` Cloud Function,
    // which made the grading dialog fail even for authorised teachers. The
    // Firestore rules already authorise the class teacher to update a
    // submission, so persist the review atomically in the active backend.
    await firestore.collection('submissions').doc(submissionId).update({
      'grade': grade,
      'feedback': feedback.trim(),
      'status': 'graded',
      'gradedBy': uid,
      'gradedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAssignment(String assignmentId) async {
    final submissions = await firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .get();
    var batch = firestore.batch();
    var count = 0;
    for (final submission in submissions.docs) {
      batch.delete(submission.reference);
      count++;
      if (count == 400) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    batch.delete(firestore.collection('assignments').doc(assignmentId));
    await batch.commit();
  }
}
