package com.pypecrm.call_recording_engine.dialer

import android.telecom.Call
import android.telecom.VideoProfile
import io.flutter.plugin.common.EventChannel

/**
 * Bridges the real [android.telecom.Call] object (owned by [PypeInCallService],
 * which only exists once this app is the system default dialer) to the
 * Flutter side via an [EventChannel] — and back, for in-call controls
 * (answer/reject/end/mute/hold), since those must be invoked on the actual
 * Call object, not simulated locally the way an earlier version of this
 * feature did.
 *
 * A plain object (not tied to any Activity) because [PypeInCallService] can
 * receive a call while no Activity is in the foreground (e.g. app was
 * backgrounded, or the call is incoming) — the sink is attached only while
 * Dart is actively listening; state changes that happen with no sink
 * attached are simply not delivered to Flutter (CallMonitorService's own
 * recording/CRM-sync pipeline does not depend on Flutter being alive at
 * all, same as every other tier in this app).
 */
object CallEventBridge : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null
    private var currentCall: Call? = null

    // Mute and speakerphone are controlled on the InCallService itself
    // (setMuted / setAudioRoute), not on the Call object — set by
    // PypeInCallService when it starts/stops.
    var service: PypeInCallService? = null

    fun attach(call: Call) {
        currentCall = call
    }

    fun detach(call: Call) {
        if (currentCall === call) currentCall = null
    }

    fun emit(event: Map<String, Any?>) {
        sink?.success(event)
    }

    fun answer() = currentCall?.answer(VideoProfile.STATE_AUDIO_ONLY)
    fun reject() = currentCall?.reject(false, null)
    fun hangup() = currentCall?.disconnect()
    fun setHold(onHold: Boolean) {
        if (onHold) currentCall?.hold() else currentCall?.unhold()
    }
    fun playDtmf(digit: Char) = currentCall?.playDtmfTone(digit)

    fun setMuted(muted: Boolean) = service?.setMuted(muted)

    /** [CallAudioState.ROUTE_SPEAKER] / [android.telecom.CallAudioState.ROUTE_EARPIECE]. */
    fun setSpeakerOn(on: Boolean) {
        val route = if (on) android.telecom.CallAudioState.ROUTE_SPEAKER
        else android.telecom.CallAudioState.ROUTE_EARPIECE
        service?.setAudioRoute(route)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
