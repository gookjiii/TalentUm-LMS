import 'package:cloud_firestore/cloud_firestore.dart';
import 'safe_firestore.dart';

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

  Stream<QuerySnapshot<Map<String, dynamic>>> webinarsForClass(String classId) {
    return firestore
        .collection('webinars')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .safeSnapshots();
  }

  Future<void> deleteWebinar(String webinarId) async {
    await firestore.collection('webinars').doc(webinarId).delete();
  }
}
