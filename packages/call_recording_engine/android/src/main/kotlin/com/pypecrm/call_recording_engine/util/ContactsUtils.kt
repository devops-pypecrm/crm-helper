package com.pypecrm.call_recording_engine.util

import android.content.Context
import android.net.Uri
import android.provider.ContactsContract
import android.util.Log

/**
 * Resolves a phone number to the device's own phone/SIM contacts —
 * separate from (and a fallback to) CRM lead matching, which only knows
 * about numbers already in this org's CRM. Requires READ_CONTACTS (part of
 * the lazily-requested dialer permission set, see
 * CallRecordingEnginePlugin's dialerPermissions()).
 */
object ContactsUtils {
    private const val TAG = "ContactsUtils"

    /** Returns the contact's display name, or null if no contact matches
     * or the permission isn't granted. */
    fun lookupName(context: Context, phoneNumber: String): String? {
        if (phoneNumber.isBlank()) return null
        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
            Uri.encode(phoneNumber),
        )
        val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
        return try {
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndexOrThrow(ContactsContract.PhoneLookup.DISPLAY_NAME))
                } else {
                    null
                }
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "READ_CONTACTS not granted — skipping contact lookup")
            null
        } catch (e: Exception) {
            Log.w(TAG, "Contact lookup failed", e)
            null
        }
    }
}
