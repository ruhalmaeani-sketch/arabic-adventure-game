import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../config/game_config.dart';

enum PlayerState { running, celebrating, stumbling }

/// شخصيّة اللاعب: طالبُ علمٍ في ثوبٍ بسيط، يمشي في اتّجاه القراءة (نحو اليسار).
///
/// الرسمُ هنا إجرائيٌّ مؤقّت. حين تجهز الهويّةُ البصريّة يُستبدَل جسمُ [render]
/// بمكوّن رسومٍ متحرّكة دون أن تتغيّر واجهةُ الصنف ولا منطقُ اللعبة.
class PlayerCharacter extends PositionComponent {
  PlayerCharacter()
      : super(
          position: Vector2(GameConfig.playerX, GameConfig.laneCenters.first),
          size: Vector2(64, GameConfig.playerHeight),
          anchor: Anchor.bottomCenter,
          priority: 30,
        ) {
    _targetY = GameConfig.laneCenters.first;
  }

  late double _targetY;
  double _phase = 0;
  double _stateTimer = 0;

  PlayerState state = PlayerState.running;

  /// الارتفاع الذي يسعى اللاعب إليه؛ يُحدّده إصبعُ اللاعب أو انجذابُ المسار.
  double get targetY => _targetY;

  set targetY(double value) {
    _targetY = value.clamp(
      GameConfig.laneCenters.first - GameConfig.laneOvershoot,
      GameConfig.laneCenters.last + GameConfig.laneOvershoot,
    );
  }

  /// فهرس أقرب مسارٍ إلى موضع اللاعب الآن — وهو إجابتُه إن عبَر البوابة الآن.
  int get nearestLaneIndex {
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < GameConfig.laneCenters.length; i++) {
      final distance = (GameConfig.laneCenters[i] - position.y).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }

  void setState(PlayerState next, {double duration = 1.0}) {
    state = next;
    _stateTimer = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_stateTimer > 0) {
      _stateTimer -= dt;
      if (_stateTimer <= 0) state = PlayerState.running;
    }

    final speed = state == PlayerState.stumbling ? 4.0 : 1.0;
    _phase += dt * (state == PlayerState.stumbling ? 4 : 11);

    position.y += (_targetY - position.y) *
        (GameConfig.playerFollowSpeed * dt / speed).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // القدم عند y = h (المرساة أسفل الوسط)، والرأس أعلى.
    final bob = state == PlayerState.stumbling
        ? 0.0
        : math.sin(_phase) * 2.2;
    final lean = state == PlayerState.stumbling ? -0.16 : 0.0;

    canvas.save();
    canvas.translate(w / 2, h + bob);
    canvas.rotate(lean);

    // الظلّ
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 46, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    final swing = math.sin(_phase) * 11;

    // الساقان
    final legPaint = Paint()
      ..color = AppPalette.robeShade
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(0, -26),
      Offset(-swing * 0.6, 0),
      legPaint,
    );
    canvas.drawLine(
      const Offset(0, -26),
      Offset(swing * 0.6, 0),
      legPaint,
    );

    // الثوب
    final robe = Path()
      ..moveTo(-13, -76)
      ..lineTo(13, -76)
      ..lineTo(20, -20)
      ..quadraticBezierTo(0, -12, -20, -20)
      ..close();
    canvas.drawPath(robe, Paint()..color = AppPalette.robe);
    canvas.drawPath(
      robe,
      Paint()
        ..color = AppPalette.woodDark.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // الحزام
    canvas.drawRect(
      const Rect.fromLTWH(-15, -56, 30, 7),
      Paint()..color = AppPalette.sash,
    );

    // الذراع الأمامية (نحو اليسار، جهة السير)
    canvas.drawLine(
      const Offset(-8, -70),
      Offset(-20 - swing * 0.35, -46),
      Paint()
        ..color = AppPalette.robe
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // الرأس والعمامة
    canvas.drawCircle(
      const Offset(-2, -86),
      11,
      Paint()..color = AppPalette.skin,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-2, -88), radius: 13),
      math.pi,
      math.pi,
      true,
      Paint()..color = AppPalette.sash,
    );

    canvas.restore();

    if (state == PlayerState.celebrating) {
      canvas.drawCircle(
        Offset(w / 2, h - 52),
        44,
        Paint()..color = AppPalette.gold.withValues(alpha: 0.18),
      );
    }
  }
}
