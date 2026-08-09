import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../config/game_config.dart';

/// طبقةٌ خلفيّةٌ تتحرّك بجزءٍ من سرعة العالم فتُعطي إحساسَ العمق.
///
/// كلُّ طبقةٍ ترسم نفسَها بأشكالٍ هندسيّةٍ بسيطة؛ وهذه رسومٌ مؤقّتةٌ للنموذج
/// الأوّليّ، وموضعُ استبدالها بصورٍ نهائيّةٍ هو هذا الصنفُ وحدَه.
abstract class ScrollingLayer extends Component {
  ScrollingLayer({required this.parallaxFactor, super.priority});

  /// نسبة سرعة هذه الطبقة إلى سرعة العالم (١ = بسرعة الأرض).
  final double parallaxFactor;

  double offset = 0;

  /// المسافة التي تتكرّر عندها زخارفُ الطبقة.
  double get tileWidth;

  void scroll(double worldDistance) {
    offset = (offset + worldDistance * parallaxFactor) % tileWidth;
  }
}

/// السماء وقرصُ الشمس قربَ الغروب — ثابتةٌ لا تتحرّك.
class SkyLayer extends Component {
  SkyLayer({super.priority});

  @override
  void render(Canvas canvas) {
    final rect = const Rect.fromLTWH(
      0,
      0,
      GameConfig.worldWidth,
      GameConfig.horizonY + 40,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppPalette.skyTop,
            Color(0xFF7A6A7B),
            AppPalette.skyBottom,
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    canvas.drawCircle(
      const Offset(96, 344),
      52,
      Paint()..color = const Color(0xFFF6D79A).withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      const Offset(96, 344),
      78,
      Paint()..color = const Color(0xFFF6D79A).withValues(alpha: 0.16),
    );
  }
}

/// تلالٌ بعيدةٌ تتحرّك ببطء.
class HillsLayer extends ScrollingLayer {
  HillsLayer({required super.parallaxFactor, super.priority});

  @override
  double get tileWidth => 240;

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = AppPalette.hillsFar.withValues(alpha: 0.55);
    for (var i = -1; i < 4; i++) {
      final cx = i * tileWidth - offset + 60;
      final path = Path()
        ..moveTo(cx - 130, GameConfig.horizonY)
        ..quadraticBezierTo(
          cx,
          GameConfig.horizonY - 96,
          cx + 130,
          GameConfig.horizonY,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }
}

/// بيوتُ القرية وقبابُها ونخيلُها.
class VillageLayer extends ScrollingLayer {
  VillageLayer({required super.parallaxFactor, super.priority});

  @override
  double get tileWidth => 320;

  @override
  void render(Canvas canvas) {
    for (var i = -1; i < 4; i++) {
      final baseX = i * tileWidth - offset;
      _house(canvas, baseX + 24, 96, 78);
      _house(canvas, baseX + 132, 68, 54);
      _dome(canvas, baseX + 214, 66);
      _palm(canvas, baseX + 286);
    }
  }

  void _house(Canvas canvas, double x, double w, double h) {
    final top = GameConfig.horizonY - h;
    canvas.drawRect(
      Rect.fromLTWH(x, top, w, h),
      Paint()..color = AppPalette.hillsNear.withValues(alpha: 0.85),
    );
    // نافذةٌ مضيئةٌ واحدة تكسر الصمت البصريّ.
    canvas.drawRect(
      Rect.fromLTWH(x + w * 0.28, top + h * 0.32, w * 0.2, h * 0.2),
      Paint()..color = AppPalette.gold.withValues(alpha: 0.5),
    );
  }

  void _dome(Canvas canvas, double x, double r) {
    final center = Offset(x, GameConfig.horizonY - r * 0.2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      math.pi,
      math.pi,
      true,
      Paint()..color = AppPalette.hillsNear.withValues(alpha: 0.92),
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 2.5, GameConfig.horizonY - r * 1.5, 5, r * 0.35),
      Paint()..color = AppPalette.hillsNear,
    );
  }

  void _palm(Canvas canvas, double x) {
    final trunkPaint = Paint()
      ..color = AppPalette.woodDark.withValues(alpha: 0.8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(x, GameConfig.horizonY),
      Offset(x - 6, GameConfig.horizonY - 104),
      trunkPaint,
    );
    final frondPaint = Paint()
      ..color = const Color(0xFF3F5A44).withValues(alpha: 0.9)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const top = GameConfig.horizonY - 104;
    for (final angle in [-2.5, -1.9, -1.2, -0.6, -3.0]) {
      canvas.drawLine(
        Offset(x - 6, top),
        Offset(x - 6 + 34 * math.cos(angle), top + 34 * math.sin(angle)),
        frondPaint,
      );
    }
  }
}

/// الطريقُ الترابيّ وحوافُّه وحصاه المتحرّك.
class RoadLayer extends ScrollingLayer {
  RoadLayer({super.priority}) : super(parallaxFactor: 1);

  @override
  double get tileWidth => 96;

  @override
  void render(Canvas canvas) {
    const rect = Rect.fromLTRB(
      0,
      GameConfig.roadTopY,
      GameConfig.worldWidth,
      GameConfig.roadBottomY,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppPalette.roadTop, AppPalette.roadBottom],
        ).createShader(rect),
    );

    // شريطُ عشبٍ جافٍّ بين الأفق والطريق.
    canvas.drawRect(
      const Rect.fromLTRB(
        0,
        GameConfig.horizonY,
        GameConfig.worldWidth,
        GameConfig.roadTopY,
      ),
      Paint()..color = const Color(0xFF7B7A55),
    );

    final edgePaint = Paint()
      ..color = AppPalette.roadEdge
      ..strokeWidth = 3;
    canvas.drawLine(
      const Offset(0, GameConfig.roadTopY),
      const Offset(GameConfig.worldWidth, GameConfig.roadTopY),
      edgePaint,
    );
    canvas.drawLine(
      const Offset(0, GameConfig.roadBottomY),
      const Offset(GameConfig.worldWidth, GameConfig.roadBottomY),
      edgePaint,
    );

    // حصًى يتحرّك فيُشعِر بالسرعة.
    final pebble = Paint()..color = AppPalette.roadEdge.withValues(alpha: 0.35);
    for (var i = -1; i < 6; i++) {
      final x = i * tileWidth + offset;
      canvas.drawCircle(Offset(x, GameConfig.roadTopY + 46), 3.5, pebble);
      canvas.drawCircle(Offset(x + 38, GameConfig.roadBottomY - 34), 4.5, pebble);
      canvas.drawCircle(Offset(x + 64, 640), 3, pebble);
    }
  }
}
