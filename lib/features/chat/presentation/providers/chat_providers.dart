import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_firebase_api/firebase_api.dart';
import 'package:sw_shared_models/shared_models.dart';
import 'package:school_world/src/providers/app_providers.dart';

import '../../domain/usecases/send_message_usecase.dart';

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final classMessagesProvider = StreamProvider.autoDispose.family<List<Message>, String>((
  ref,
  classId,
) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).watchClassMessages(classId);
});
