import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'safe_firestore.dart';

mixin SchoolRepositoryClasses {
  FirebaseFirestore get firestore;
  FirebaseFunctions get functions;
  String? get uid;

  Future<Map<String, dynamic>> joinClass(
    String classId, [
    String? inviteCode,
  ]) async {
    final res = await functions.httpsCallable('joinClass').call({
      'classId': classId,
      if (inviteCode != null) 'inviteCode': inviteCode,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<String> createClass({
    required String name,
    String? subject,
    String? inviteCode,
  }) async {
    if (uid == null) throw Exception('Not logged in');

    final batch = firestore.batch();
    final classRef = firestore.collection('classes').doc();
    final classId = classRef.id;
    final now = FieldValue.serverTimestamp();
    
    final classData = {
      'id': classId,
      'name': name,
      'teacherId': uid,
      'teacherIds': [uid],
      'createdAt': now,
      'updatedAt': now,
      'studentIds': [],
      'parentIds': [],
      'coverColor': '#6C5CE7',
    };
    if (subject != null) classData['subject'] = subject;
    if (inviteCode != null) classData['inviteCode'] = inviteCode;
    
    batch.set(classRef, classData);
    
    final roomRef = firestore.collection('rooms').doc(classId);
    batch.set(roomRef, {
      'id': classId,
      'type': 'class_main',
      'name': name,
      'createdAt': now,
      'updatedAt': now,
      'userIds': [uid],
      'metadata': {
        'classId': classId,
      }
    });

    final userRef = firestore.collection('users').doc(uid);
    batch.update(userRef, {
      'classIds': FieldValue.arrayUnion([classId])
    });

    await batch.commit();
    return classId;
  }

  Future<Map<String, dynamic>> validateInviteCode(String code) async {
    final res = await functions.httpsCallable('validateInviteCode').call({
      'code': code,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>?> getClassData(String classId) async {
    final doc = await firestore.collection('classes').doc(classId).get();
    return doc.data();
  }

  Stream<List<Map<String, dynamic>>> teacherClassesCached() {
    return firestore
        .collection('classes')
        .where(
          Filter.or(
            Filter('teacherId', isEqualTo: uid),
            Filter('teacherIds', arrayContains: uid),
          ),
        )
        .safeSnapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> studentClassesCached() {
    return firestore
        .collection('classes')
        .where('studentIds', arrayContains: uid)
        .safeSnapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
        );
  }

  Future<void> toggleClassAdmin({
    required String classId,
    required String userId,
    required bool isAdmin,
  }) async {
    await functions.httpsCallable('toggleClassAdmin').call({
      'classId': classId,
      'userId': userId,
      'isAdmin': isAdmin,
    });
  }

  Future<void> removeUserFromClass({
    required String classId,
    required String userId,
  }) async {
    await functions.httpsCallable('removeUserFromClass').call({
      'classId': classId,
      'userId': userId,
    });
  }

  Future<void> addStudentToClass({
    required String classId,
    required String userId,
  }) async {
    await firestore.collection('classes').doc(classId).update({
      'studentIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<List<Map<String, dynamic>>> searchUserByEmail(String email) async {
    final snap = await firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(5)
        .get();
    return snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<Map<String, dynamic>> joinClassAsGuest({
    required String classId,
    required String inviteCode,
    required String displayName,
  }) async {
    final res = await functions.httpsCallable('joinClassAsGuest').call({
      'classId': classId,
      'inviteCode': inviteCode,
      'displayName': displayName,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> allStudentAssignments(
    dynamic studentOrClasses,
  ) {
    if (studentOrClasses is List) {
      if (studentOrClasses.isEmpty) return Stream.empty();
      return firestore
          .collection('assignments')
          .where('classId', whereIn: studentOrClasses)
          .safeSnapshots();
    }
    return firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentOrClasses.toString())
        .safeSnapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> teacherClasses() {
    return firestore
        .collection('classes')
        .where('teacherId', isEqualTo: uid)
        .safeSnapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> parentClasses([
    List<String> childIds = const [],
  ]) {
    if (childIds.isEmpty) return Stream.empty();
    return firestore
        .collection('classes')
        .where('studentIds', arrayContainsAny: childIds)
        .safeSnapshots();
  }
}
