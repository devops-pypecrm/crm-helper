# Prompt: Convert PypeCRM Helper into a default-dialer app

Copy everything below this line into Antigravity as the task prompt.

---

## Context

You're working on **PypeCRM Helper** (`Dad-call-recorder`), a Flutter/Kotlin Android app that is a sideloaded field-companion to a multi-tenant CRM called PypeCRM. It currently exists to solve one problem: get call activity (who called, direction, duration, and — when possible — the audio) from a field sales rep's phone into the CRM automatically, without the rep doing anything manual.

Today it does this **without being the phone's dialer app** — it watches `TelephonyManager` broadcasts, polls the system Call Log, and hunts for audio files the phone's own (separate) dialer/recorder app might have produced. That approach works but is fundamentally reactive and OEM-dependent: it has to guess at call direction from raw `CallLog.Calls.TYPE` integers (some OEMs use non-standard values), it can miss a call entirely if a broadcast doesn't fire, and it can only find a recording if some other app already made one.

**The goal of this branch is to make PypeCRM Helper become the phone's own default dialer app.** As the actual `ConnectionService`/`InCallService` implementation, call state (ringing/active/ended, direction, the actual phone number, call duration) becomes authoritative — sourced directly from the Android Telecom framework instead of reverse-engineered after the fact. This should eliminate essentially every call-detection/misclassification bug the current implementation has, and is also the prerequisite for ever publishing this app on the Play Store (Google restricts `READ_CALL_LOG`/call-related permissions to an app that is the user's default Phone or Assistant handler).

**Important limitation to design around, not silently break:** becoming the default dialer does **not** unlock clean access to the other party's voice during a call — Android restricts capturing call audio regardless of dialer role, specifically to prevent silent recording. So the existing "Tier 0–3" audio capture/recovery logic (finding a native recorder's file, or capturing audio via `MediaRecorder`/`MediaProjection` workarounds) most likely still needs to exist and run *alongside* the new dialer functionality — don't delete it assuming the dialer role makes it obsolete. Treat this conversion as: **replace the call-detection/metadata layer with the Telecom framework, keep the audio-capture layer as-is (adapted to trigger off real `Connection` lifecycle callbacks instead of `CallStateReceiver` broadcasts).**

## What must be preserved

This app has a lot of working, tested functionality that the CRM integration depends on. Do not regress any of it:

- **Multi-tenant CRM sync**: every synced call must still carry the signed-in user's JWT/organisation context. Auth is stored natively (`NativeAuthPrefs`, SharedPreferences-backed) so background work can run without the Flutter engine alive.
- **Backend API contract** (`Dad-backend`, sibling repo, not to be modified as part of this task): `POST /api/android/recordings` (multipart audio upload), `POST /api/android/bulk-sync` (batched call metadata), `POST /api/android/helper-logs` (structured diagnostic events), `GET /api/android/leads`, `GET /api/call-settings` (org-level `autoRecordInbound`/`autoRecordOutbound` consent flags — **must keep being enforced** before any audio is uploaded, this is a legal consent gate, not a suggestion), `GET/POST /api/app-releases/*` (in-app update mechanism). All of `packages/call_recording_engine/android/.../net/BackendApi.kt`'s existing methods should keep working.
- **WhatsApp reply sync** (`WhatsAppSyncListenerService`, a `NotificationListenerService`) — unrelated to dialer functionality, must keep working untouched.
- **The reconciliation safety net** (`CallLogReconciler` + `CallLogReconcilePrefs`) — even as the default dialer, keep this as a backstop for anything the new `ConnectionService` path somehow misses (e.g. a call that happened before the app was set as default, or during a crash/restart window).
- **Helper Logs telemetry** (`EngineDebugLog` → `HelperLogUploader` → `HelperActivityLog` on the backend, surfaced in Dad-frontend's super-admin "Helper Logs" panel) — extend this with new dialer-specific events (e.g. `DIALER_CALL_PLACED`, `DIALER_CALL_ANSWERED`, `DIALER_SET_AS_DEFAULT`), don't replace it.
- **The in-app update system** (`lib/features/updates/`, `UpdatesScreen`, `UpdateBanner`) — keep working; a rep on an old version should still get prompted to update.
- **Existing onboarding flow** (`lib/features/onboarding/presentation/screens/onboarding_screen.dart`) — extend it with a new step for "Set as default phone app," don't replace the existing permission/battery/accessibility steps.
- **App branding**: green theme (`lib/core/theme/app_theme.dart`, `kBrandColor = 0xFF578732`, `kBrandSurface = 0xFFF9FAEF`), Material 3, app name "PypeCRM Helper," `applicationId = "com.pypecrm.recorder"` (do not change — changing it breaks update-in-place for already-installed devices, wiping their granted permissions).
- **Architecture conventions**: Flutter side uses Riverpod with `@riverpod` code generation (`part '*.g.dart'`), Freezed for models/state unions, a plain `MethodChannel` (not a federated plugin) for each native bridge (`com.pypecrm.recorder/engine`, `com.pypecrm.recorder/installer`). Native side is Kotlin, organized under `packages/call_recording_engine/android/src/main/kotlin/com/pypecrm/call_recording_engine/` (a local Flutter plugin package) with subpackages `data/` (SharedPreferences-backed prefs classes), `net/` (BackendApi + sealed result classes), `receivers/`, `service/`, `sync/` (WorkManager workers), `scanner/`, `accessibility/`, `debug/`. Follow these same conventions for new code rather than introducing a new pattern.

## What "becoming the default dialer" requires (Android side)

1. **`PhoneAccount` registration**: register a `PhoneAccountHandle` with `TelecomManager.registerPhoneAccount()` at app startup, with `CAPABILITY_CALL_PROVIDER` (and `CAPABILITY_SELF_MANAGED` is an option to evaluate — a self-managed `ConnectionService` is significantly less native-Telecom-UI-integrated but *much* less work than a fully-managed one that must render Android's own in-call surfaces correctly across OEM skins; recommend evaluating self-managed first given this app's actual goal is CRM data capture, not being a general-purpose phone replacement, but flag the tradeoff back to the user rather than silently deciding).
2. **`ConnectionService`**: implement `onCreateIncomingConnection` / `onCreateOutgoingConnection`, returning a `Connection` subclass that reports state (`setActive()`, `setDisconnected()`, etc.) — this is what makes call state authoritative instead of inferred.
3. **`InCallService`** (only required for a fully-managed, i.e. non-self-managed, implementation) — renders the actual in-call screen; must handle `onCallAdded`/`onCallRemoved` and expose mute/speaker/hold/end controls.
4. **Requesting the default-dialer role**: `RoleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)` on API 29+ (fall back to `TelecomManager.ACTION_CHANGE_DEFAULT_DIALER` intent below that) — the user must explicitly grant this via a system dialog, same UX category as the existing "Ignore battery optimizations" onboarding step (can't be silently granted).
5. **New/changed permissions**: `CALL_PHONE`, `ANSWER_PHONE_CALLS`, `MANAGE_OWN_CALLS` (if self-managed), `READ_CONTACTS` (for a real dialer UI — matching numbers to names), and confirm whether `WRITE_CALL_LOG`/`PROCESS_OUTGOING_CALLS` are actually needed for the chosen approach (they may not be, given `READ_CALL_LOG` is already granted). Document the exact final permission set and update `AndroidManifest.xml` plus the onboarding screen's permission list together — don't let them drift out of sync (this happened before in this codebase and caused confusion, see `CallRecordingEnginePlugin.kt`'s comment about owning permission strings directly rather than trusting a generic plugin).
6. **Emergency-call correctness**: Android's Telecom framework handles emergency-number routing at the OS level regardless of default-dialer app, but the in-call UI (if fully-managed) must still not block or interfere with placing/displaying an emergency call. If going the self-managed route, confirm self-managed connections are exempted from this concern the way you expect — verify against current Android docs, don't assume.

## New UI needed (Flutter side, matching existing theme/patterns)

- **Dialer screen**: numeric keypad + a call button, following Material 3 + `AppTheme.light`'s existing button/card styling. Should search/match against CRM leads (`GET /api/android/leads`, already fetched and cached — see `getAndroidLeads`) as the user types, so a rep can see "this number belongs to lead X" before dialing, not just raw digits.
- **In-call screen** (if fully-managed `InCallService`): mute, speaker, hold, end-call controls, showing the matched CRM lead's name/organisation if the number matches one, elapsed-call timer. Green-branded, consistent with the rest of the app.
- **Incoming-call screen**: full-screen intent UI for a ringing call (answer/decline), same lead-matching as above.
- **Call log tab**: a simple list of recent calls *as recorded by this app's own Telecom integration* (for the rep's own reference) — separate from, but reconcilable with, what's already synced to the CRM.
- **New onboarding step**: "Set PypeCRM Helper as your default Phone app," inserted into the existing `OnboardingScreen`'s step list (`_OnboardingStep` widgets), with the same granted/not-granted visual pattern already used for the other steps.
- **Status screen update**: add a row/indicator for "Default dialer: Active/Inactive" alongside the existing "Call log history access" row (`lib/features/status/presentation/screens/status_screen.dart`).

## Deliverables

1. A written technical plan first — self-managed vs. fully-managed `ConnectionService`, exact final permission list, and a phased rollout (e.g. Phase 1: register as a call-capable app and get accurate call-state/direction without changing the UI at all; Phase 2: real dialer/in-call UI) — before writing implementation code, since this is a large, high-risk-if-wrong change to how a rep's phone actually makes calls.
2. Native Kotlin implementation under `packages/call_recording_engine/android/`, following existing package/class conventions.
3. Flutter UI under `lib/features/dialer/` (new feature folder, same structure as `lib/features/updates/`: `domain/`, `data/`, `presentation/screens/`, `presentation/widgets/`, `providers/`), wired into the existing app navigation.
4. Updated `AndroidManifest.xml`, onboarding screen, and status screen as described above.
5. Every new event this flow can produce should get a corresponding `EngineDebugLog.append(...)` call (matching the existing convention in `CallStateReceiver.kt`/`CallLogReconciler.kt`) so it's visible in the super-admin Helper Logs panel.
6. Confirm `flutter analyze` and `flutter build apk --debug` both pass before considering any phase done — this repo has no automated test suite, that's the actual verification bar used throughout its history.

## Explicitly out of scope for this task

- Do not touch `Dad-backend` or `Dad-frontend` (separate sibling repos) — if you determine a backend change is genuinely required (e.g. a new field to store dialer-specific call metadata), stop and describe exactly what's needed rather than modifying those repos directly.
- Do not attempt Play Store submission/compliance work as part of this — that's a separate future decision once the dialer functionality itself is working and tested on real devices.
- Do not remove or disable the existing Tier 0–4 call-recording/sync logic — extend/adapt it to the new call-lifecycle source of truth, don't delete it.
