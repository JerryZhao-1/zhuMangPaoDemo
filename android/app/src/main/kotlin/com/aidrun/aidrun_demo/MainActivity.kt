package com.aidrun.aidrun_demo

import android.os.Build
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import com.amap.api.location.AMapLocationClient
import com.amap.api.maps.MapsInitializer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Locale

class MainActivity : FlutterActivity() {
    private var speechChannel: MethodChannel? = null
    private var textToSpeech: TextToSpeech? = null
    private var ttsReady = false
    private var ttsInitializing = false
    private val pendingTtsCallbacks = mutableListOf<(Boolean) -> Unit>()
    private var pendingSpeakResult: Result? = null
    private var speechLanguage: String = "zh-CN"
    private var speechRate: Float = 0.48f
    private var speechPitch: Float = 1.0f

    override fun onCreate(savedInstanceState: Bundle?) {
        initializeAmap()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAndroidEmulator" -> result.success(isProbablyEmulator())
                else -> result.notImplemented()
            }
        }

        speechChannel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                SPEECH_CHANNEL,
            ).also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "configure" -> configureSpeech(call.arguments, result)
                        "speak" -> speak(call.arguments, result)
                        "stop" -> {
                            stopSpeech()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    private fun initializeAmap() {
        val apiKey = BuildConfig.AMAP_ANDROID_KEY
        if (apiKey.isBlank()) {
            return
        }

        try {
            MapsInitializer.updatePrivacyShow(this, true, true)
            MapsInitializer.updatePrivacyAgree(this, true)
            MapsInitializer.setApiKey(apiKey)
        } catch (_: Throwable) {
        }

        try {
            AMapLocationClient.updatePrivacyShow(this, true, true)
            AMapLocationClient.updatePrivacyAgree(this, true)
            AMapLocationClient.setApiKey(apiKey)
        } catch (_: Throwable) {
        }
    }

    private fun isProbablyEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.contains("emulator", ignoreCase = true) ||
            Build.MODEL.contains("Emulator", ignoreCase = true) ||
            Build.MODEL.contains("sdk_gphone", ignoreCase = true) ||
            Build.MANUFACTURER.contains("Genymotion", ignoreCase = true) ||
            Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
            Build.PRODUCT.contains("sdk", ignoreCase = true)
    }

    private fun configureSpeech(arguments: Any?, result: Result) {
        val args = arguments as? Map<*, *>
        speechLanguage = (args?.get("language") as? String)?.takeIf { it.isNotBlank() } ?: speechLanguage
        speechRate = (args?.get("rate") as? Double)?.toFloat() ?: speechRate
        speechPitch = (args?.get("pitch") as? Double)?.toFloat() ?: speechPitch

        ensureTextToSpeech { ready ->
            if (ready) {
                applySpeechConfig()
            }
            result.success(null)
        }
    }

    private fun speak(arguments: Any?, result: Result) {
        val args = arguments as? Map<*, *>
        val text = (args?.get("text") as? String)?.trim().orEmpty()
        if (text.isEmpty()) {
            result.success(null)
            return
        }

        ensureTextToSpeech { ready ->
            if (!ready) {
                result.success(null)
                return@ensureTextToSpeech
            }

            applySpeechConfig()
            resolvePendingSpeak()
            stopSpeechInternal()
            pendingSpeakResult = result

            val utteranceId = "aidrun-${System.currentTimeMillis()}"
            val status = textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
            if (status != TextToSpeech.SUCCESS) {
                resolvePendingSpeak()
            }
        }
    }

    private fun ensureTextToSpeech(callback: (Boolean) -> Unit) {
        if (ttsReady && textToSpeech != null) {
            callback(true)
            return
        }

        pendingTtsCallbacks += callback
        if (ttsInitializing) {
            return
        }

        ttsInitializing = true
        textToSpeech =
            TextToSpeech(applicationContext) { status ->
                val ready = status == TextToSpeech.SUCCESS
                runOnUiThread {
                    ttsInitializing = false
                    val tts = textToSpeech
                    textToSpeech = if (ready) tts else null
                    ttsReady = ready
                    if (ready && tts != null) {
                        tts.setOnUtteranceProgressListener(
                            object : UtteranceProgressListener() {
                                override fun onStart(utteranceId: String?) = Unit

                                override fun onDone(utteranceId: String?) {
                                    runOnUiThread { resolvePendingSpeak() }
                                }

                                @Deprecated("Deprecated in Java")
                                override fun onError(utteranceId: String?) {
                                    runOnUiThread { resolvePendingSpeak() }
                                }

                                override fun onError(utteranceId: String?, errorCode: Int) {
                                    runOnUiThread { resolvePendingSpeak() }
                                }
                            },
                        )
                        applySpeechConfig()
                    }
                    val callbacks = pendingTtsCallbacks.toList()
                    pendingTtsCallbacks.clear()
                    callbacks.forEach { it(ready) }
                }
            }
    }

    private fun applySpeechConfig() {
        textToSpeech?.language = Locale.forLanguageTag(speechLanguage)
        textToSpeech?.setSpeechRate(speechRate)
        textToSpeech?.setPitch(speechPitch)
    }

    private fun stopSpeech() {
        stopSpeechInternal()
        resolvePendingSpeak()
    }

    private fun stopSpeechInternal() {
        textToSpeech?.stop()
    }

    private fun resolvePendingSpeak() {
        pendingSpeakResult?.success(null)
        pendingSpeakResult = null
    }

    override fun onDestroy() {
        speechChannel?.setMethodCallHandler(null)
        stopSpeechInternal()
        textToSpeech?.shutdown()
        textToSpeech = null
        pendingTtsCallbacks.clear()
        pendingSpeakResult = null
        super.onDestroy()
    }

    companion object {
        private const val DEVICE_CHANNEL = "aidrun/device"
        private const val SPEECH_CHANNEL = "aidrun/speech"
    }
}
