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
 * risk for no payoff.
 *
 * Two tables:
 *  - `pending_call_events`: the upload queue (metadata, plus an optional
 *    locally-kept recording whose real-time upload failed).
 *  - `handled_calls`: CallLog `_ID`s the real-time path already processed,
 *    so CallLogReconciler doesn't re-queue (and re-upload the audio of)
 *    every call the live path already handled.
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
                $COL_SYNCED INTEGER NOT NULL DEFAULT 0,
                $COL_RECORDING_PATH TEXT
            )
            """.trimIndent()
        )
        createHandledTable(db)
    }

    private fun createHandledTable(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS $HANDLED_TABLE (
                $COL_HANDLED_HW_ID TEXT PRIMARY KEY,
                $COL_HANDLED_AT INTEGER NOT NULL
            )
            """.trimIndent()
        )
    }

    // Never DROP here: the queue holds calls not yet in the CRM, and the
    // previous drop-and-recreate meant an app update silently deleted every
    // call still waiting to sync.
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL("ALTER TABLE $TABLE ADD COLUMN $COL_RECORDING_PATH TEXT")
            createHandledTable(db)
        }
    }

    /** Queues [event] unless an unsynced row for the same CallLog `_ID` is
     * already waiting — the live path, Tier 3 and the reconciler can all
     * reach the same call. A newly supplied recording is attached to the
     * existing row rather than dropped. */
    @Synchronized
    fun enqueue(event: PendingCallEvent): Long {
        val db = writableDatabase
        if (!event.hardwareId.isNullOrEmpty()) {
            db.query(
                TABLE, arrayOf(COL_ID, COL_RECORDING_PATH),
                "$COL_HARDWARE_ID = ? AND $COL_SYNCED = 0", arrayOf(event.hardwareId),
                null, null, null,
            ).use { cursor ->
                if (cursor.moveToFirst()) {
                    val existingId = cursor.getLong(0)
                    if (event.recordingPath != null && cursor.isNull(1)) {
                        db.update(
                            TABLE,
                            ContentValues().apply { put(COL_RECORDING_PATH, event.recordingPath) },
                            "$COL_ID = ?", arrayOf(existingId.toString()),
                        )
                    }
                    return existingId
                }
            }
        }
        val values = ContentValues().apply {
            put(COL_PHONE, event.phoneNumber)
            put(COL_DURATION, event.durationSeconds)
            put(COL_TYPE, event.callType)
            put(COL_TIMESTAMP, event.timestampMillis)
            put(COL_HARDWARE_ID, event.hardwareId)
            put(COL_SESSION_ID, event.callSessionId)
            put(COL_SYNCED, 0)
            put(COL_RECORDING_PATH, event.recordingPath)
        }
        return db.insert(TABLE, null, values)
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
            val recordingCol = cursor.getColumnIndexOrThrow(COL_RECORDING_PATH)
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
                        recordingPath = cursor.getString(recordingCol),
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

    /** Detaches a queued recording (uploaded elsewhere, file gone, or given
     * up on) so the row falls back to the metadata-only bulk-sync. */
    fun clearRecordingPath(id: Long) {
        writableDatabase.update(
            TABLE,
            ContentValues().apply { putNull(COL_RECORDING_PATH) },
            "$COL_ID = ?", arrayOf(id.toString()),
        )
    }

    /** Synced rows are transit state, not an audit log (the CRM's own
     * Interaction rows are the durable record) — clear them out once done. */
    fun pruneSynced() {
        writableDatabase.delete(TABLE, "$COL_SYNCED = 1", null)
    }

    /** Drops unsynced rows for calls older than [cutoffMillis] — a backstop
     * so an entry the server keeps rejecting can't be re-sent forever and
     * grow every bulk-sync payload. Returns the recording files those rows
     * still held so the caller can delete them. */
    fun dropUnsyncedOlderThan(cutoffMillis: Long): List<String> {
        val db = writableDatabase
        val paths = mutableListOf<String>()
        db.query(
            TABLE, arrayOf(COL_RECORDING_PATH),
            "$COL_SYNCED = 0 AND $COL_TIMESTAMP < ? AND $COL_RECORDING_PATH IS NOT NULL",
            arrayOf(cutoffMillis.toString()), null, null, null,
        ).use { cursor -> while (cursor.moveToNext()) paths.add(cursor.getString(0)) }
        db.delete(TABLE, "$COL_SYNCED = 0 AND $COL_TIMESTAMP < ?", arrayOf(cutoffMillis.toString()))
        return paths
    }

    fun markHandled(hardwareId: String?) {
        if (hardwareId.isNullOrEmpty()) return
        writableDatabase.insertWithOnConflict(
            HANDLED_TABLE, null,
            ContentValues().apply {
                put(COL_HANDLED_HW_ID, hardwareId)
                put(COL_HANDLED_AT, System.currentTimeMillis())
            },
            SQLiteDatabase.CONFLICT_REPLACE,
        )
    }

    fun isHandled(hardwareId: String?): Boolean {
        if (hardwareId.isNullOrEmpty()) return false
        readableDatabase.query(
            HANDLED_TABLE, arrayOf(COL_HANDLED_HW_ID), "$COL_HANDLED_HW_ID = ?", arrayOf(hardwareId),
            null, null, null,
        ).use { return it.moveToFirst() }
    }

    /** CallLog `_ID`s can be recycled after the log is pruned (see the
     * backend's HARDWARE_ID_MATCH_WINDOW_MS), so handled markers only need
     * to outlive the reconciler's look-back window, not forever. */
    fun pruneHandledOlderThan(cutoffMillis: Long) {
        writableDatabase.delete(HANDLED_TABLE, "$COL_HANDLED_AT < ?", arrayOf(cutoffMillis.toString()))
    }

    companion object {
        private const val DB_NAME = "call_recording_engine.db"
        private const val DB_VERSION = 2
        private const val TABLE = "pending_call_events"
        private const val COL_ID = "_id"
        private const val COL_PHONE = "phone_number"
        private const val COL_DURATION = "duration_seconds"
        private const val COL_TYPE = "call_type"
        private const val COL_TIMESTAMP = "timestamp_millis"
        private const val COL_HARDWARE_ID = "hardware_id"
        private const val COL_SESSION_ID = "call_session_id"
        private const val COL_SYNCED = "synced"
        private const val COL_RECORDING_PATH = "recording_path"
        private const val HANDLED_TABLE = "handled_calls"
        private const val COL_HANDLED_HW_ID = "hardware_id"
        private const val COL_HANDLED_AT = "handled_at"

        @Volatile private var instance: CallEventDbHelper? = null

        fun getInstance(context: Context): CallEventDbHelper =
            instance ?: synchronized(this) {
                instance ?: CallEventDbHelper(context).also { instance = it }
            }
    }
}
