import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import 'atmosphere.dart';
import 'perspective.dart';

/// حالةُ المشهد المشتركة بين الطبقات: الجوُّ الحاليّ والمسافةُ المقطوعة.
///
/// الطبقاتُ لا تحفظ حالتَها بنفسها، بل تقرأ من هنا؛ فتبديلُ الجوّ يسري على
/// المشهد كلِّه في اللحظة نفسِها.
class SceneState {
  SceneState({Atmosphere? atmosphere})
      : atmosphere = atmosphere ?? Atmosphere.dusk;

  Atmosphere atmosphere;

  /// مجموعُ ما قطعه المسافرُ من وحدات العالم.
  double travelled = 0;
}

/// السماءُ والقرصُ والنجومُ والمدينةُ البعيدة.
class SkyLayer extends Component {
  SkyLayer(this.scene, {super.priority});

  final SceneState scene;

  /// مواضعُ ثابتةٌ للنجوم كي لا ترتجف بين الإطارات.
  static final List<Offset> _stars = List.generate(46, (i) {
    final random = math.Random(i * 7919);
    return Offset(
      random.nextDouble() * GameConfig.worldWidth,
      random.nextDouble() * (GameConfig.horizonY - 40),
    );
  });

  @override
  void render(Canvas canvas) {
    final sky = scene.atmosphere;
    const rect = Rect.fromLTWH(
      0,
      0,
      GameConfig.worldWidth,
      GameConfig.horizonY + 2,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.skyTop, sky.skyMid, sky.skyBottom],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(rect),
    );

    if (sky.hasStars) {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);
      for (var i = 0; i < _stars.length; i++) {
        canvas.drawCircle(_stars[i], i.isEven ? 1.4 : 1.0, paint);
      }
    }

    _renderOrb(canvas, sky);
    _renderCity(canvas, sky);
  }

  void _renderOrb(Canvas canvas, Atmosphere sky) {
    const center = Offset(302, 176);
    canvas.drawCircle(
      center,
      96,
      Paint()..color = sky.orbGlow.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      62,
      Paint()..color = sky.orbGlow.withValues(alpha: 0.3),
    );
    canvas.drawCircle(center, 38, Paint()..color = sky.orb);
  }

  /// خطُّ المدينة عند الأفق: قبابٌ ومآذنُ وبيوتٌ في طبقتين تعطيان عمقًا.
  void _renderCity(Canvas canvas, Atmosphere sky) {
    _renderSkyline(
      canvas,
      color: sky.cityFar.withValues(alpha: 0.75),
      baseY: GameConfig.horizonY,
      heightScale: 0.62,
      seed: 11,
      step: 46,
    );
    _renderSkyline(
      canvas,
      color: sky.cityNear,
      baseY: GameConfig.horizonY + 2,
      heightScale: 1.0,
      seed: 29,
      step: 62,
    );
  }

  void _renderSkyline(
    Canvas canvas, {
    required Color color,
    required double baseY,
    required double heightScale,
    required int seed,
    required double step,
  }) {
    final paint = Paint()..color = color;
    final random = math.Random(seed);

    for (var x = -20.0; x < GameConfig.worldWidth + 40; x += step) {
      final kind = random.nextInt(5);
      final width = step * (0.5 + random.nextDouble() * 0.32);
      final height = (26 + random.nextDouble() * 40) * heightScale;

      if (kind == 0) {
        // مئذنة
        canvas.drawRect(
          Rect.fromLTWH(x, baseY - height * 1.9, width * 0.34, height * 1.9),
          paint,
        );
        canvas.drawCircle(
          Offset(x + width * 0.17, baseY - height * 1.9),
          width * 0.24,
          paint,
        );
      } else if (kind == 1) {
        // قبّة
        final radius = width * 0.5;
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(x + radius, baseY - height * 0.5),
            radius: radius,
          ),
          math.pi,
          math.pi,
          true,
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(x, baseY - height * 0.5, width, height * 0.5),
          paint,
        );
      } else {
        // بيتٌ بسطحٍ مستوٍ
        canvas.drawRect(Rect.fromLTWH(x, baseY - height, width, height), paint);
      }
    }
  }
}

/// الطريقُ الممتدُّ إلى الأفق، وأشرطتُه المتحرّكة، وحوافُّه، وما على جانبيه.
class RoadLayer extends Component {
  RoadLayer(this.scene, {super.priority});

  final SceneState scene;

  /// طولُ الشريط العَرْضيّ الواحد؛ تعاقبُ الأشرطة هو ما يُشعر بالسرعة.
  static const double _bandLength = 96;

  /// كلُّ كم وحدةٍ يقوم مصباحٌ على جانب الطريق.
  static const double _lampSpacing = 320;

  @override
  void render(Canvas canvas) {
    final sky = scene.atmosphere;

    // الأرضُ الممتدّة تحت الأفق.
    canvas.drawRect(
      const Rect.fromLTRB(
        0,
        GameConfig.horizonY,
        GameConfig.worldWidth,
        GameConfig.worldHeight,
      ),
      Paint()..color = sky.ground,
    );

    _renderRoadBands(canvas, sky);
    _renderRoadsides(canvas, sky);
    _renderHaze(canvas, sky);
  }

  void _renderRoadBands(Canvas canvas, Atmosphere sky) {
    final offset = scene.travelled % _bandLength;
    final firstIndex = (scene.travelled / _bandLength).floor();

    // من البعيد إلى القريب، ليعلوَ القريبُ البعيدَ عند التداخل.
    for (var k = 24; k >= 0; k--) {
      final zNear = k * _bandLength - offset;
      final zFar = zNear + _bandLength;
      if (zFar <= GameConfig.nearClipZ) continue;

      final nearHalf = Perspective.roadHalfWidthAt(zNear);
      final farHalf = Perspective.roadHalfWidthAt(zFar);
      final nearY = Perspective.groundY(zNear);
      final farY = Perspective.groundY(zFar);
      if ((nearY - farY).abs() < 0.4) continue;

      const cx = GameConfig.worldWidth / 2;
      final band = Path()
        ..moveTo(cx - nearHalf, nearY)
        ..lineTo(cx + nearHalf, nearY)
        ..lineTo(cx + farHalf, farY)
        ..lineTo(cx - farHalf, farY)
        ..close();

      final isLight = (firstIndex + k).isEven;
      canvas.drawPath(
        band,
        Paint()..color = isLight ? sky.roadLight : sky.roadDark,
      );

      // خطّا الحافّة، وشُرطةُ المنتصف الفاصلة بين المسارين.
      final edgePaint = Paint()
        ..color = sky.roadEdge
        ..strokeWidth = math.max(1, 4 * Perspective.scaleAt(zNear));
      canvas.drawLine(
        Offset(cx - nearHalf, nearY),
        Offset(cx - farHalf, farY),
        edgePaint,
      );
      canvas.drawLine(
        Offset(cx + nearHalf, nearY),
        Offset(cx + farHalf, farY),
        edgePaint,
      );

      if (isLight) {
        final dashHalf = math.max(0.6, 3 * Perspective.scaleAt(zNear));
        canvas.drawPath(
          Path()
            ..moveTo(cx - dashHalf, nearY)
            ..lineTo(cx + dashHalf, nearY)
            ..lineTo(cx + dashHalf * farHalf / nearHalf, farY)
            ..lineTo(cx - dashHalf * farHalf / nearHalf, farY)
            ..close(),
          Paint()..color = sky.roadEdge.withValues(alpha: 0.55),
        );
      }
    }
  }

  /// أعمدةُ الإنارة والنخيلُ على الجانبين — أقوى ما يصنع الإحساسَ بالعمق،
  /// لأنّ تتابعَ مرورِها يقيس السرعةَ للعين.
  void _renderRoadsides(Canvas canvas, Atmosphere sky) {
    final offset = scene.travelled % _lampSpacing;
    final firstIndex = (scene.travelled / _lampSpacing).floor();

    for (var k = 9; k >= 0; k--) {
      final z = k * _lampSpacing - offset;
      if (!Perspective.isVisible(z)) continue;

      final scale = Perspective.scaleAt(z);
      final haze = Perspective.hazeAt(z);
      final sideX = GameConfig.roadHalfWidth + 42;
      final index = firstIndex + k;

      for (final sign in [-1.0, 1.0]) {
        if (index.isEven) {
          _renderLamp(canvas, sky, sign * sideX, z, scale, haze);
        } else {
          _renderPalm(canvas, sky, sign * sideX, z, scale, haze);
        }
      }
    }
  }

  void _renderLamp(
    Canvas canvas,
    Atmosphere sky,
    double x,
    double z,
    double scale,
    double haze,
  ) {
    final base = Perspective.project(x, z);
    final top = Perspective.project(x, z, height: 168);
    final fade = 1 - haze;

    canvas.drawLine(
      base,
      top,
      Paint()
        ..color = sky.cityNear.withValues(alpha: 0.85 * fade)
        ..strokeWidth = math.max(1, 7 * scale),
    );
    canvas.drawCircle(
      top,
      math.max(1, 11 * scale),
      Paint()..color = sky.lampGlow.withValues(alpha: 0.95 * fade),
    );
    canvas.drawCircle(
      top,
      math.max(2, 26 * scale),
      Paint()..color = sky.lampGlow.withValues(alpha: 0.18 * fade),
    );
  }

  void _renderPalm(
    Canvas canvas,
    Atmosphere sky,
    double x,
    double z,
    double scale,
    double haze,
  ) {
    final base = Perspective.project(x, z);
    final crown = Perspective.project(x, z, height: 200);
    final fade = 1 - haze;

    canvas.drawLine(
      base,
      crown,
      Paint()
        ..color = const Color(0xFF5C4326).withValues(alpha: 0.9 * fade)
        ..strokeWidth = math.max(1, 9 * scale)
        ..strokeCap = StrokeCap.round,
    );

    final frondPaint = Paint()
      ..color = const Color(0xFF3F5A44).withValues(alpha: 0.92 * fade)
      ..strokeWidth = math.max(1, 6 * scale)
      ..strokeCap = StrokeCap.round;
    for (final angle in [-2.7, -2.1, -1.57, -1.0, -0.45]) {
      canvas.drawLine(
        crown,
        crown +
            Offset(math.cos(angle), math.sin(angle)) * (58 * scale),
        frondPaint,
      );
    }
  }

  /// ضبابُ الأفق: يذيب البعيدَ في لون السماء فيبدو العمقُ مقنعًا.
  void _renderHaze(Canvas canvas, Atmosphere sky) {
    final hazeTop = GameConfig.horizonY;
    final hazeBottom = Perspective.groundY(GameConfig.hazeStartZ * 0.55);
    final rect = Rect.fromLTRB(
      0,
      hazeTop,
      GameConfig.worldWidth,
      hazeBottom,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sky.hazeColor.withValues(alpha: GameConfig.hazeMaxOpacity),
            sky.hazeColor.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }
}
