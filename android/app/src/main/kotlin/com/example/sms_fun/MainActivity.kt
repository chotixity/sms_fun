package com.example.sms_fun

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsMessage
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.sms_fun/mpesa"
    private val EVENT_CHANNEL = "com.example.sms_fun/mpesa_events"

    companion object {
        private var eventSink: EventChannel.EventSink? = null

        fun notifyNewMessage(message: String) {
            MpesaMessageStore.addMessage(message)
            eventSink?.success(message)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMpesaMessages" -> result.success(MpesaMessageStore.getMessages())
                "clearMpesaMessages" -> {
                    MpesaMessageStore.clearMessages()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }
}

object MpesaMessageStore {
    private val messages = mutableListOf<String>()

    @Synchronized
    fun addMessage(message: String) {
        messages.add(message)
    }

    @Synchronized
    fun getMessages(): List<String> = messages.toList()

    @Synchronized
    fun clearMessages() {
        messages.clear()
    }
}

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle = intent.extras
            if (bundle != null) {
                val pdus = bundle.get("pdus") as Array<*>
                for (i in pdus.indices) {
                    val smsMessage = SmsMessage.createFromPdu(pdus[i] as ByteArray)
                    val originatingAddress = smsMessage.originatingAddress

                    if (originatingAddress == "MPESA") {
                        val messageBody = smsMessage.messageBody
                        MainActivity.notifyNewMessage(messageBody)
                    }
                }
            }
        }
    }
}