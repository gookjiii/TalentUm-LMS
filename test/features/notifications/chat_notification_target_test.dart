import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/firebase/push_notification_manager.dart';

void main() {
  test('parses a chat notification destination', () {
    final target = ChatNotificationTarget.fromData({
      'destination': 'chat',
      'classId': 'externat',
      'roomId': 'room-42',
      'topicId': 'homework',
      'messageId': 'message-9',
    });

    expect(target.isChat, isTrue);
    expect(target.classId, 'externat');
    expect(target.roomId, 'room-42');
    expect(target.topicId, 'homework');
    expect(target.messageId, 'message-9');
  });

  test('keeps old room-based chat payloads routable', () {
    final target = ChatNotificationTarget.fromData({
      'classId': 'class-7',
      'roomId': 'room-7',
    });

    expect(target.isChat, isTrue);
    expect(target.classId, 'class-7');
  });

  test('does not mistake a class-only assignment notification for chat', () {
    final target = ChatNotificationTarget.fromData({'classId': 'class-7'});

    expect(target.isChat, isFalse);
  });

  test('trims empty values from notification data', () {
    final target = ChatNotificationTarget.fromData({
      'destination': ' chat ',
      'classId': '   ',
      'roomId': '',
    });

    expect(target.classId, isNull);
    expect(target.roomId, isNull);
    expect(target.isChat, isTrue);
  });
}
