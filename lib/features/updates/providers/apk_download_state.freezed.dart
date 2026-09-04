// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'apk_download_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ApkDownloadState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress) downloading,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installLaunched,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress)? downloading,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installLaunched,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress)? downloading,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installLaunched,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallLaunched value) installLaunched,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallLaunched value)? installLaunched,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallLaunched value)? installLaunched,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApkDownloadStateCopyWith<$Res> {
  factory $ApkDownloadStateCopyWith(
    ApkDownloadState value,
    $Res Function(ApkDownloadState) then,
  ) = _$ApkDownloadStateCopyWithImpl<$Res, ApkDownloadState>;
}

/// @nodoc
class _$ApkDownloadStateCopyWithImpl<$Res, $Val extends ApkDownloadState>
    implements $ApkDownloadStateCopyWith<$Res> {
  _$ApkDownloadStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$IdleImplCopyWith<$Res> {
  factory _$$IdleImplCopyWith(
    _$IdleImpl value,
    $Res Function(_$IdleImpl) then,
  ) = __$$IdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$IdleImplCopyWithImpl<$Res>
    extends _$ApkDownloadStateCopyWithImpl<$Res, _$IdleImpl>
    implements _$$IdleImplCopyWith<$Res> {
  __$$IdleImplCopyWithImpl(_$IdleImpl _value, $Res Function(_$IdleImpl) _then)
    : super(_value, _then);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$IdleImpl implements _Idle {
  const _$IdleImpl();

  @override
  String toString() {
    return 'ApkDownloadState.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$IdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress) downloading,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installLaunched,
    required TResult Function(String message) error,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress)? downloading,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installLaunched,
    TResult? Function(String message)? error,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress)? downloading,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installLaunched,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallLaunched value) installLaunched,
    required TResult Function(_Error value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallLaunched value)? installLaunched,
    TResult? Function(_Error value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallLaunched value)? installLaunched,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class _Idle implements ApkDownloadState {
  const factory _Idle() = _$IdleImpl;
}

/// @nodoc
abstract class _$$DownloadingImplCopyWith<$Res> {
  factory _$$DownloadingImplCopyWith(
    _$DownloadingImpl value,
    $Res Function(_$DownloadingImpl) then,
  ) = __$$DownloadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double progress});
}

/// @nodoc
class __$$DownloadingImplCopyWithImpl<$Res>
    extends _$ApkDownloadStateCopyWithImpl<$Res, _$DownloadingImpl>
    implements _$$DownloadingImplCopyWith<$Res> {
  __$$DownloadingImplCopyWithImpl(
    _$DownloadingImpl _value,
    $Res Function(_$DownloadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? progress = null}) {
    return _then(
      _$DownloadingImpl(
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$DownloadingImpl implements _Downloading {
  const _$DownloadingImpl({required this.progress});

  @override
  final double progress;

  @override
  String toString() {
    return 'ApkDownloadState.downloading(progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadingImpl &&
            (identical(other.progress, progress) ||
                other.progress == progress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, progress);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DownloadingImplCopyWith<_$DownloadingImpl> get copyWith =>
      __$$DownloadingImplCopyWithImpl<_$DownloadingImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress) downloading,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installLaunched,
    required TResult Function(String message) error,
  }) {
    return downloading(progress);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress)? downloading,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installLaunched,
    TResult? Function(String message)? error,
  }) {
    return downloading?.call(progress);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress)? downloading,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installLaunched,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (downloading != null) {
      return downloading(progress);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallLaunched value) installLaunched,
    required TResult Function(_Error value) error,
  }) {
    return downloading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallLaunched value)? installLaunched,
    TResult? Function(_Error value)? error,
  }) {
    return downloading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallLaunched value)? installLaunched,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (downloading != null) {
      return downloading(this);
    }
    return orElse();
  }
}

abstract class _Downloading implements ApkDownloadState {
  const factory _Downloading({required final double progress}) =
      _$DownloadingImpl;

  double get progress;

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DownloadingImplCopyWith<_$DownloadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PermissionNeededImplCopyWith<$Res> {
  factory _$$PermissionNeededImplCopyWith(
    _$PermissionNeededImpl value,
    $Res Function(_$PermissionNeededImpl) then,
  ) = __$$PermissionNeededImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filePath});
}

/// @nodoc
class __$$PermissionNeededImplCopyWithImpl<$Res>
    extends _$ApkDownloadStateCopyWithImpl<$Res, _$PermissionNeededImpl>
    implements _$$PermissionNeededImplCopyWith<$Res> {
  __$$PermissionNeededImplCopyWithImpl(
    _$PermissionNeededImpl _value,
    $Res Function(_$PermissionNeededImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filePath = null}) {
    return _then(
      _$PermissionNeededImpl(
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PermissionNeededImpl implements _PermissionNeeded {
  const _$PermissionNeededImpl({required this.filePath});

  @override
  final String filePath;

  @override
  String toString() {
    return 'ApkDownloadState.permissionNeeded(filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PermissionNeededImpl &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filePath);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PermissionNeededImplCopyWith<_$PermissionNeededImpl> get copyWith =>
      __$$PermissionNeededImplCopyWithImpl<_$PermissionNeededImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress) downloading,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installLaunched,
    required TResult Function(String message) error,
  }) {
    return permissionNeeded(filePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress)? downloading,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installLaunched,
    TResult? Function(String message)? error,
  }) {
    return permissionNeeded?.call(filePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress)? downloading,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installLaunched,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (permissionNeeded != null) {
      return permissionNeeded(filePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallLaunched value) installLaunched,
    required TResult Function(_Error value) error,
  }) {
    return permissionNeeded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallLaunched value)? installLaunched,
    TResult? Function(_Error value)? error,
  }) {
    return permissionNeeded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallLaunched value)? installLaunched,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (permissionNeeded != null) {
      return permissionNeeded(this);
    }
    return orElse();
  }
}

abstract class _PermissionNeeded implements ApkDownloadState {
  const factory _PermissionNeeded({required final String filePath}) =
      _$PermissionNeededImpl;

  String get filePath;

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PermissionNeededImplCopyWith<_$PermissionNeededImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InstallLaunchedImplCopyWith<$Res> {
  factory _$$InstallLaunchedImplCopyWith(
    _$InstallLaunchedImpl value,
    $Res Function(_$InstallLaunchedImpl) then,
  ) = __$$InstallLaunchedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filePath});
}

/// @nodoc
class __$$InstallLaunchedImplCopyWithImpl<$Res>
    extends _$ApkDownloadStateCopyWithImpl<$Res, _$InstallLaunchedImpl>
    implements _$$InstallLaunchedImplCopyWith<$Res> {
  __$$InstallLaunchedImplCopyWithImpl(
    _$InstallLaunchedImpl _value,
    $Res Function(_$InstallLaunchedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filePath = null}) {
    return _then(
      _$InstallLaunchedImpl(
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$InstallLaunchedImpl implements _InstallLaunched {
  const _$InstallLaunchedImpl({required this.filePath});

  @override
  final String filePath;

  @override
  String toString() {
    return 'ApkDownloadState.installLaunched(filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InstallLaunchedImpl &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filePath);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InstallLaunchedImplCopyWith<_$InstallLaunchedImpl> get copyWith =>
      __$$InstallLaunchedImplCopyWithImpl<_$InstallLaunchedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress) downloading,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installLaunched,
    required TResult Function(String message) error,
  }) {
    return installLaunched(filePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress)? downloading,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installLaunched,
    TResult? Function(String message)? error,
  }) {
    return installLaunched?.call(filePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress)? downloading,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installLaunched,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (installLaunched != null) {
      return installLaunched(filePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallLaunched value) installLaunched,
    required TResult Function(_Error value) error,
  }) {
    return installLaunched(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallLaunched value)? installLaunched,
    TResult? Function(_Error value)? error,
  }) {
    return installLaunched?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallLaunched value)? installLaunched,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (installLaunched != null) {
      return installLaunched(this);
    }
    return orElse();
  }
}

abstract class _InstallLaunched implements ApkDownloadState {
  const factory _InstallLaunched({required final String filePath}) =
      _$InstallLaunchedImpl;

  String get filePath;

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InstallLaunchedImplCopyWith<_$InstallLaunchedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
    _$ErrorImpl value,
    $Res Function(_$ErrorImpl) then,
  ) = __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$ApkDownloadStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'ApkDownloadState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress) downloading,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installLaunched,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress)? downloading,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installLaunched,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress)? downloading,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installLaunched,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallLaunched value) installLaunched,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallLaunched value)? installLaunched,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallLaunched value)? installLaunched,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements ApkDownloadState {
  const factory _Error({required final String message}) = _$ErrorImpl;

  String get message;

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
