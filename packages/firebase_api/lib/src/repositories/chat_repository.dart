import 'package:sw_shared_models/shared_models.dart';

abstract interface class ChatRepository {
  Stream<List<Message>> watchClassMessages(String classId, {int limit = 30});
  Future<void> sendTextMessage({
    required String classId,
    required String senderId,
    required String content,
  });
}
