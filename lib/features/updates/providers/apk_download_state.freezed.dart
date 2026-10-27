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
    required TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )
    downloading,
    required TResult Function(String filePath) downloaded,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installerOpened,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult? Function(String filePath)? downloaded,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installerOpened,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult Function(String filePath)? downloaded,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installerOpened,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_Downloaded value) downloaded,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallerOpened value) installerOpened,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_Downloaded value)? downloaded,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallerOpened value)? installerOpened,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_Downloaded value)? downloaded,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallerOpened value)? installerOpened,
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
    required TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )
    downloading,
    required TResult Function(String filePath) downloaded,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installerOpened,
    required TResult Function(String message) error,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult? Function(String filePath)? downloaded,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installerOpened,
    TResult? Function(String message)? error,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult Function(String filePath)? downloaded,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installerOpened,
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
    required TResult Function(_Downloaded value) downloaded,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallerOpened value) installerOpened,
    required TResult Function(_Error value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_Downloaded value)? downloaded,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallerOpened value)? installerOpened,
    TResult? Function(_Error value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_Downloaded value)? downloaded,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallerOpened value)? installerOpened,
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
  $Res call({
    double progress,
    int bytesReceived,
    int totalBytes,
    double bytesPerSecond,
  });
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
  $Res call({
    Object? progress = null,
    Object? bytesReceived = null,
    Object? totalBytes = null,
    Object? bytesPerSecond = null,
  }) {
    return _then(
      _$DownloadingImpl(
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        bytesReceived: null == bytesReceived
            ? _value.bytesReceived
            : bytesReceived // ignore: cast_nullable_to_non_nullable
                  as int,
        totalBytes: null == totalBytes
            ? _value.totalBytes
            : totalBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        bytesPerSecond: null == bytesPerSecond
            ? _value.bytesPerSecond
            : bytesPerSecond // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$DownloadingImpl implements _Downloading {
  const _$DownloadingImpl({
    required this.progress,
    required this.bytesReceived,
    required this.totalBytes,
    required this.bytesPerSecond,
  });

  @override
  final double progress;
  @override
  final int bytesReceived;
  @override
  final int totalBytes;
  @override
  final double bytesPerSecond;

  @override
  String toString() {
    return 'ApkDownloadState.downloading(progress: $progress, bytesReceived: $bytesReceived, totalBytes: $totalBytes, bytesPerSecond: $bytesPerSecond)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadingImpl &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.bytesReceived, bytesReceived) ||
                other.bytesReceived == bytesReceived) &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.bytesPerSecond, bytesPerSecond) ||
                other.bytesPerSecond == bytesPerSecond));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    progress,
    bytesReceived,
    totalBytes,
    bytesPerSecond,
  );

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
    required TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )
    downloading,
    required TResult Function(String filePath) downloaded,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installerOpened,
    required TResult Function(String message) error,
  }) {
    return downloading(progress, bytesReceived, totalBytes, bytesPerSecond);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult? Function(String filePath)? downloaded,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installerOpened,
    TResult? Function(String message)? error,
  }) {
    return downloading?.call(
      progress,
      bytesReceived,
      totalBytes,
      bytesPerSecond,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult Function(String filePath)? downloaded,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installerOpened,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (downloading != null) {
      return downloading(progress, bytesReceived, totalBytes, bytesPerSecond);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_Downloaded value) downloaded,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallerOpened value) installerOpened,
    required TResult Function(_Error value) error,
  }) {
    return downloading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_Downloaded value)? downloaded,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallerOpened value)? installerOpened,
    TResult? Function(_Error value)? error,
  }) {
    return downloading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_Downloaded value)? downloaded,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallerOpened value)? installerOpened,
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
  const factory _Downloading({
    required final double progress,
    required final int bytesReceived,
    required final int totalBytes,
    required final double bytesPerSecond,
  }) = _$DownloadingImpl;

  double get progress;
  int get bytesReceived;
  int get totalBytes;
  double get bytesPerSecond;

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DownloadingImplCopyWith<_$DownloadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DownloadedImplCopyWith<$Res> {
  factory _$$DownloadedImplCopyWith(
    _$DownloadedImpl value,
    $Res Function(_$DownloadedImpl) then,
  ) = __$$DownloadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filePath});
}

/// @nodoc
class __$$DownloadedImplCopyWithImpl<$Res>
    extends _$ApkDownloadStateCopyWithImpl<$Res, _$DownloadedImpl>
    implements _$$DownloadedImplCopyWith<$Res> {
  __$$DownloadedImplCopyWithImpl(
    _$DownloadedImpl _value,
    $Res Function(_$DownloadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filePath = null}) {
    return _then(
      _$DownloadedImpl(
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DownloadedImpl implements _Downloaded {
  const _$DownloadedImpl({required this.filePath});

  @override
  final String filePath;

  @override
  String toString() {
    return 'ApkDownloadState.downloaded(filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadedImpl &&
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
  _$$DownloadedImplCopyWith<_$DownloadedImpl> get copyWith =>
      __$$DownloadedImplCopyWithImpl<_$DownloadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )
    downloading,
    required TResult Function(String filePath) downloaded,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installerOpened,
    required TResult Function(String message) error,
  }) {
    return downloaded(filePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult? Function(String filePath)? downloaded,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installerOpened,
    TResult? Function(String message)? error,
  }) {
    return downloaded?.call(filePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult Function(String filePath)? downloaded,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installerOpened,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (downloaded != null) {
      return downloaded(filePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_Downloaded value) downloaded,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallerOpened value) installerOpened,
    required TResult Function(_Error value) error,
  }) {
    return downloaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_Downloaded value)? downloaded,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallerOpened value)? installerOpened,
    TResult? Function(_Error value)? error,
  }) {
    return downloaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_Downloaded value)? downloaded,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallerOpened value)? installerOpened,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (downloaded != null) {
      return downloaded(this);
    }
    return orElse();
  }
}

abstract class _Downloaded implements ApkDownloadState {
  const factory _Downloaded({required final String filePath}) =
      _$DownloadedImpl;

  String get filePath;

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DownloadedImplCopyWith<_$DownloadedImpl> get copyWith =>
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
    required TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )
    downloading,
    required TResult Function(String filePath) downloaded,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installerOpened,
    required TResult Function(String message) error,
  }) {
    return permissionNeeded(filePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult? Function(String filePath)? downloaded,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installerOpened,
    TResult? Function(String message)? error,
  }) {
    return permissionNeeded?.call(filePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult Function(String filePath)? downloaded,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installerOpened,
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
    required TResult Function(_Downloaded value) downloaded,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallerOpened value) installerOpened,
    required TResult Function(_Error value) error,
  }) {
    return permissionNeeded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_Downloaded value)? downloaded,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallerOpened value)? installerOpened,
    TResult? Function(_Error value)? error,
  }) {
    return permissionNeeded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_Downloaded value)? downloaded,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallerOpened value)? installerOpened,
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
abstract class _$$InstallerOpenedImplCopyWith<$Res> {
  factory _$$InstallerOpenedImplCopyWith(
    _$InstallerOpenedImpl value,
    $Res Function(_$InstallerOpenedImpl) then,
  ) = __$$InstallerOpenedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filePath});
}

/// @nodoc
class __$$InstallerOpenedImplCopyWithImpl<$Res>
    extends _$ApkDownloadStateCopyWithImpl<$Res, _$InstallerOpenedImpl>
    implements _$$InstallerOpenedImplCopyWith<$Res> {
  __$$InstallerOpenedImplCopyWithImpl(
    _$InstallerOpenedImpl _value,
    $Res Function(_$InstallerOpenedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filePath = null}) {
    return _then(
      _$InstallerOpenedImpl(
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$InstallerOpenedImpl implements _InstallerOpened {
  const _$InstallerOpenedImpl({required this.filePath});

  @override
  final String filePath;

  @override
  String toString() {
    return 'ApkDownloadState.installerOpened(filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InstallerOpenedImpl &&
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
  _$$InstallerOpenedImplCopyWith<_$InstallerOpenedImpl> get copyWith =>
      __$$InstallerOpenedImplCopyWithImpl<_$InstallerOpenedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )
    downloading,
    required TResult Function(String filePath) downloaded,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installerOpened,
    required TResult Function(String message) error,
  }) {
    return installerOpened(filePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult? Function(String filePath)? downloaded,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installerOpened,
    TResult? Function(String message)? error,
  }) {
    return installerOpened?.call(filePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult Function(String filePath)? downloaded,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installerOpened,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (installerOpened != null) {
      return installerOpened(filePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Downloading value) downloading,
    required TResult Function(_Downloaded value) downloaded,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallerOpened value) installerOpened,
    required TResult Function(_Error value) error,
  }) {
    return installerOpened(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_Downloaded value)? downloaded,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallerOpened value)? installerOpened,
    TResult? Function(_Error value)? error,
  }) {
    return installerOpened?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_Downloaded value)? downloaded,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallerOpened value)? installerOpened,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (installerOpened != null) {
      return installerOpened(this);
    }
    return orElse();
  }
}

abstract class _InstallerOpened implements ApkDownloadState {
  const factory _InstallerOpened({required final String filePath}) =
      _$InstallerOpenedImpl;

  String get filePath;

  /// Create a copy of ApkDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InstallerOpenedImplCopyWith<_$InstallerOpenedImpl> get copyWith =>
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
    required TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )
    downloading,
    required TResult Function(String filePath) downloaded,
    required TResult Function(String filePath) permissionNeeded,
    required TResult Function(String filePath) installerOpened,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult? Function(String filePath)? downloaded,
    TResult? Function(String filePath)? permissionNeeded,
    TResult? Function(String filePath)? installerOpened,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
      double progress,
      int bytesReceived,
      int totalBytes,
      double bytesPerSecond,
    )?
    downloading,
    TResult Function(String filePath)? downloaded,
    TResult Function(String filePath)? permissionNeeded,
    TResult Function(String filePath)? installerOpened,
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
    required TResult Function(_Downloaded value) downloaded,
    required TResult Function(_PermissionNeeded value) permissionNeeded,
    required TResult Function(_InstallerOpened value) installerOpened,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Downloading value)? downloading,
    TResult? Function(_Downloaded value)? downloaded,
    TResult? Function(_PermissionNeeded value)? permissionNeeded,
    TResult? Function(_InstallerOpened value)? installerOpened,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Downloading value)? downloading,
    TResult Function(_Downloaded value)? downloaded,
    TResult Function(_PermissionNeeded value)? permissionNeeded,
    TResult Function(_InstallerOpened value)? installerOpened,
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
