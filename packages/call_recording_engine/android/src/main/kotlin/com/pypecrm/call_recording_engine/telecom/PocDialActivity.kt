package com.pypecrm.call_recording_engine.telecom

import android.app.Activity
import android.os.Bundle

/**
 * Does nothing itself — its only job is to exist and be declared for
 * `ACTION_DIAL`/`ACTION_VIEW` (`tel:`) in the manifest, a hard requirement
 * for `RoleManager.ROLE_DIALER` eligibility (an app can't be offered as a
 * default-dialer candidate at all without one). Actual call placement in
 * this POC goes through `CallRecordingEnginePlugin.startPocDialerCall()`,
 * invoked from the Dart POC screen, not through this activity — if Android
 * or the user launches this directly (e.g. tapping a phone number
 * elsewhere on the device while this app holds the dialer role), it just
 * finishes immediately rather than pretending to offer a real dial-pad.
 */
class PocDialActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        finish()
    }
}
