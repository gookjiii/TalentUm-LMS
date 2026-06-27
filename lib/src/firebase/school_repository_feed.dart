import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'safe_firestore.dart';
import 'storage_provider.dart';
import 'package:school_world/src/firebase/push_notification_manager.dart';

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

    _sendClassNotification(classId, 'Новый пост', content);
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

  Stream<QuerySnapshot<Map<String, dynamic>>> postsForClass(
    String classId, {
    int? limit,
  }) {
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
