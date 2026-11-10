package com.example.sms_fun

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()   // no channels any more

/** Implemented in Dart via jnigen. */
fun interface IncomingSmsListener {
    fun onSmsReceived(intent: Intent)
}

object SmsBridge {
    @Volatile private var listener: IncomingSmsListener? = null

    @JvmStatic fun setListener(l: IncomingSmsListener?) { listener = l }

    @JvmStatic fun dispatch(intent: Intent) { listener?.onSmsReceived(intent) }
}

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            SmsBridge.dispatch(intent)
        }
    }
}
