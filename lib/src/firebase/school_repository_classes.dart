import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'safe_firestore.dart';

mixin SchoolRepositoryClasses {
  FirebaseFirestore get firestore;
  FirebaseFunctions get functions;
  String? get uid;

  bool _isStaffRole(String? role) {
    final normalized = role?.trim().toLowerCase().replaceAll('_', '');
    return normalized == 'teacher' ||
        normalized == 'leadteacher' ||
        normalized == 'admin';
  }

  /// Returns only real student accounts, even when historical class data has
  /// accidentally placed a teacher in `studentIds`.
  Future<List<String>> studentIdsForJournal(String classId) async {
    final classSnapshot = await firestore
        .collection('classes')
        .doc(classId)
        .get();
    final rawIds = List<String>.from(classSnapshot.data()?['studentIds'] ?? []);
    if (rawIds.isEmpty) return const [];

    final studentIds = <String>[];
    for (var start = 0; start < rawIds.length; start += 30) {
      final end = (start + 30).clamp(0, rawIds.length);
      final chunk = rawIds.sublist(start, end);
      final users = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      final rolesById = <String, String?>{
        for (final user in users.docs) user.id: user.data()['role']?.toString(),
      };
      for (final id in chunk) {
        if (!_isStaffRole(rolesById[id])) studentIds.add(id);
      }
    }
    return studentIds;
  }

  /// Repairs a class after a staff account was accidentally placed in
  /// `studentIds`. The operation is idempotent and role-aware.
  Future<void> reconcileClassMembership(String classId) async {
    final classRef = firestore.collection('classes').doc(classId);
    final snapshot = await classRef.get();
    final data = snapshot.data();
    if (data == null) return;

    final rawStudents = List<String>.from(data['studentIds'] ?? []);
    final rawTeachers = List<String>.from(data['teacherIds'] ?? []);
    final allIds = <String>{
      ...rawStudents,
      ...rawTeachers,
      if (data['teacherId'] != null) data['teacherId'].toString(),
    };
    final ids = allIds.toList();
    final roles = <String, String?>{};
    for (var start = 0; start < ids.length; start += 30) {
      final end = (start + 30).clamp(0, ids.length);
      final users = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: ids.sublist(start, end))
          .get();
      for (final user in users.docs) {
        roles[user.id] = user.data()['role']?.toString();
      }
    }

    final students = <String>[];
    final teachers = <String>[];
    for (final id in rawStudents) {
      // A known staff account found only in studentIds is removed from this
      // class instead of being silently promoted to its teacher roster.
      if (!_isStaffRole(roles[id]) && !students.contains(id)) students.add(id);
    }
    for (final id in rawTeachers) {
      if (_isStaffRole(roles[id]) || roles[id] == null) {
        if (!teachers.contains(id)) teachers.add(id);
      } else if (!students.contains(id)) {
        students.add(id);
      }
    }
    final teacherId = data['teacherId']?.toString();
    if (teacherId != null && !teachers.contains(teacherId))
      teachers.add(teacherId);

    if (!_sameIds(rawStudents, students) || !_sameIds(rawTeachers, teachers)) {
      await classRef.update({
        'studentIds': students,
        'teacherIds': teachers,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  bool _sameIds(List<String> a, List<String> b) {
    return a.length == b.length &&
        a.toSet().length == b.toSet().length &&
        a.toSet().containsAll(b);
  }

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
    String? coverColor,
    String? avatarUrl,
  }) async {
    if (uid == null) throw Exception('Not logged in');
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) throw Exception('Class name is required');

    final batch = firestore.batch();
    final classRef = firestore.collection('classes').doc();
    final classId = classRef.id;
    final now = FieldValue.serverTimestamp();

    final classData = {
      'id': classId,
      'name': normalizedName,
      'teacherId': uid,
      'teacherIds': [uid],
      'createdAt': now,
      'updatedAt': now,
      'studentIds': [],
      'parentIds': [],
      'coverColor': coverColor ?? '#6C5CE7',
    };
    if (subject != null) classData['subject'] = subject;
    if (inviteCode != null) classData['inviteCode'] = inviteCode;
    if (avatarUrl != null) classData['avatarUrl'] = avatarUrl;

    batch.set(classRef, classData);

    final roomRef = firestore.collection('rooms').doc(classId);
    batch.set(roomRef, {
      'id': classId,
      'type': 'class_main',
      'name': normalizedName,
      'createdAt': now,
      'updatedAt': now,
      'userIds': [uid],
      'metadata': {'classId': classId},
    });

    final userRef = firestore.collection('users').doc(uid);
    batch.update(userRef, {
      'classIds': FieldValue.arrayUnion([classId]),
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
    if (uid == null) return const Stream.empty();
    return firestore
        .collection('classes')
        .where(
          Filter.or(
            Filter('teacherId', isEqualTo: uid),
            Filter('teacherIds', arrayContains: uid),
          ),
        )
        .safeSnapshots()
        .asyncMap((snap) async {
          final docsMap = <String, Map<String, dynamic>>{
            for (final doc in snap.docs) doc.id: {...doc.data(), 'id': doc.id},
          };

          try {
            final userSnap = await firestore
                .collection('users')
                .doc(uid!)
                .get();
            final userClassIds = List<String>.from(
              userSnap.data()?['classIds'] ?? [],
            );
            final missingIds = userClassIds
                .where((id) => !docsMap.containsKey(id))
                .take(20);

            for (final classId in missingIds) {
              final cDoc = await firestore
                  .collection('classes')
                  .doc(classId)
                  .get();
              if (cDoc.exists && cDoc.data() != null) {
                docsMap[classId] = {...cDoc.data()!, 'id': cDoc.id};
              }
            }
          } catch (e) {
            debugPrint('Error fetching additional teacher user classes: $e');
          }

          return docsMap.values.toList();
        });
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
    try {
      final classRef = firestore.collection('classes').doc(classId);
      final classSnap = await classRef.get();
      final classData = classSnap.data();
      final chatRoomId = classData?['chatRoomId'] as String?;

      final batch = firestore.batch();
      batch.update(classRef, {
        'studentIds': FieldValue.arrayRemove([userId]),
        'teacherIds': FieldValue.arrayRemove([userId]),
      });

      final roomRef = firestore.collection('rooms').doc(classId);
      batch.set(roomRef, {
        'userIds': FieldValue.arrayRemove([userId]),
      }, SetOptions(merge: true));

      if (chatRoomId != null &&
          chatRoomId.isNotEmpty &&
          chatRoomId != classId) {
        final customRoomRef = firestore.collection('rooms').doc(chatRoomId);
        batch.set(customRoomRef, {
          'userIds': FieldValue.arrayRemove([userId]),
        }, SetOptions(merge: true));
      }

      final userRef = firestore.collection('users').doc(userId);
      batch.set(userRef, {
        'classIds': FieldValue.arrayRemove([classId]),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Direct Firestore removeUserFromClass error, fallback to function: $e',
      );
      await functions.httpsCallable('removeUserFromClass').call({
        'classId': classId,
        'userId': userId,
      });
    }
  }

  Future<void> addStudentToClass({
    required String classId,
    required String userId,
  }) async {
    final classRef = firestore.collection('classes').doc(classId);
    final userRef = firestore.collection('users').doc(userId);
    final classSnap = await classRef.get();
    if (!classSnap.exists) throw Exception('Class not found');
    final userSnap = await userRef.get();
    final role = userSnap.data()?['role']?.toString();

    final batch = firestore.batch();
    if (_isStaffRole(role)) {
      batch.update(classRef, {
        'teacherIds': FieldValue.arrayUnion([userId]),
        'studentIds': FieldValue.arrayRemove([userId]),
      });
    } else {
      batch.update(classRef, {
        'studentIds': FieldValue.arrayUnion([userId]),
        'teacherIds': FieldValue.arrayRemove([userId]),
      });
    }

    final roomRef = firestore.collection('rooms').doc(classId);
    batch.set(roomRef, {
      'userIds': FieldValue.arrayUnion([userId]),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'classIds': FieldValue.arrayUnion([classId]),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> assignTeacherToClass({
    required String classId,
    required String teacherId,
  }) async {
    final classRef = firestore.collection('classes').doc(classId);
    final classSnap = await classRef.get();
    final data = classSnap.data();
    if (data == null) throw Exception('Class not found');
    final chatRoomId = data['chatRoomId'] as String?;

    final batch = firestore.batch();
    batch.update(classRef, {
      'teacherId': teacherId,
      'teacherIds': FieldValue.arrayUnion([teacherId]),
      'studentIds': FieldValue.arrayRemove([teacherId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final roomRef = firestore.collection('rooms').doc(classId);
    batch.set(roomRef, {
      'userIds': FieldValue.arrayUnion([teacherId]),
    }, SetOptions(merge: true));

    if (chatRoomId != null && chatRoomId.isNotEmpty && chatRoomId != classId) {
      final customRoomRef = firestore.collection('rooms').doc(chatRoomId);
      batch.set(customRoomRef, {
        'userIds': FieldValue.arrayUnion([teacherId]),
      }, SetOptions(merge: true));
    }

    batch.set(firestore.collection('users').doc(teacherId), {
      'classIds': FieldValue.arrayUnion([classId]),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> updateClassAvatar({
    required String classId,
    required String avatarUrl,
  }) async {
    await firestore.collection('classes').doc(classId).update({
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateClassName({
    required String classId,
    required String name,
  }) async {
    final batch = firestore.batch();
    batch.update(firestore.collection('classes').doc(classId), {
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(firestore.collection('rooms').doc(classId), {
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> regenerateInviteCode(String classId) async {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code = List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    await firestore.collection('classes').doc(classId).update({
      'inviteCode': code,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteClass(String classId) async {
    var batch = firestore.batch();
    var operationCount = 0;

    Future<void> flush() async {
      if (operationCount == 0) return;
      await batch.commit();
      batch = firestore.batch();
      operationCount = 0;
    }

    Future<void> enqueueDelete(DocumentReference<Object?> ref) async {
      batch.delete(ref);
      operationCount++;
      if (operationCount >= 400) await flush();
    }

    Future<void> enqueueMembershipRemoval(
      DocumentReference<Object?> ref,
    ) async {
      batch.set(ref, {
        'classIds': FieldValue.arrayRemove([classId]),
      }, SetOptions(merge: true));
      operationCount++;
      if (operationCount >= 400) await flush();
    }

    for (final collection in [
      'assignments',
      'grades',
      'library_materials',
      'posts',
      'schedules',
      'schedule_overrides',
      'webinars',
    ]) {
      final snapshot = await firestore
          .collection(collection)
          .where('classId', isEqualTo: classId)
          .get();
      for (final doc in snapshot.docs) {
        await enqueueDelete(doc.reference);
      }
    }

    final roomRef = firestore.collection('rooms').doc(classId);
    for (final subcollection in ['messages', 'polls', 'topics']) {
      final snapshot = await roomRef.collection(subcollection).get();
      for (final doc in snapshot.docs) {
        await enqueueDelete(doc.reference);
      }
    }
    await enqueueDelete(roomRef);

    final members = await firestore
        .collection('users')
        .where('classIds', arrayContains: classId)
        .get();
    for (final doc in members.docs) {
      final role = doc.data()['role']?.toString();
      if (doc.id == uid || role == 'student') {
        await enqueueMembershipRemoval(doc.reference);
      }
    }

    // Keep the class until the end so permission checks remain valid while
    // its linked documents and memberships are cleaned up.
    await enqueueDelete(firestore.collection('classes').doc(classId));
    await flush();
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
