// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssignmentDtoImpl _$$AssignmentDtoImplFromJson(Map<String, dynamic> json) =>
    _$AssignmentDtoImpl(
      id: json['id'] as String,
      classId: json['classId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      createdBy: json['createdBy'] as String,
    );

Map<String, dynamic> _$$AssignmentDtoImplToJson(_$AssignmentDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'classId': instance.classId,
      'title': instance.title,
      'description': instance.description,
      'dueDate': instance.dueDate.toIso8601String(),
      'createdBy': instance.createdBy,
    };
