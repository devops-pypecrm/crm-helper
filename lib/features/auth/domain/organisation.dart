import 'package:freezed_annotation/freezed_annotation.dart';

part 'organisation.freezed.dart';
part 'organisation.g.dart';

/// Mirrors the subset of Prisma's `Organisation` model
/// (Dad-backend/prisma/schema.prisma) this app needs — just enough to label
/// the signed-in org on the status screen. Trimmed compared to
/// Dad-mobile/lib/features/auth/domain/organisation.dart (no pipeline/stage
/// config — this app has no lead/opportunity UI). Extra backend fields are
/// ignored on parse.
@freezed
class Organisation with _$Organisation {
  const factory Organisation({
    required String id,
    required String name,
  }) = _Organisation;

  factory Organisation.fromJson(Map<String, dynamic> json) => _$OrganisationFromJson(json);
}
