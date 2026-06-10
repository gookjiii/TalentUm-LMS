import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

mixin SchoolRepositoryAdmin {
  FirebaseFirestore get firestore;
  FirebaseAuth get auth;

  Future<void> resetSystem() async {
    // 1. Top-level collections
    final topCollections = [
      'classes',
      'assignments',
      'submissions',
      'grades',
      'notifications',
      'rooms',
      'library_materials',
      'posts',
      'teacher_requests',
      'journal_columns',
      'journal_marks',
      'schedules',
      'schedule_overrides',
      'webinars',
    ];

    for (final name in topCollections) {
      await _deleteCollection(name);
    }

    // 2. Collection groups (for subcollections)
    final groupCollections = ['messages', 'tokens'];

    for (final name in groupCollections) {
      await _deleteCollectionGroup(name);
    }

    // 3. Reset users (remove from classes, etc.)
    final usersSnap = await firestore.collection('users').get();
    var batch = firestore.batch();
    int count = 0;

    for (final doc in usersSnap.docs) {
      batch.update(doc.reference, {
        'classIds': [],
        'managedClassIds': [],
        'streak': 0,
        'lastActivity': null,
      });
      count++;
      if (count >= 500) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  Future<void> _deleteCollection(String collectionName) async {
    final snap = await firestore.collection(collectionName).get();
    var batch = firestore.batch();
    int count = 0;

    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 500) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  Future<void> _deleteCollectionGroup(String collectionName) async {
    final snap = await firestore.collectionGroup(collectionName).get();
    var batch = firestore.batch();
    int count = 0;

    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 500) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }
}
