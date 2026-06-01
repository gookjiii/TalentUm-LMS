import 'package:cloud_firestore/cloud_firestore.dart';
import 'safe_firestore.dart';
import 'storage_provider.dart';

mixin SchoolRepositoryWebinars {
  FirebaseFirestore get firestore;

  Future<void> addWebinar({
    required String classId,
    required String title,
    String? description,
    required String videoUrl,
    String? lessonId,
  }) async {
    await firestore.collection('webinars').add({
      'classId': classId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'lessonId': lessonId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> webinarsForClass(String classId, {int? limit}) {
    var query = firestore
        .collection('webinars')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.safeSnapshots();
  }

  Future<void> deleteWebinar(String webinarId) async {
    final docRef = firestore.collection('webinars').doc(webinarId);
    final doc = await docRef.get();
    if (doc.exists) {
      final videoUrl = doc.data()?['videoUrl'] as String?;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        try {
          await CloudinaryStorageProvider.libraryProvider().deleteFile(videoUrl);
        } catch (e) {
          // Ignore file deletion errors to allow doc deletion
        }
      }
      await docRef.delete();
    }
  }
}
