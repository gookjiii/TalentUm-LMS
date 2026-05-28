// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assignment_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AssignmentDto _$AssignmentDtoFromJson(Map<String, dynamic> json) {
  return _AssignmentDto.fromJson(json);
}

/// @nodoc
mixin _$AssignmentDto {
  String get id => throw _privateConstructorUsedError;
  String get classId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get dueDate => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;

  /// Serializes this AssignmentDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssignmentDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssignmentDtoCopyWith<AssignmentDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssignmentDtoCopyWith<$Res> {
  factory $AssignmentDtoCopyWith(
    AssignmentDto value,
    $Res Function(AssignmentDto) then,
  ) = _$AssignmentDtoCopyWithImpl<$Res, AssignmentDto>;
  @useResult
  $Res call({
    String id,
    String classId,
    String title,
    String description,
    DateTime dueDate,
    String createdBy,
  });
}

/// @nodoc
class _$AssignmentDtoCopyWithImpl<$Res, $Val extends AssignmentDto>
    implements $AssignmentDtoCopyWith<$Res> {
  _$AssignmentDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssignmentDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? classId = null,
    Object? title = null,
    Object? description = null,
    Object? dueDate = null,
    Object? createdBy = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            classId: null == classId
                ? _value.classId
                : classId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            dueDate: null == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssignmentDtoImplCopyWith<$Res>
    implements $AssignmentDtoCopyWith<$Res> {
  factory _$$AssignmentDtoImplCopyWith(
    _$AssignmentDtoImpl value,
    $Res Function(_$AssignmentDtoImpl) then,
  ) = __$$AssignmentDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String classId,
    String title,
    String description,
    DateTime dueDate,
    String createdBy,
  });
}

/// @nodoc
class __$$AssignmentDtoImplCopyWithImpl<$Res>
    extends _$AssignmentDtoCopyWithImpl<$Res, _$AssignmentDtoImpl>
    implements _$$AssignmentDtoImplCopyWith<$Res> {
  __$$AssignmentDtoImplCopyWithImpl(
    _$AssignmentDtoImpl _value,
    $Res Function(_$AssignmentDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssignmentDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? classId = null,
    Object? title = null,
    Object? description = null,
    Object? dueDate = null,
    Object? createdBy = null,
  }) {
    return _then(
      _$AssignmentDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        classId: null == classId
            ? _value.classId
            : classId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        dueDate: null == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssignmentDtoImpl implements _AssignmentDto {
  const _$AssignmentDtoImpl({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.createdBy,
  });

  factory _$AssignmentDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssignmentDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String classId;
  @override
  final String title;
  @override
  final String description;
  @override
  final DateTime dueDate;
  @override
  final String createdBy;

  @override
  String toString() {
    return 'AssignmentDto(id: $id, classId: $classId, title: $title, description: $description, dueDate: $dueDate, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssignmentDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    classId,
    title,
    description,
    dueDate,
    createdBy,
  );

  /// Create a copy of AssignmentDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssignmentDtoImplCopyWith<_$AssignmentDtoImpl> get copyWith =>
      __$$AssignmentDtoImplCopyWithImpl<_$AssignmentDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssignmentDtoImplToJson(this);
  }
}

abstract class _AssignmentDto implements AssignmentDto {
  const factory _AssignmentDto({
    required final String id,
    required final String classId,
    required final String title,
    required final String description,
    required final DateTime dueDate,
    required final String createdBy,
  }) = _$AssignmentDtoImpl;

  factory _AssignmentDto.fromJson(Map<String, dynamic> json) =
      _$AssignmentDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get classId;
  @override
  String get title;
  @override
  String get description;
  @override
  DateTime get dueDate;
  @override
  String get createdBy;

  /// Create a copy of AssignmentDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssignmentDtoImplCopyWith<_$AssignmentDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
