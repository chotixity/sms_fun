package com.example.sms_fun

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/** Implemented in Dart via jnigen. */
fun interface WidgetUpdateListener {
    fun onUpdateRequested()
}

object WidgetBridge {
    @Volatile private var listener: WidgetUpdateListener? = null

    @JvmStatic fun setListener(l: WidgetUpdateListener?) { listener = l }

    @JvmStatic fun dispatch() { listener?.onUpdateRequested() }
}

/**
 * Only here because the manifest needs a real AppWidgetProvider class (jnigen
 * can't subclass). All rendering lives in Dart: lib/src/android/message_widget.dart.
 */
class MessageWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) = WidgetBridge.dispatch()
}
