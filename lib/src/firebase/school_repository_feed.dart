import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'safe_firestore.dart';
import 'storage_provider.dart';

mixin SchoolRepositoryFeed {
  FirebaseFirestore get firestore;
  FirebaseFunctions get functions;
  String? get uid;

  Future<void> createPost({
    required String classId,
    required String content,
    bool pinned = false,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    await functions.httpsCallable('createPost').call({
      'classId': classId,
      'content': content,
      'pinned': pinned,
      'attachments': attachments,
    });
  }

  Future<void> setPostPinned(String postId, bool pinned) async {
    await firestore.collection('posts').doc(postId).update({'pinned': pinned});
  }

  Future<void> deletePost(String postId) async {
    final docRef = firestore.collection('posts').doc(postId);
    final doc = await docRef.get();
    if (doc.exists) {
      final attachments = doc.data()?['attachments'] as List<dynamic>?;
      if (attachments != null) {
        for (var att in attachments) {
          if (att is Map<String, dynamic>) {
            final url = att['url'] as String?;
            if (url != null && url.isNotEmpty) {
              try {
                await CloudinaryStorageProvider.chatProvider().deleteFile(url);
              } catch (e) {
                // Ignore file deletion errors to allow doc deletion
              }
            }
          }
        }
      }
      await docRef.delete();
    }
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    final id = uid;
    if (id == null) return;
    await firestore.collection('posts').doc(postId).update({
      'likes': isLiked
          ? FieldValue.arrayRemove([id])
          : FieldValue.arrayUnion([id]),
    });
  }

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final id = uid;
    if (id == null) return;
    await firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([
        {'authorId': id, 'content': content, 'createdAt': Timestamp.now()},
      ]),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> postsForClass(String classId, {int? limit}) {
    var query = firestore
        .collection('posts')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.safeSnapshots();
  }
}
