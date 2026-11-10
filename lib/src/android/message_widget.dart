import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';
import 'package:sms_fun/src/android/bindings.g.dart';

// Kotlin only declares MessageWidgetProvider (the manifest needs a real class);
// everything else about the home widget is done here through jnigen bindings.

const _providerClass = 'com.example.sms_fun.MessageWidgetProvider';
const _prefsName = 'message_widget';
const _prefsKey = 'text';
const _emptyText = 'No messages yet';

WidgetUpdateListener? _refreshListener;

/// Lets the system ask Dart to redraw the widget (first placement, reboot).
/// Call once at startup.
void registerMessageWidget() {
  if (_refreshListener != null) return;
  _refreshListener = WidgetUpdateListener.implement($WidgetUpdateListener(
    onUpdateRequested: () => _render(null),
    // onUpdate runs on Android's main thread; don't block it.
    onUpdateRequested$async: true,
  ));
  WidgetBridge.listener = _refreshListener;
}

/// Shows [text] on every placed widget and remembers it for later redraws.
void updateMessageWidget(String text) => _render(text);

void _render(String? newText) => using((arena) {
      final ctx = androidApplicationContext.as(Context.type,
          releaseOriginal: true)
        ..releasedBy(arena);

      final prefs = ctx.getSharedPreferences(_prefsName.toJString()..releasedBy(arena), 0)
        ?..releasedBy(arena);
      final key = _prefsKey.toJString()..releasedBy(arena);

      if (newText != null) {
        final editor = prefs?.edit()?..releasedBy(arena);
        editor
            ?.putString(key, newText.toJString()..releasedBy(arena))
            ?.releasedBy(arena);
        editor?.apply();
      }
      final text = newText ??
          prefs?.getString(key, null)?.toDartString(releaseOriginal: true) ??
          _emptyText;

      // Resource ids by name, so Dart doesn't need the generated R class.
      final pkg = ctx.packageName!..releasedBy(arena);
      final res = ctx.resources!..releasedBy(arena);
      int id(String name, String type) => res.getIdentifier(
          name.toJString()..releasedBy(arena),
          type.toJString()..releasedBy(arena),
          pkg);
      final layout = id('message_widget', 'layout');
      final messageView = id('widget_message', 'id');
      final rootView = id('widget_root', 'id');

      // Tapping the widget opens the app.
      final launch = ctx.packageManager!
          .getLaunchIntentForPackage(pkg)
        ?..releasedBy(arena);
      final tap = PendingIntent.getActivity(
        ctx,
        0,
        launch ?? Intent(),
        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE,
      )?..releasedBy(arena);

      final views = RemoteViews.new$4(pkg, layout)..releasedBy(arena);
      views.setTextViewText(
          messageView,
          (text.toJString()..releasedBy(arena))
              .as(CharSequence.type, releaseOriginal: false)
            ..releasedBy(arena));
      views.setOnClickPendingIntent(rootView, tap);

      final manager = AppWidgetManager.getInstance(ctx)!..releasedBy(arena);
      final provider = ComponentName.new$1(
          ctx, _providerClass.toJString()..releasedBy(arena))
        ..releasedBy(arena);
      final ids = manager.getAppWidgetIds(provider)!..releasedBy(arena);
      for (var i = 0; i < ids.length; i++) {
        manager.updateAppWidget$1(ids[i], views);
      }
    });
