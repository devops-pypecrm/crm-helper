package com.pypecrm.call_recording_engine.data

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * Plain framework SQLite (not Room) backing the Tier 4 offline queue —
 * deliberate: Room needs a KSP/kapt annotation-processor version pinned to
 * this exact Kotlin/AGP version, and getting that pin right from outside a
 * synced IDE (this was built without one available) is a real Gradle-break
 * risk for no payoff — one table, four simple operations, no relations or
 * migrations to speak of.
 */
class CallEventDbHelper private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DB_NAME, null, DB_VERSION) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE $TABLE (
                $COL_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COL_PHONE TEXT NOT NULL,
                $COL_DURATION INTEGER NOT NULL,
                $COL_TYPE TEXT NOT NULL,
                $COL_TIMESTAMP INTEGER NOT NULL,
                $COL_HARDWARE_ID TEXT,
                $COL_SESSION_ID TEXT,
                $COL_SYNCED INTEGER NOT NULL DEFAULT 0
            )
            """.trimIndent()
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE")
        onCreate(db)
    }

    fun enqueue(event: PendingCallEvent): Long {
        val values = ContentValues().apply {
            put(COL_PHONE, event.phoneNumber)
            put(COL_DURATION, event.durationSeconds)
            put(COL_TYPE, event.callType)
            put(COL_TIMESTAMP, event.timestampMillis)
            put(COL_HARDWARE_ID, event.hardwareId)
            put(COL_SESSION_ID, event.callSessionId)
            put(COL_SYNCED, 0)
        }
        return writableDatabase.insert(TABLE, null, values)
    }

    fun unsyncedEvents(): List<PendingCallEvent> {
        val results = mutableListOf<PendingCallEvent>()
        readableDatabase.query(
            TABLE, null, "$COL_SYNCED = 0", null, null, null, "$COL_TIMESTAMP ASC"
        ).use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(COL_ID)
            val phoneCol = cursor.getColumnIndexOrThrow(COL_PHONE)
            val durationCol = cursor.getColumnIndexOrThrow(COL_DURATION)
            val typeCol = cursor.getColumnIndexOrThrow(COL_TYPE)
            val timestampCol = cursor.getColumnIndexOrThrow(COL_TIMESTAMP)
            val hardwareIdCol = cursor.getColumnIndexOrThrow(COL_HARDWARE_ID)
            val sessionIdCol = cursor.getColumnIndexOrThrow(COL_SESSION_ID)
            while (cursor.moveToNext()) {
                results.add(
                    PendingCallEvent(
                        id = cursor.getLong(idCol),
                        phoneNumber = cursor.getString(phoneCol),
                        durationSeconds = cursor.getInt(durationCol),
                        callType = cursor.getString(typeCol),
                        timestampMillis = cursor.getLong(timestampCol),
                        hardwareId = cursor.getString(hardwareIdCol),
                        callSessionId = cursor.getString(sessionIdCol),
                    )
                )
            }
        }
        return results
    }

    fun markSynced(ids: List<Long>) {
        if (ids.isEmpty()) return
        val db = writableDatabase
        db.beginTransaction()
        try {
            val placeholders = ids.joinToString(",") { "?" }
            db.execSQL(
                "UPDATE $TABLE SET $COL_SYNCED = 1 WHERE $COL_ID IN ($placeholders)",
                ids.map { it as Any }.toTypedArray(),
            )
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    /** Synced rows are transit state, not an audit log (the CRM's own
     * Interaction rows are the durable record) — clear them out once done. */
    fun pruneSynced() {
        writableDatabase.delete(TABLE, "$COL_SYNCED = 1", null)
    }

    companion object {
        private const val DB_NAME = "call_recording_engine.db"
        private const val DB_VERSION = 1
        private const val TABLE = "pending_call_events"
        private const val COL_ID = "_id"
        private const val COL_PHONE = "phone_number"
        private const val COL_DURATION = "duration_seconds"
        private const val COL_TYPE = "call_type"
        private const val COL_TIMESTAMP = "timestamp_millis"
        private const val COL_HARDWARE_ID = "hardware_id"
        private const val COL_SESSION_ID = "call_session_id"
        private const val COL_SYNCED = "synced"

        @Volatile private var instance: CallEventDbHelper? = null

        fun getInstance(context: Context): CallEventDbHelper =
            instance ?: synchronized(this) {
                instance ?: CallEventDbHelper(context).also { instance = it }
            }
    }
}
