import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseChatController controller;
  const roomId = 'test-room-id';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    controller = FirebaseChatController(
      firestore: firestore,
      roomId: roomId,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('FirebaseChatController Tests', () {
    test('sendText adds message to Firestore', () async {
      await controller.sendText('user1', 'Hello');

      final messages = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .get();

      expect(messages.docs.length, 1);
      expect(messages.docs.first.data()['text'], 'Hello');
      expect(messages.docs.first.data()['authorId'], 'user1');
    });

    test('editText updates message in Firestore', () async {
      final ref = firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc('msg1');
      
      await ref.set({
        'type': 'text',
        'authorId': 'user1',
        'text': 'Old',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      await controller.editText('msg1', 'New');

      final doc = await ref.get();
      expect(doc.data()?['text'], 'New');
      expect(doc.data()?['metadata']?['isEdited'], true);
    });

    test('deleteMessage performs soft delete', () async {
      final ref = firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc('msg1');
      
      await ref.set({
        'type': 'text',
        'authorId': 'user1',
        'text': 'To be deleted',
      });

      await controller.deleteMessage('msg1');

      final doc = await ref.get();
      expect(doc.data()?['text'], 'Сообщение удалено');
      expect(doc.data()?['metadata']?['isDeleted'], true);
    });

    test('setTypingStatus manages typing collection', () async {
      await controller.setTypingStatus('user1', true);
      
      var typing = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('typing')
          .get();
      expect(typing.docs.length, 1);
      expect(typing.docs.first.id, 'user1');

      await controller.setTypingStatus('user1', false);
      typing = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('typing')
          .get();
      expect(typing.docs.length, 0);
    });
  });
}