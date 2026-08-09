import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureDevice();
  runApp(const RihlaApp());
}

/// تهيئةُ الجهاز للّعب رأسيًّا.
///
/// هذه إعداداتُ منصّةٍ قد لا تدعمها كلُّ البيئات (الويب مثلًا)،
/// فلا يجوز أن يمنع فشلُها إقلاعَ اللعبة.
Future<void> _configureDevice() async {
  if (kIsWeb) return;
  try {
    await Flame.device.setPortrait();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  } on Object catch (error, stackTrace) {
    debugPrint('تعذّر ضبطُ اتّجاه الشاشة: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
