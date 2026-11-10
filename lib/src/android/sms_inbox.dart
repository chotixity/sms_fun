import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';
import 'package:sms_fun/src/android/bindings.g.dart';

const mpesaSender = 'MPESA';

/// Bodies of all M-Pesa SMS in the inbox, newest first.
List<String> readMpesaMessages() => using((arena) {
      final ctx = androidApplicationContext.as(Context.type,
          releaseOriginal: true)
        ..releasedBy(arena);
      final resolver = ctx.contentResolver!..releasedBy(arena);

      final body = Telephony$TextBasedSmsColumns.BODY!..releasedBy(arena);
      final address = Telephony$TextBasedSmsColumns.ADDRESS!
          .toDartString(releaseOriginal: true);
      final date = Telephony$TextBasedSmsColumns.DATE!
          .toDartString(releaseOriginal: true);

      final cursor = resolver.query$1(
        Telephony$Sms$Inbox.CONTENT_URI?..releasedBy(arena),
        JArray.of<JString?>(JString.type, [body])..releasedBy(arena),
        '$address = ?'.toJString()..releasedBy(arena),
        JArray.of<JString?>(JString.type, [mpesaSender.toJString()..releasedBy(arena)])
          ..releasedBy(arena),
        '$date DESC'.toJString()..releasedBy(arena),
      );
      if (cursor == null) return <String>[];

      try {
        final bodyIdx = cursor.getColumnIndexOrThrow(body);
        final out = <String>[];
        while (cursor.moveToNext()) {
          final s = cursor.getString(bodyIdx);
          if (s != null) out.add(s.toDartString(releaseOriginal: true));
        }
        return out;
      } finally {
        cursor.close();
        cursor.release();
      }
    });
