import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sw_shared_models/shared_models.dart';
import 'package:sw_validation/validation.dart';

import '../datasources/firestore_paths.dart';
import 'chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  const FirebaseChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Message>> watchClassMessages(String classId, {int limit = 30}) {
    return _firestore
        .collection(FirestorePaths.messages)
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> sendTextMessage({
    required String classId,
    required String senderId,
    required String content,
  }) async {
    final validation = MessageValidator.validateText(content);
    if (validation is Invalid) {
      throw ArgumentError(validation.message);
    }

    await _firestore.collection(FirestorePaths.messages).add({
      'classId': classId,
      'senderId': senderId,
      'type': MessageType.text.name,
      'content': content.trim(),
      'attachments': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
      'deleted': false,
    });
  }

  Message _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Message(
      id: doc.id,
      classId: data['classId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      type: MessageType.values.byName(data['type'] as String? ?? 'text'),
      content: data['content'] as String? ?? '',
      attachments: List<String>.from(data['attachments'] as List? ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      deleted: data['deleted'] as bool? ?? false,
    );
  }
}
