import 'dart:async';

import 'package:jni/jni.dart';
import 'package:sms_fun/src/android/bindings.g.dart';
import 'package:sms_fun/src/android/sms_inbox.dart';

/// Emits the body of each M-Pesa SMS received while this isolate is alive.
///
/// Backed by `SmsBridge` in MainActivity.kt, which `SmsReceiver` forwards
/// every SMS_RECEIVED intent to.
Stream<String> incomingMpesaMessages() {
  IncomingSmsListener? listener;
  late final StreamController<String> controller;
  controller = StreamController<String>(
    onListen: () {
      listener = IncomingSmsListener.implement($IncomingSmsListener(
        onSmsReceived: (intent) {
          final body = _mpesaBodyFromIntent(intent);
          intent.release();
          if (body != null) controller.add(body);
        },
        // onReceive runs on Android's main thread; don't block it.
        onSmsReceived$async: true,
      ));
      SmsBridge.listener = listener;
    },
    onCancel: () {
      SmsBridge.listener = null;
      listener?.release();
      listener = null;
    },
  );
  return controller.stream;
}

String? _mpesaBodyFromIntent(Intent intent) => using((arena) {
      final parts = Telephony$Sms$Intents.getMessagesFromIntent(intent)
        ?..releasedBy(arena);
      if (parts == null || parts.length == 0) return null;

      final first = parts[0]?..releasedBy(arena);
      final sender =
          first?.originatingAddress?.toDartString(releaseOriginal: true);
      if (sender != mpesaSender) return null;

      // A long M-Pesa SMS arrives as several parts in one intent; join them.
      final body = StringBuffer();
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i]?..releasedBy(arena);
        body.write(part?.messageBody?.toDartString(releaseOriginal: true) ?? '');
      }
      return body.toString();
    });
