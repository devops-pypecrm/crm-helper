// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppReleaseImpl _$$AppReleaseImplFromJson(Map<String, dynamic> json) =>
    _$AppReleaseImpl(
      versionName: json['versionName'] as String,
      versionCode: (json['versionCode'] as num).toInt(),
      releaseNotes: json['releaseNotes'] as String,
      apkFileName: json['apkFileName'] as String,
      releasedAt: json['releasedAt'] as String,
    );

Map<String, dynamic> _$$AppReleaseImplToJson(_$AppReleaseImpl instance) =>
    <String, dynamic>{
      'versionName': instance.versionName,
      'versionCode': instance.versionCode,
      'releaseNotes': instance.releaseNotes,
      'apkFileName': instance.apkFileName,
      'releasedAt': instance.releasedAt,
    };
