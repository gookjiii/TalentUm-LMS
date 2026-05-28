import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'safe_firestore.dart';


mixin SchoolRepositoryJournal {
  FirebaseAuth get auth;
  FirebaseFirestore get firestore;

  /// Stream of all journal columns (lessons) for a specific class, ordered by date ascending.
  Stream<QuerySnapshot<Map<String, dynamic>>> journalColumnsStream(String classId) {
    return firestore
        .collection('classes')
        .doc(classId)
        .collection('journal_columns')
        .orderBy('date')
        .safeSnapshots();
  }

  /// Stream of all journal marks for a specific class (teacher view).
  Stream<QuerySnapshot<Map<String, dynamic>>> journalMarksStream(String classId) {
    return firestore
        .collection('classes')
        .doc(classId)
        .collection('journal_marks')
        .safeSnapshots();
  }

  /// Stream of a single student's marks document (student view).
  /// Uses a direct document reference instead of a collection query to satisfy
  /// the Firestore rule: allow read if request.auth.uid == studentId.
  Stream<DocumentSnapshot<Map<String, dynamic>>> journalStudentMarkStream(
    String classId,
    String studentId,
  ) {
    return firestore
        .collection('classes')
        .doc(classId)
        .collection('journal_marks')
        .doc(studentId)
        .snapshots();
  }

  /// Adds a new lesson column to the journal.
  Future<void> addJournalColumn({
    required String classId,
    required DateTime date,
    required String topic,
    required String homework,
  }) async {
    await firestore
        .collection('classes')
        .doc(classId)
        .collection('journal_columns')
        .add({
      'date': Timestamp.fromDate(date),
      'topic': topic,
      'homework': homework,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates an existing lesson column in the journal.
  Future<void> updateJournalColumn({
    required String classId,
    required String columnId,
    required DateTime date,
    required String topic,
    required String homework,
  }) async {
    await firestore
        .collection('classes')
        .doc(classId)
        .collection('journal_columns')
        .doc(columnId)
        .update({
      'date': Timestamp.fromDate(date),
      'topic': topic,
      'homework': homework,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a lesson column from the journal.
  Future<void> deleteJournalColumn({
    required String classId,
    required String columnId,
  }) async {
    // Delete the column
    await firestore
        .collection('classes')
        .doc(classId)
        .collection('journal_columns')
        .doc(columnId)
        .delete();

    // Optionally, we could clean up marks that reference this columnId.
    // However, it's safer/faster to just ignore the mark on the client side
    // if the column doesn't exist anymore, or run a background function later.
  }

  /// Updates a specific mark for a student in a specific lesson.
  Future<void> updateStudentMark({
    required String classId,
    required String studentId,
    required String columnId,
    required String? mark,
  }) async {
    final docRef = firestore
        .collection('classes')
        .doc(classId)
        .collection('journal_marks')
        .doc(studentId);

    if (mark == null || mark.isEmpty) {
      // Remove the mark
      await docRef.set({
        'marks': {columnId: FieldValue.delete()},
      }, SetOptions(merge: true));
    } else {
      // Update/Set the mark
      await docRef.set({
        'studentId': studentId, // Make sure studentId is there for indexing/loading
        'marks': {columnId: mark},
      }, SetOptions(merge: true));
    }
  }
}
