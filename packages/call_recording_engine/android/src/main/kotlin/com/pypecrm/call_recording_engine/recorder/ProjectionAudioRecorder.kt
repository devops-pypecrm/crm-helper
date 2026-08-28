package com.pypecrm.call_recording_engine.recorder

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.pypecrm.call_recording_engine.data.MediaProjectionTokenStore
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import kotlin.concurrent.thread

/**
 * Tier 3: MediaProjection `AudioPlaybackCaptureConfiguration` — captures
 * whatever the device is *playing* (call audio routed to the earpiece/
 * speaker), a different OS subsystem from Tiers 1/2's microphone-input
 * recording. Adapted from CallTrackerService's projection-capture code
 * (Dad-frontend). API 29+ only; needs a consent token obtained once from a
 * foreground Activity (see [MediaProjectionTokenStore]) — the most
 * invasive of all four tiers (a visible system "screen/audio capture"
 * permission dialog), which is why the plan ranks it last/lowest-priority.
 */
@RequiresApi(Build.VERSION_CODES.Q)
class ProjectionAudioRecorder(private val context: Context) {
    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null

    @Volatile private var isRecording = false
    private var recordThread: Thread? = null
    private var outputFile: File? = null

    val isActive: Boolean get() = isRecording

    /** Returns the output file being written to on success, or null if
     * capture couldn't be started (no token, or the platform APIs threw). */
    fun start(): File? {
        if (isRecording) return outputFile
        val (resultCode, resultData) = MediaProjectionTokenStore.current() ?: return null

        try {
            val manager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            // getMediaProjection() is @Nullable on the Java side (Kotlin
            // sees a platform type) — an explicit null check here, not just
            // the try/catch below, since a null projection isn't a thrown
            // exception, it's a normal "the grant token was stale" outcome.
            val projection = manager.getMediaProjection(resultCode, resultData) ?: return null
            mediaProjection = projection

            val file = File(context.cacheDir, "tier3_call_${System.currentTimeMillis()}.wav")

            val config = AudioPlaybackCaptureConfiguration.Builder(projection)
                .addMatchingUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .build()

            val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, ENCODING)
            val record = AudioRecord.Builder()
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(ENCODING)
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(CHANNEL_CONFIG)
                        .build()
                )
                .setAudioPlaybackCaptureConfig(config)
                .setBufferSizeInBytes(minBufferSize * 2)
                .build()

            record.startRecording()
            audioRecord = record
            isRecording = true
            outputFile = file
            recordThread = thread(start = true) { writeAudioDataToFile(file, minBufferSize) }
            return file
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start MediaProjection capture", e)
            stop()
            return null
        }
    }

    fun stop(): File? {
        if (!isRecording) return null
        isRecording = false
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to release AudioRecord", e)
        } finally {
            audioRecord = null
        }
        try {
            recordThread?.join(1000)
        } catch (_: InterruptedException) {
        }
        recordThread = null
        try {
            mediaProjection?.stop()
        } catch (_: Exception) {
        }
        mediaProjection = null
        val result = outputFile
        outputFile = null
        return result
    }

    private fun writeAudioDataToFile(file: File, bufferSize: Int) {
        val data = ByteArray(bufferSize)
        val out = FileOutputStream(file)
        out.write(ByteArray(WAV_HEADER_SIZE)) // placeholder, filled in by writeWavHeader once size is known
        try {
            while (isRecording) {
                val read = audioRecord?.read(data, 0, bufferSize) ?: 0
                if (read > 0) out.write(data, 0, read)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error writing projection audio bytes", e)
        } finally {
            out.close()
            if (file.exists() && file.length() > WAV_HEADER_SIZE) writeWavHeader(file)
        }
    }

    private fun writeWavHeader(file: File) {
        try {
            RandomAccessFile(file, "rw").use { raf ->
                val totalAudioLen = file.length() - WAV_HEADER_SIZE
                val totalDataLen = totalAudioLen + 36
                val byteRate = SAMPLE_RATE.toLong() * CHANNELS * 2

                val header = ByteArray(WAV_HEADER_SIZE)
                "RIFF".toByteArray().copyInto(header, 0)
                writeIntLE(header, 4, totalDataLen.toInt())
                "WAVE".toByteArray().copyInto(header, 8)
                "fmt ".toByteArray().copyInto(header, 12)
                writeIntLE(header, 16, 16)
                header[20] = 1 // PCM
                header[21] = 0
                header[22] = CHANNELS.toByte()
                header[23] = 0
                writeIntLE(header, 24, SAMPLE_RATE)
                writeIntLE(header, 28, byteRate.toInt())
                header[32] = (CHANNELS * 2).toByte()
                header[33] = 0
                header[34] = 16
                header[35] = 0
                "data".toByteArray().copyInto(header, 36)
                writeIntLE(header, 40, totalAudioLen.toInt())

                raf.seek(0)
                raf.write(header)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed writing WAV header", e)
        }
    }

    private fun writeIntLE(buffer: ByteArray, offset: Int, value: Int) {
        buffer[offset] = (value and 0xff).toByte()
        buffer[offset + 1] = ((value shr 8) and 0xff).toByte()
        buffer[offset + 2] = ((value shr 16) and 0xff).toByte()
        buffer[offset + 3] = ((value shr 24) and 0xff).toByte()
    }

    companion object {
        private const val TAG = "ProjectionAudioRecorder"
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val ENCODING = AudioFormat.ENCODING_PCM_16BIT
        private const val CHANNELS = 1
        private const val WAV_HEADER_SIZE = 44

        // Uncompressed 16kHz/16-bit/mono PCM runs ~32000 bytes/sec; well
        // below that for the claimed duration means silence or a
        // near-empty file — same "succeeded but silent" guard as Tier 1/2,
        // scaled for PCM WAV instead of compressed AAC.
        private const val MIN_BYTES_PER_SECOND = 8000

        fun isLikelySilent(file: File, durationSeconds: Int): Boolean {
            if (durationSeconds <= 0) return true
            if (!file.exists() || file.length() <= WAV_HEADER_SIZE) return true
            return (file.length() / durationSeconds) < MIN_BYTES_PER_SECOND
        }
    }
}
