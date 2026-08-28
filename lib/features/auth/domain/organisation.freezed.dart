// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organisation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Organisation _$OrganisationFromJson(Map<String, dynamic> json) {
  return _Organisation.fromJson(json);
}

/// @nodoc
mixin _$Organisation {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this Organisation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Organisation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrganisationCopyWith<Organisation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrganisationCopyWith<$Res> {
  factory $OrganisationCopyWith(
    Organisation value,
    $Res Function(Organisation) then,
  ) = _$OrganisationCopyWithImpl<$Res, Organisation>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$OrganisationCopyWithImpl<$Res, $Val extends Organisation>
    implements $OrganisationCopyWith<$Res> {
  _$OrganisationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Organisation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrganisationImplCopyWith<$Res>
    implements $OrganisationCopyWith<$Res> {
  factory _$$OrganisationImplCopyWith(
    _$OrganisationImpl value,
    $Res Function(_$OrganisationImpl) then,
  ) = __$$OrganisationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$OrganisationImplCopyWithImpl<$Res>
    extends _$OrganisationCopyWithImpl<$Res, _$OrganisationImpl>
    implements _$$OrganisationImplCopyWith<$Res> {
  __$$OrganisationImplCopyWithImpl(
    _$OrganisationImpl _value,
    $Res Function(_$OrganisationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Organisation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _$OrganisationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrganisationImpl implements _Organisation {
  const _$OrganisationImpl({required this.id, required this.name});

  factory _$OrganisationImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrganisationImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'Organisation(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrganisationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of Organisation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrganisationImplCopyWith<_$OrganisationImpl> get copyWith =>
      __$$OrganisationImplCopyWithImpl<_$OrganisationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrganisationImplToJson(this);
  }
}

abstract class _Organisation implements Organisation {
  const factory _Organisation({
    required final String id,
    required final String name,
  }) = _$OrganisationImpl;

  factory _Organisation.fromJson(Map<String, dynamic> json) =
      _$OrganisationImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Create a copy of Organisation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrganisationImplCopyWith<_$OrganisationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
