import 'package:cloud_firestore/cloud_firestore.dart';
import 'safe_firestore.dart';

mixin SchoolRepositoryLibrary {
  FirebaseFirestore get firestore;

  Future<void> addLibraryMaterial({
    required String classId,
    required String title,
    String? description,
    required String fileUrl,
    String? fileName,
    String? lessonId,
  }) async {
    await firestore.collection('library_materials').add({
      'classId': classId,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'lessonId': lessonId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> libraryMaterialsForClass(
    String classId,
  ) {
    return firestore
        .collection('library_materials')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .safeSnapshots();
  }

  Future<void> deleteLibraryMaterial(String materialId) async {
    await firestore.collection('library_materials').doc(materialId).delete();
  }
}
