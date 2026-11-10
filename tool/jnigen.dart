import 'dart:io';

import 'package:jnigen/jnigen.dart';

void main(List<String> args) async {
  final packageRoot = Platform.script.resolve('../');

  final generator = JniGenerator(
    input: Input(
      classes: [
        // App bridge (Kotlin)
        'com.example.sms_fun.SmsBridge',
        'com.example.sms_fun.IncomingSmsListener',
        'com.example.sms_fun.WidgetBridge',
        'com.example.sms_fun.WidgetUpdateListener',
        // Home-widget plumbing, driven entirely from Dart.
        'android.appwidget.AppWidgetManager',
        'android.widget.RemoteViews',
        'android.content.ComponentName',
        'android.app.PendingIntent',
        'android.content.Intent',
        'android.content.SharedPreferences',
        'android.content.pm.PackageManager',
        'android.content.res.Resources',
        // Nested classes can't be listed on their own; this pulls in every
        // Telephony$* class, trimmed below by OnlyNestedClasses.
        'android.provider.Telephony',
        'android.telephony.SmsMessage',
        'android.content.Context',
        'android.content.ContentResolver',
        'android.database.Cursor',
      ],
      backend: SummarizerBackend.asm,
      // AGP 9's built-in Kotlin output. Run `flutter build apk --debug` first.
      classPath: [
        packageRoot.resolve(
          'build/app/intermediates/built_in_kotlinc/debug/compileDebugKotlin/classes/',
        ),
      ],
      androidSdk: AndroidSdk(addGradleDeps: true, androidExample: packageRoot),
    ),
    output: Output(
      dart: DartOutput(
        path: packageRoot.resolve('lib/src/android/bindings.g.dart'),
        structure: OutputStructure.singleFile,
      ),
    ),
    visitors: [
      OnlyNestedClasses('android.provider.Telephony', {
        'Sms',
        'Sms\$Inbox', // CONTENT_URI
        'Sms\$Intents', // getMessagesFromIntent(Intent)
        'TextBasedSmsColumns', // ADDRESS, BODY, DATE
      }),
      OnlyNestedClasses('android.content.SharedPreferences', {'Editor'}),
      OnlyMethods({
        'android.content.Context': {
          'getContentResolver',
          'getPackageName',
          'getPackageManager',
          'getResources',
          'getSharedPreferences',
        },
        'android.appwidget.AppWidgetManager': {'getInstance', 'getAppWidgetIds', 'updateAppWidget'},
        'android.widget.RemoteViews': {'<init>', 'setTextViewText', 'setOnClickPendingIntent'},
        'android.content.ComponentName': {'<init>'},
        'android.app.PendingIntent': {'getActivity'},
        'android.content.pm.PackageManager': {'getLaunchIntentForPackage'},
        'android.content.res.Resources': {'getIdentifier'},
        'android.content.SharedPreferences': {'getString', 'edit'},
        'android.content.SharedPreferences\$Editor': {'putString', 'apply'},
      }),
    ],
  );

  await generator.generate();
}

/// Excludes every nested class of [outer] except those in [keep].
///
/// [keep] holds names relative to [outer], e.g. `Sms$Inbox` for
/// `android.provider.Telephony$Sms$Inbox`. [outer] itself stays included.
final class OnlyNestedClasses extends Visitor {
  OnlyNestedClasses(this.outer, this.keep) : super.base();

  final String outer;
  final Set<String> keep;

  @override
  void visitClass(ClassDecl c) {
    final prefix = '$outer\$';
    if (c.binaryName.startsWith(prefix) &&
        !keep.contains(c.binaryName.substring(prefix.length))) {
      c.isIncluded = false;
    }
  }
}

/// Keeps only the listed methods of the given classes.
///
/// `Method` has no link to its owning class, but jnigen visits each class
/// right before its methods (`ClassDecl.accept`), so we remember the current
/// class in `visitClass`.
final class OnlyMethods extends Visitor {
  OnlyMethods(this.keep) : super.base();

  final Map<String, Set<String>> keep;
  Set<String>? _current;

  @override
  void visitClass(ClassDecl c) => _current = keep[c.binaryName];

  @override
  void visitMethod(Method m) {
    final allowed = _current;
    if (allowed != null && !allowed.contains(m.originalName)) {
      m.isIncluded = false;
    }
  }
}
