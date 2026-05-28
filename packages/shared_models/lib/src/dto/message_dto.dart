import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_dto.freezed.dart';
part 'message_dto.g.dart';

@freezed
class MessageDto with _$MessageDto {
  const factory MessageDto({
    required String id,
    required String classId,
    required String senderId,
    required String type,
    required String content,
    @Default(<String>[]) List<String> attachments,
    required DateTime createdAt,
    DateTime? editedAt,
    @Default(false) bool deleted,
  }) = _MessageDto;

  factory MessageDto.fromJson(Map<String, dynamic> json) => _$MessageDtoFromJson(json);
}
