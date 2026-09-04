// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_release.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppRelease _$AppReleaseFromJson(Map<String, dynamic> json) {
  return _AppRelease.fromJson(json);
}

/// @nodoc
mixin _$AppRelease {
  String get versionName => throw _privateConstructorUsedError;
  int get versionCode => throw _privateConstructorUsedError;
  String get releaseNotes => throw _privateConstructorUsedError;
  String get apkFileName => throw _privateConstructorUsedError;
  String get releasedAt => throw _privateConstructorUsedError;

  /// Serializes this AppRelease to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppRelease
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppReleaseCopyWith<AppRelease> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppReleaseCopyWith<$Res> {
  factory $AppReleaseCopyWith(
    AppRelease value,
    $Res Function(AppRelease) then,
  ) = _$AppReleaseCopyWithImpl<$Res, AppRelease>;
  @useResult
  $Res call({
    String versionName,
    int versionCode,
    String releaseNotes,
    String apkFileName,
    String releasedAt,
  });
}

/// @nodoc
class _$AppReleaseCopyWithImpl<$Res, $Val extends AppRelease>
    implements $AppReleaseCopyWith<$Res> {
  _$AppReleaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppRelease
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? versionName = null,
    Object? versionCode = null,
    Object? releaseNotes = null,
    Object? apkFileName = null,
    Object? releasedAt = null,
  }) {
    return _then(
      _value.copyWith(
            versionName: null == versionName
                ? _value.versionName
                : versionName // ignore: cast_nullable_to_non_nullable
                      as String,
            versionCode: null == versionCode
                ? _value.versionCode
                : versionCode // ignore: cast_nullable_to_non_nullable
                      as int,
            releaseNotes: null == releaseNotes
                ? _value.releaseNotes
                : releaseNotes // ignore: cast_nullable_to_non_nullable
                      as String,
            apkFileName: null == apkFileName
                ? _value.apkFileName
                : apkFileName // ignore: cast_nullable_to_non_nullable
                      as String,
            releasedAt: null == releasedAt
                ? _value.releasedAt
                : releasedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppReleaseImplCopyWith<$Res>
    implements $AppReleaseCopyWith<$Res> {
  factory _$$AppReleaseImplCopyWith(
    _$AppReleaseImpl value,
    $Res Function(_$AppReleaseImpl) then,
  ) = __$$AppReleaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String versionName,
    int versionCode,
    String releaseNotes,
    String apkFileName,
    String releasedAt,
  });
}

/// @nodoc
class __$$AppReleaseImplCopyWithImpl<$Res>
    extends _$AppReleaseCopyWithImpl<$Res, _$AppReleaseImpl>
    implements _$$AppReleaseImplCopyWith<$Res> {
  __$$AppReleaseImplCopyWithImpl(
    _$AppReleaseImpl _value,
    $Res Function(_$AppReleaseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppRelease
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? versionName = null,
    Object? versionCode = null,
    Object? releaseNotes = null,
    Object? apkFileName = null,
    Object? releasedAt = null,
  }) {
    return _then(
      _$AppReleaseImpl(
        versionName: null == versionName
            ? _value.versionName
            : versionName // ignore: cast_nullable_to_non_nullable
                  as String,
        versionCode: null == versionCode
            ? _value.versionCode
            : versionCode // ignore: cast_nullable_to_non_nullable
                  as int,
        releaseNotes: null == releaseNotes
            ? _value.releaseNotes
            : releaseNotes // ignore: cast_nullable_to_non_nullable
                  as String,
        apkFileName: null == apkFileName
            ? _value.apkFileName
            : apkFileName // ignore: cast_nullable_to_non_nullable
                  as String,
        releasedAt: null == releasedAt
            ? _value.releasedAt
            : releasedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppReleaseImpl implements _AppRelease {
  const _$AppReleaseImpl({
    required this.versionName,
    required this.versionCode,
    required this.releaseNotes,
    required this.apkFileName,
    required this.releasedAt,
  });

  factory _$AppReleaseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppReleaseImplFromJson(json);

  @override
  final String versionName;
  @override
  final int versionCode;
  @override
  final String releaseNotes;
  @override
  final String apkFileName;
  @override
  final String releasedAt;

  @override
  String toString() {
    return 'AppRelease(versionName: $versionName, versionCode: $versionCode, releaseNotes: $releaseNotes, apkFileName: $apkFileName, releasedAt: $releasedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppReleaseImpl &&
            (identical(other.versionName, versionName) ||
                other.versionName == versionName) &&
            (identical(other.versionCode, versionCode) ||
                other.versionCode == versionCode) &&
            (identical(other.releaseNotes, releaseNotes) ||
                other.releaseNotes == releaseNotes) &&
            (identical(other.apkFileName, apkFileName) ||
                other.apkFileName == apkFileName) &&
            (identical(other.releasedAt, releasedAt) ||
                other.releasedAt == releasedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    versionName,
    versionCode,
    releaseNotes,
    apkFileName,
    releasedAt,
  );

  /// Create a copy of AppRelease
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppReleaseImplCopyWith<_$AppReleaseImpl> get copyWith =>
      __$$AppReleaseImplCopyWithImpl<_$AppReleaseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppReleaseImplToJson(this);
  }
}

abstract class _AppRelease implements AppRelease {
  const factory _AppRelease({
    required final String versionName,
    required final int versionCode,
    required final String releaseNotes,
    required final String apkFileName,
    required final String releasedAt,
  }) = _$AppReleaseImpl;

  factory _AppRelease.fromJson(Map<String, dynamic> json) =
      _$AppReleaseImpl.fromJson;

  @override
  String get versionName;
  @override
  int get versionCode;
  @override
  String get releaseNotes;
  @override
  String get apkFileName;
  @override
  String get releasedAt;

  /// Create a copy of AppRelease
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppReleaseImplCopyWith<_$AppReleaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
