import 'dart:math' as math;
import 'dart:ui';

import '../config/game_config.dart';

/// إسقاطُ المنظور: يحوّل موضعًا في عالمٍ ذي عمقٍ إلى نقطةٍ على الشاشة.
///
/// العالم ثلاثيُّ الإحداثيّات:
/// * `x` انحرافٌ جانبيٌّ عن محور الطريق (السالب يسارًا).
/// * `z` بُعدٌ أمام الكاميرا؛ كلّما كبر ابتعد الشيءُ ودنا من الأفق.
/// * `h` ارتفاعٌ فوق سطح الطريق.
///
/// معاملُ التصغير `scale = focal / (focal + z)` يساوي واحدًا عند قدمَي
/// الكاميرا ويؤول إلى الصفر عند الأفق، فهو الذي يصنع الإحساسَ بالعمق:
/// به تُصغَّر الأحجام، وتُقرَّب الأشياءُ من محور الطريق، ويُرفَع موضعُها
/// نحو الأفق.
class Perspective {
  const Perspective._();

  /// معاملُ التصغير عند بُعدٍ معيّن. القيمة في المجال (٠، ١].
  static double scaleAt(double z) {
    final depth = math.max(z, -GameConfig.focalLength * 0.9);
    return GameConfig.focalLength / (GameConfig.focalLength + depth);
  }

  /// ارتفاعُ نقطةِ الأرض على الشاشة عند بُعدٍ معيّن.
  static double groundY(double z) {
    final scale = scaleAt(z);
    return GameConfig.horizonY +
        (GameConfig.roadBaseY - GameConfig.horizonY) * scale;
  }

  /// يُسقِط نقطةً من العالم إلى الشاشة.
  static Offset project(double x, double z, {double height = 0}) {
    final scale = scaleAt(z);
    return Offset(
      GameConfig.worldWidth / 2 + x * scale,
      groundY(z) - height * scale,
    );
  }

  /// نصفُ عرض الطريق على الشاشة عند بُعدٍ معيّن.
  static double roadHalfWidthAt(double z) =>
      GameConfig.roadHalfWidth * scaleAt(z);

  /// هل يقع هذا البُعد داخل المدى المرئيّ؟
  static bool isVisible(double z) =>
      z > GameConfig.nearClipZ && z < GameConfig.farClipZ;

  /// شدّةُ الضباب عند بُعدٍ معيّن: صفرٌ قريبًا، وواحدٌ عند الأفق.
  ///
  /// الضبابُ ليس زينةً فحسب؛ هو ما يُذيب الأشياءَ البعيدة في لون الأفق
  /// فيبدو العمقُ مقنعًا بدل أن تظهر الأشياءُ حادّةً وهي صغيرة.
  static double hazeAt(double z) {
    if (z <= GameConfig.hazeStartZ) return 0;
    final span = GameConfig.farClipZ - GameConfig.hazeStartZ;
    return ((z - GameConfig.hazeStartZ) / span).clamp(0.0, 1.0) *
        GameConfig.hazeMaxOpacity;
  }
}
