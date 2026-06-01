import 'package:cloud_firestore/cloud_firestore.dart';
import 'safe_firestore.dart';
import 'storage_provider.dart';

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
    String classId, {
    int? limit,
  }) {
    var query = firestore
        .collection('library_materials')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.safeSnapshots();
  }

  Future<void> deleteLibraryMaterial(String materialId) async {
    final docRef = firestore.collection('library_materials').doc(materialId);
    final doc = await docRef.get();
    if (doc.exists) {
      final fileUrl = doc.data()?['fileUrl'] as String?;
      if (fileUrl != null && fileUrl.isNotEmpty) {
        try {
          await CloudinaryStorageProvider.libraryProvider().deleteFile(fileUrl);
        } catch (e) {
          // Ignore file deletion errors to allow doc deletion
        }
      }
      await docRef.delete();
    }
  }
}
