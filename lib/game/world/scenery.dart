import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import 'perspective.dart';
import 'realm.dart';

/// حالةُ المشهد المشتركة: الإقليمُ الحاليّ والمسافةُ المقطوعة.
///
/// الطبقاتُ لا تحفظ حالتَها بنفسها بل تقرأ من هنا، فانتقالُ اللاعب إلى إقليمٍ
/// جديدٍ يسري على المشهد كلِّه في اللحظة نفسِها.
class SceneState {
  SceneState({Realm? realm}) : realm = realm ?? Realm.palmVillage;

  Realm realm;

  /// مجموعُ ما قطعه المسافرُ من وحدات العالم.
  double travelled = 0;

  /// شدّةُ الانطلاق الحاليّة (٠ إلى ١)؛ تُستعمل في خطوط السرعة.
  double turbo = 0;
}

/// السماءُ والقرصُ والنجومُ وخطُّ الأفق.
class SkyLayer extends Component {
  SkyLayer(this.scene, {super.priority});

  final SceneState scene;

  static final List<Offset> _stars = List.generate(54, (i) {
    final random = math.Random(i * 7919);
    return Offset(
      random.nextDouble() * GameConfig.worldWidth,
      random.nextDouble() * (GameConfig.horizonY - 40),
    );
  });

  @override
  void render(Canvas canvas) {
    final realm = scene.realm;
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
          colors: [realm.skyTop, realm.skyMid, realm.skyBottom],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(rect),
    );

    if (realm.hasStars) {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.72);
      for (var i = 0; i < _stars.length; i++) {
        canvas.drawCircle(_stars[i], i.isEven ? 1.4 : 1.0, paint);
      }
    }

    if (realm.showOrb) _renderOrb(canvas, realm);
    _renderSkyline(canvas, realm);
  }

  void _renderOrb(Canvas canvas, Realm realm) {
    const center = Offset(302, 176);
    canvas.drawCircle(
      center,
      96,
      Paint()..color = realm.orbGlow.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      62,
      Paint()..color = realm.orbGlow.withValues(alpha: 0.3),
    );
    canvas.drawCircle(center, 38, Paint()..color = realm.orb);
  }

  void _renderSkyline(Canvas canvas, Realm realm) {
    switch (realm.skyline) {
      case SkylineKind.domes:
        _domes(canvas, realm.structureFar.withValues(alpha: 0.72),
            GameConfig.horizonY, 0.62, 11, 46);
        _domes(canvas, realm.structureNear, GameConfig.horizonY + 2, 1.0, 29, 62);
      case SkylineKind.arches:
        _arches(canvas, realm.structureFar.withValues(alpha: 0.7), 0.7, 54);
        _arches(canvas, realm.structureNear, 1.0, 78);
      case SkylineKind.dunes:
        _dunes(canvas, realm.structureFar.withValues(alpha: 0.7), 74, 0);
        _dunes(canvas, realm.structureNear, 46, 120);
      case SkylineKind.colonnade:
        _colonnade(canvas, realm);
    }
  }

  void _domes(Canvas canvas, Color color, double baseY, double heightScale,
      int seed, double step) {
    final paint = Paint()..color = color;
    final random = math.Random(seed);

    for (var x = -20.0; x < GameConfig.worldWidth + 40; x += step) {
      final kind = random.nextInt(5);
      final width = step * (0.5 + random.nextDouble() * 0.32);
      final height = (26 + random.nextDouble() * 40) * heightScale;

      if (kind == 0) {
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
        canvas.drawRect(Rect.fromLTWH(x, baseY - height, width, height), paint);
      }
    }
  }

  /// جدارُ أقواسٍ متتابعة — هيئةُ سوقٍ مسقوف.
  void _arches(Canvas canvas, Color color, double scale, double step) {
    final paint = Paint()..color = color;
    final height = 62 * scale;
    final baseY = GameConfig.horizonY + 2;

    canvas.drawRect(
      Rect.fromLTWH(-20, baseY - height * 0.45, GameConfig.worldWidth + 40,
          height * 0.45),
      paint,
    );
    for (var x = -20.0; x < GameConfig.worldWidth + 40; x += step) {
      final width = step * 0.62;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(x + width / 2, baseY - height * 0.45),
          radius: width / 2,
        ),
        math.pi,
        math.pi,
        true,
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + width / 2 - 4, baseY - height, 8, height * 0.55),
        paint,
      );
    }
  }

  /// كثبانٌ متموّجة.
  void _dunes(Canvas canvas, Color color, double height, double phase) {
    final path = Path()..moveTo(-20, GameConfig.horizonY + 4);
    for (var x = -20.0; x < GameConfig.worldWidth + 40; x += 8) {
      final y = GameConfig.horizonY -
          height *
              (0.5 +
                  0.5 * math.sin((x + phase) / 120) *
                      math.cos((x + phase) / 61));
      path.lineTo(x, y);
    }
    path
      ..lineTo(GameConfig.worldWidth + 40, GameConfig.horizonY + 4)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  /// رواقٌ داخليّ: سقفٌ وأعمدةٌ تحدّ المشهد — لا سماءَ مفتوحة.
  void _colonnade(Canvas canvas, Realm realm) {
    canvas.drawRect(
      Rect.fromLTWH(0, GameConfig.horizonY - 96, GameConfig.worldWidth, 96),
      Paint()..color = realm.structureNear,
    );
    final paint = Paint()..color = realm.structureFar;
    for (var x = 6.0; x < GameConfig.worldWidth; x += 62) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(x + 22, GameConfig.horizonY - 34),
          radius: 22,
        ),
        math.pi,
        math.pi,
        true,
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x, GameConfig.horizonY - 34, 44, 36),
        paint,
      );
    }
  }
}

/// الطريقُ الممتدُّ إلى الأفق، وكسوتُه، وما يقوم على جانبيه، وما يطفو في هوائه.
class RoadLayer extends Component {
  RoadLayer(this.scene, {super.priority});

  final SceneState scene;

  static const double _bandLength = 96;
  static const double _propSpacing = 300;

  @override
  void render(Canvas canvas) {
    final realm = scene.realm;

    canvas.drawRect(
      const Rect.fromLTRB(
        0,
        GameConfig.horizonY,
        GameConfig.worldWidth,
        GameConfig.worldHeight,
      ),
      Paint()..color = realm.ground,
    );

    _renderRoad(canvas, realm);
    _renderRoadsides(canvas, realm);
    _renderParticles(canvas, realm);
    _renderHaze(canvas, realm);
    if (scene.turbo > 0.01) _renderSpeedLines(canvas);
  }

  void _renderRoad(Canvas canvas, Realm realm) {
    final offset = scene.travelled % _bandLength;
    final firstIndex = (scene.travelled / _bandLength).floor();

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
        Paint()..color = isLight ? realm.roadLight : realm.roadDark,
      );

      final scale = Perspective.scaleAt(zNear);
      final edgePaint = Paint()
        ..color = realm.roadEdge
        ..strokeWidth = math.max(1, 4 * scale);
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

      _renderSurfaceDetail(canvas, realm, zNear, zFar, nearHalf, farHalf,
          nearY, farY, isLight, scale);
    }
  }

  /// تفاصيلُ كسوة الطريق: بلاطٌ أو سجّادةٌ أو رملٌ أو تراب.
  void _renderSurfaceDetail(
    Canvas canvas,
    Realm realm,
    double zNear,
    double zFar,
    double nearHalf,
    double farHalf,
    double nearY,
    double farY,
    bool isLight,
    double scale,
  ) {
    const cx = GameConfig.worldWidth / 2;

    switch (realm.surface) {
      case RoadSurface.dirt:
        if (!isLight) return;
        final dashHalf = math.max(0.6, 3 * scale);
        canvas.drawPath(
          Path()
            ..moveTo(cx - dashHalf, nearY)
            ..lineTo(cx + dashHalf, nearY)
            ..lineTo(cx + dashHalf * farHalf / nearHalf, farY)
            ..lineTo(cx - dashHalf * farHalf / nearHalf, farY)
            ..close(),
          Paint()..color = realm.roadEdge.withValues(alpha: 0.5),
        );
      case RoadSurface.stoneTiles:
        // خطوطٌ طوليّةٌ تقسم البلاطَ إلى ثلاثة صفوف.
        final linePaint = Paint()
          ..color = realm.roadEdge.withValues(alpha: 0.45)
          ..strokeWidth = math.max(0.8, 2 * scale);
        for (final t in [-0.34, 0.34]) {
          canvas.drawLine(
            Offset(cx + nearHalf * t, nearY),
            Offset(cx + farHalf * t, farY),
            linePaint,
          );
        }
      case RoadSurface.carpet:
        // حاشيةٌ ذهبيّةٌ على جانبَي السجّادة.
        final trim = Paint()
          ..color = realm.roadEdge.withValues(alpha: 0.85)
          ..strokeWidth = math.max(1, 6 * scale);
        for (final t in [-0.86, 0.86]) {
          canvas.drawLine(
            Offset(cx + nearHalf * t, nearY),
            Offset(cx + farHalf * t, farY),
            trim,
          );
        }
        if (isLight) {
          canvas.drawCircle(
            Offset(cx, (nearY + farY) / 2),
            math.max(1, 7 * scale),
            Paint()..color = realm.roadEdge.withValues(alpha: 0.5),
          );
        }
      case RoadSurface.sand:
        // تموّجاتُ رملٍ خفيفة.
        if (!isLight) return;
        canvas.drawLine(
          Offset(cx - nearHalf * 0.6, nearY),
          Offset(cx + farHalf * 0.2, farY),
          Paint()
            ..color = realm.roadEdge.withValues(alpha: 0.2)
            ..strokeWidth = math.max(0.8, 3 * scale),
        );
    }
  }

  void _renderRoadsides(Canvas canvas, Realm realm) {
    final offset = scene.travelled % _propSpacing;
    final firstIndex = (scene.travelled / _propSpacing).floor();

    for (var k = 10; k >= 0; k--) {
      final z = k * _propSpacing - offset;
      if (!Perspective.isVisible(z)) continue;

      final scale = Perspective.scaleAt(z);
      final fade = 1 - Perspective.hazeAt(z);
      if (fade <= 0.04) continue;

      final sideX = GameConfig.roadHalfWidth + 46;
      final index = firstIndex + k;

      for (final sign in [-1.0, 1.0]) {
        _renderProp(canvas, realm, sign * sideX, z, scale, fade, index);
      }
    }
  }

  void _renderProp(Canvas canvas, Realm realm, double x, double z, double scale,
      double fade, int index) {
    switch (realm.roadside) {
      case RoadsideKind.palms:
        if (index.isEven) {
          _lamp(canvas, realm, x, z, scale, fade, 168);
        } else {
          _palm(canvas, x, z, scale, fade);
        }
      case RoadsideKind.marketColumns:
        _column(canvas, realm, x, z, scale, fade);
        if (index.isEven) _awning(canvas, realm, x, z, scale, fade);
      case RoadsideKind.cypressLanterns:
        if (index.isEven) {
          _lamp(canvas, realm, x, z, scale, fade, 132);
        } else {
          _cypress(canvas, x, z, scale, fade);
        }
      case RoadsideKind.libraryShelves:
        _shelf(canvas, realm, x, z, scale, fade);
      case RoadsideKind.dunes:
        if (index.isEven) {
          _acacia(canvas, x, z, scale, fade);
        } else {
          _rock(canvas, realm, x, z, scale, fade);
        }
    }
  }

  void _lamp(Canvas canvas, Realm realm, double x, double z, double scale,
      double fade, double height) {
    final base = Perspective.project(x, z);
    final top = Perspective.project(x, z, height: height);

    canvas.drawLine(
      base,
      top,
      Paint()
        ..color = realm.structureNear.withValues(alpha: 0.88 * fade)
        ..strokeWidth = math.max(1, 7 * scale),
    );
    canvas.drawCircle(
      top,
      math.max(1, 11 * scale),
      Paint()..color = realm.lampGlow.withValues(alpha: 0.95 * fade),
    );
    canvas.drawCircle(
      top,
      math.max(2, 28 * scale),
      Paint()..color = realm.lampGlow.withValues(alpha: 0.2 * fade),
    );
  }

  void _palm(Canvas canvas, double x, double z, double scale, double fade) {
    final base = Perspective.project(x, z);
    final crown = Perspective.project(x, z, height: 200);

    canvas.drawLine(
      base,
      crown,
      Paint()
        ..color = const Color(0xFF5C4326).withValues(alpha: 0.9 * fade)
        ..strokeWidth = math.max(1, 9 * scale)
        ..strokeCap = StrokeCap.round,
    );
    final frond = Paint()
      ..color = const Color(0xFF3F5A44).withValues(alpha: 0.92 * fade)
      ..strokeWidth = math.max(1, 6 * scale)
      ..strokeCap = StrokeCap.round;
    for (final angle in [-2.7, -2.1, -1.57, -1.0, -0.45]) {
      canvas.drawLine(
        crown,
        crown + Offset(math.cos(angle), math.sin(angle)) * (58 * scale),
        frond,
      );
    }
  }

  /// عمودٌ حجريٌّ بتاجٍ — هيئةُ السوق المسقوف.
  void _column(Canvas canvas, Realm realm, double x, double z, double scale,
      double fade) {
    final base = Perspective.project(x, z);
    final top = Perspective.project(x, z, height: 210);
    final width = math.max(1.5, 26 * scale);

    canvas.drawRect(
      Rect.fromLTRB(base.dx - width / 2, top.dy, base.dx + width / 2, base.dy),
      Paint()..color = realm.structureNear.withValues(alpha: 0.95 * fade),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, top.dy),
        width: width * 1.6,
        height: math.max(1.5, 16 * scale),
      ),
      Paint()..color = realm.structureFar.withValues(alpha: fade),
    );
  }

  void _awning(Canvas canvas, Realm realm, double x, double z, double scale,
      double fade) {
    final anchor = Perspective.project(x, z, height: 190);
    final inner = Perspective.project(x * 0.55, z, height: 150);
    canvas.drawPath(
      Path()
        ..moveTo(anchor.dx, anchor.dy)
        ..lineTo(inner.dx, inner.dy)
        ..lineTo(inner.dx, inner.dy + math.max(2, 22 * scale))
        ..lineTo(anchor.dx, anchor.dy + math.max(2, 26 * scale))
        ..close(),
      Paint()..color = const Color(0xFFB5563F).withValues(alpha: 0.85 * fade),
    );
  }

  /// سروٌ مخروطيّ.
  void _cypress(Canvas canvas, double x, double z, double scale, double fade) {
    final base = Perspective.project(x, z);
    final top = Perspective.project(x, z, height: 236);
    final width = math.max(2.0, 34 * scale);

    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(base.dx + width / 2, base.dy)
        ..lineTo(base.dx - width / 2, base.dy)
        ..close(),
      Paint()..color = const Color(0xFF20402F).withValues(alpha: 0.95 * fade),
    );
  }

  /// رفُّ كتبٍ ملوّنٌ يحدّ الرواق.
  void _shelf(Canvas canvas, Realm realm, double x, double z, double scale,
      double fade) {
    final base = Perspective.project(x, z);
    final top = Perspective.project(x, z, height: 260);
    final width = math.max(3.0, 92 * scale);

    canvas.drawRect(
      Rect.fromLTRB(base.dx - width / 2, top.dy, base.dx + width / 2, base.dy),
      Paint()..color = realm.structureNear.withValues(alpha: fade),
    );

    // كعوبُ الكتب: خطوطٌ رأسيّةٌ ملوّنة.
    const spines = [
      Color(0xFFB5563F),
      Color(0xFF3F6B5A),
      Color(0xFFC9A227),
      Color(0xFF5A6B99),
    ];
    final shelfHeight = base.dy - top.dy;
    for (var row = 0; row < 3; row++) {
      final rowY = top.dy + shelfHeight * (0.18 + row * 0.28);
      for (var i = 0; i < 5; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            base.dx - width / 2 + width * (0.1 + i * 0.17),
            rowY,
            math.max(0.8, width * 0.11),
            math.max(1.2, shelfHeight * 0.2),
          ),
          Paint()
            ..color = spines[(i + row) % spines.length]
                .withValues(alpha: 0.92 * fade),
        );
      }
    }
  }

  void _acacia(Canvas canvas, double x, double z, double scale, double fade) {
    final base = Perspective.project(x, z);
    final crown = Perspective.project(x, z, height: 150);

    canvas.drawLine(
      base,
      crown,
      Paint()
        ..color = const Color(0xFF6B5330).withValues(alpha: 0.9 * fade)
        ..strokeWidth = math.max(1, 8 * scale),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: crown,
        width: math.max(3, 130 * scale),
        height: math.max(2, 40 * scale),
      ),
      Paint()..color = const Color(0xFF6E7F4A).withValues(alpha: 0.9 * fade),
    );
  }

  void _rock(Canvas canvas, Realm realm, double x, double z, double scale,
      double fade) {
    final base = Perspective.project(x, z);
    final size = math.max(2.0, 62 * scale);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - size / 2, base.dy)
        ..lineTo(base.dx - size * 0.2, base.dy - size * 0.7)
        ..lineTo(base.dx + size * 0.3, base.dy - size * 0.5)
        ..lineTo(base.dx + size / 2, base.dy)
        ..close(),
      Paint()..color = realm.structureNear.withValues(alpha: 0.9 * fade),
    );
  }

  /// ما يطفو في هواء الإقليم: غبارٌ أو يراعاتٌ أو شررٌ.
  void _renderParticles(Canvas canvas, Realm realm) {
    if (realm.particle == AmbientParticle.none) return;

    final color = switch (realm.particle) {
      AmbientParticle.dust => const Color(0xFFFFE9C4),
      AmbientParticle.fireflies => const Color(0xFFCFF58A),
      AmbientParticle.embers => const Color(0xFFFFA24C),
      AmbientParticle.none => Colors.transparent,
    };

    for (var i = 0; i < 22; i++) {
      final random = math.Random(i * 3571);
      final speed = 0.25 + random.nextDouble() * 0.7;
      final baseX = random.nextDouble() * GameConfig.worldWidth;
      final drift = math.sin((scene.travelled * 0.004) + i) * 18;
      final y = GameConfig.horizonY +
          ((scene.travelled * speed * 0.35 + i * 97) %
              (GameConfig.worldHeight - GameConfig.horizonY));
      canvas.drawCircle(
        Offset((baseX + drift) % GameConfig.worldWidth, y),
        1.2 + random.nextDouble() * 1.6,
        Paint()..color = color.withValues(alpha: 0.42),
      );
    }
  }

  void _renderHaze(Canvas canvas, Realm realm) {
    final rect = Rect.fromLTRB(
      0,
      GameConfig.horizonY,
      GameConfig.worldWidth,
      Perspective.groundY(GameConfig.hazeStartZ * 0.55),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            realm.hazeColor.withValues(alpha: GameConfig.hazeMaxOpacity),
            realm.hazeColor.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  /// خطوطُ سرعةٍ تنبثق من الأفق أثناء الانطلاق.
  void _renderSpeedLines(Canvas canvas) {
    final strength = scene.turbo.clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2 * strength)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const center = Offset(GameConfig.worldWidth / 2, GameConfig.horizonY + 30);
    for (var i = 0; i < 14; i++) {
      final angle = (i / 14) * math.pi * 2;
      final phase = (scene.travelled * 0.02 + i * 0.37) % 1.0;
      final start = 60 + phase * 220;
      final end = start + 60 + 90 * strength;
      final direction = Offset(math.cos(angle), math.sin(angle) * 0.72);
      canvas.drawLine(
        center + direction * start,
        center + direction * end,
        paint,
      );
    }
  }
}
