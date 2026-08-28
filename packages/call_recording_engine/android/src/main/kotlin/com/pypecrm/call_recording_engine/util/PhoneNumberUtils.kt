package com.pypecrm.call_recording_engine.util

object PhoneNumberUtils {
    /**
     * Last 10 digits of a phone number, stripped of all non-digit
     * characters. Matches the suffix-matching convention used server-side
     * (Dad-backend/src/controllers/androidController.ts) and by the old
     * wrapper app's CallLog/MediaStore lookups — a number can show up with
     * +91/91/0 prefixes across the OS call log, MediaStore filenames, and
     * the CRM's stored lead phone, so comparing only the last 10 digits is
     * the one representation all three tend to agree on.
     */
    fun last10Digits(raw: String?): String {
        if (raw.isNullOrEmpty()) return ""
        val digits = raw.filter { it.isDigit() }
        return if (digits.length >= 10) digits.takeLast(10) else digits
    }
}
