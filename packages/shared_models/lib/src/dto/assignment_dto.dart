import 'package:freezed_annotation/freezed_annotation.dart';

part 'assignment_dto.freezed.dart';
part 'assignment_dto.g.dart';

@freezed
class AssignmentDto with _$AssignmentDto {
  const factory AssignmentDto({
    required String id,
    required String classId,
    required String title,
    required String description,
    required DateTime dueDate,
    required String createdBy,
  }) = _AssignmentDto;

  factory AssignmentDto.fromJson(Map<String, dynamic> json) => _$AssignmentDtoFromJson(json);
}
