import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'engine_provider.g.dart';

/// Single instance of the native plugin handle — everything that needs to
/// talk to the call-monitoring engine (session_provider on login/logout,
/// the status screen, the onboarding wizard) goes through this.
@Riverpod(keepAlive: true)
CallRecordingEngine callRecordingEngine(ProviderRef<CallRecordingEngine> ref) =>
    CallRecordingEngine();
