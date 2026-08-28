import 'package:freezed_annotation/freezed_annotation.dart';

import 'organisation.dart';

part 'user_session.freezed.dart';
part 'user_session.g.dart';

/// The exact response shape of `POST /api/auth/login` and `GET /api/auth/me`
/// (Dad-backend/src/controllers/authController.ts) — same contract
/// Dad-mobile's auth_repository.dart uses. Trimmed relative to
/// Dad-mobile/lib/features/auth/domain/user_session.dart: no
/// `position`/`isBranchManager`/`branchId`, since this app has no
/// profile/RBAC UI, just a status screen that names who's signed in.
@freezed
class UserSession with _$UserSession {
  const factory UserSession({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
    required Organisation organisation,
    /// Present on the login response; absent on `/auth/me` refreshes, in
    /// which case the previously stored token is kept.
    String? token,
  }) = _UserSession;

  factory UserSession.fromJson(Map<String, dynamic> json) => _$UserSessionFromJson(json);
}
