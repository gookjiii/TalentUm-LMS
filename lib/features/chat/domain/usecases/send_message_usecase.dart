import 'package:sw_firebase_api/firebase_api.dart';
import 'package:sw_validation/validation.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call({
    required String classId,
    required String senderId,
    required String content,
  }) async {
    final result = MessageValidator.validateText(content);
    if (result is Invalid) throw ArgumentError(result.message);
    await _repository.sendTextMessage(
      classId: classId,
      senderId: senderId,
      content: content,
    );
  }
}
