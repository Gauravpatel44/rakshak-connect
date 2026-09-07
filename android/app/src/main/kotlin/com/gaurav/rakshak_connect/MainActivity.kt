package com.gaurav.rakshak_connect

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity
 *
 * Dynamic Lock Screen & Screen Wake Control:
 *   Exposes setLockScreenVisibility via MethodChannel so lock screen flags
 *   are only active when an incoming fake call is presented, preventing
 *   unauthorized access to the rest of the application.
 *
 * Robust System Ringtone & Audio Attributes:
 *   - API 28+: Ringtone with USAGE_NOTIFICATION_RINGTONE & CONTENT_TYPE_SONIFICATION
 *   - API 26-27: MediaPlayer with USAGE_NOTIFICATION_RINGTONE (binds to STREAM_RING, not STREAM_MUSIC)
 *
 * Native Hardware Vibration:
 *   Vibrates with a realistic 1s on / 1s off repeating call pattern during incoming calls.
 *
 * Channel:  com.gaurav.rakshak_connect/system_ringtone
 * Methods:  playSystemRingtone | stopSystemRingtone | setLockScreenVisibility | moveAppToBack
 */
class MainActivity : FlutterActivity() {

    private val ringtoneChannelName = "com.gaurav.rakshak_connect/system_ringtone"

    // API 28+ path
    private var ringtone: Ringtone? = null
    // API 26–27 path
    private var mediaPlayer: MediaPlayer? = null
    // Hardware vibrator
    private var vibrator: Vibrator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Note: Lock screen and wake flags are now set dynamically when a call arrives
        // via setLockScreenVisibility, preventing sensitive data exposure over the lock screen.
    }

    // ── MethodChannel ────────────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ringtoneChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "playSystemRingtone" -> {
                        stopAllAudio()

                        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        if (uri == null) {
                            startVibration()
                            result.success(null)
                            return@setMethodCallHandler
                        }

                        try {
                            val audioAttributes = AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build()

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                // API 28+ (Android 9+): Ringtone API with USAGE_NOTIFICATION_RINGTONE
                                ringtone = RingtoneManager.getRingtone(applicationContext, uri)?.also {
                                    it.audioAttributes = audioAttributes
                                    it.isLooping = true
                                    it.play()
                                }
                            } else {
                                // API 26–27 (Android 8.0–8.1): MediaPlayer configured explicitly for ringtone audio
                                val player = MediaPlayer().apply {
                                    setAudioAttributes(audioAttributes)
                                    setDataSource(applicationContext, uri)
                                    isLooping = true
                                    prepare()
                                    start()
                                }
                                mediaPlayer = player
                            }

                            startVibration()
                            result.success(null)
                        } catch (e: Exception) {
                            // Non-fatal fallback: ensure vibration works even if audio initialization fails
                            startVibration()
                            result.error(
                                "RINGTONE_PLAY_ERROR",
                                "Failed to play system ringtone: ${e.message}",
                                null
                            )
                        }
                    }

                    "stopSystemRingtone" -> {
                        stopAllAudio()
                        result.success(null)
                    }

                    "setLockScreenVisibility" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        setLockScreenMode(enable)
                        result.success(null)
                    }

                    "moveAppToBack" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /** Dynamically toggles display over lock screen and screen turn-on. */
    private fun setLockScreenMode(enable: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(enable)
            setTurnScreenOn(enable)
        } else {
            @Suppress("DEPRECATION")
            if (enable) {
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                )
            } else {
                window.clearFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                )
            }
        }
    }

    /** Starts a realistic phone ring vibration pattern (1s on, 1s off, repeat). */
    private fun startVibration() {
        stopVibration()
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            val pattern = longArrayOf(0, 1000, 1000)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(pattern, 0)
                vibrator?.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (_: Exception) {}
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
        } catch (_: Exception) {}
        vibrator = null
    }

    /** Stops and releases all audio and vibration resources defensively. */
    private fun stopAllAudio() {
        stopVibration()

        try { ringtone?.stop() } catch (_: Exception) {}
        ringtone = null

        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (_: Exception) {}
        mediaPlayer = null
    }

    override fun onDestroy() {
        stopAllAudio()
        setLockScreenMode(false)
        super.onDestroy()
    }
}
