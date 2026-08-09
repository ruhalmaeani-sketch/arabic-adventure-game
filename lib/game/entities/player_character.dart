import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../config/game_config.dart';
import '../world/perspective.dart';

enum PlayerState { running, celebrating, stumbling }

/// شخصيّة اللاعب: طالبُ علمٍ يصعد الطريقَ مبتعدًا عن الكاميرا.
///
/// نراه من الخلف، فالمشهدُ منظورٌ من وراء كتفه؛ ولذلك لا وجهَ له ولا ملامح،
/// وإنّما ثوبٌ وعمامةٌ وخطوٌ. الرسمُ إجرائيٌّ مؤقّت، وموضعُ استبداله بصورٍ
/// نهائيّةٍ هو [render] وحدَه.
class PlayerCharacter extends Component {
  PlayerCharacter({super.priority});

  /// انحرافُ اللاعب الجانبيّ عن محور الطريق.
  double lateralX = 0;

  double _targetX = 0;
  double _phase = 0;
  double _stateTimer = 0;
  double _lean = 0;

  PlayerState state = PlayerState.running;

  double get targetX => _targetX;

  set targetX(double value) {
    final limit =
        GameConfig.laneOffsets.first.abs() + GameConfig.laneOvershoot;
    _targetX = value.clamp(-limit, limit);
  }

  /// فهرسُ أقرب مسارٍ إلى موضع اللاعب الآن — وهو إجابتُه إن عبَر البوابة الآن.
  int get nearestLaneIndex {
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < GameConfig.laneOffsets.length; i++) {
      final distance = (GameConfig.laneOffsets[i] - lateralX).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }

  /// موضعُ رأس اللاعب على الشاشة، لتنطلق منه النصوصُ الطائرة.
  Offset get headScreenPosition => Perspective.project(
        lateralX,
        GameConfig.playerZ,
        height: GameConfig.playerHeight,
      );

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

    _phase += dt * (state == PlayerState.stumbling ? 4.5 : 12);

    final previousX = lateralX;
    lateralX += (_targetX - lateralX) *
        (GameConfig.playerFollowSpeed * dt).clamp(0.0, 1.0);

    // ميلٌ خفيفٌ في اتّجاه الانعطاف يعطي الحركةَ إحساسًا بالوزن.
    final drift = (lateralX - previousX) / math.max(dt, 0.0001);
    _lean += ((drift * 0.0016).clamp(-0.28, 0.28) - _lean) *
        (6 * dt).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final scale = Perspective.scaleAt(GameConfig.playerZ);
    final feet = Perspective.project(lateralX, GameConfig.playerZ);

    canvas.save();
    canvas.translate(feet.dx, feet.dy);
    canvas.scale(scale);

    final bob = state == PlayerState.stumbling ? 0.0 : math.sin(_phase) * 2.6;
    canvas.translate(0, bob);

    // الظلّ على الأرض.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 58, height: 15),
      Paint()..color = Colors.black.withValues(alpha: 0.26),
    );

    canvas.rotate(_lean);

    final swing = math.sin(_phase) * 13;

    // الساقان
    final legPaint = Paint()
      ..color = AppPalette.robeShade
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -30), Offset(-swing * 0.5, 0), legPaint);
    canvas.drawLine(const Offset(0, -30), Offset(swing * 0.5, 0), legPaint);

    // الثوب مرئيًّا من الخلف
    final robe = Path()
      ..moveTo(-17, -84)
      ..lineTo(17, -84)
      ..lineTo(25, -22)
      ..quadraticBezierTo(0, -14, -25, -22)
      ..close();
    canvas.drawPath(robe, Paint()..color = AppPalette.robe);
    canvas.drawPath(
      robe,
      Paint()
        ..color = AppPalette.woodDark.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // طيّةُ ظلٍّ في وسط الظهر تكسر التسطّح.
    canvas.drawPath(
      Path()
        ..moveTo(0, -82)
        ..lineTo(0, -20),
      Paint()
        ..color = AppPalette.robeShade.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // الحزام
    canvas.drawRect(
      const Rect.fromLTWH(-18, -62, 36, 8),
      Paint()..color = AppPalette.sash,
    );

    // الذراعان على الجانبين
    final armPaint = Paint()
      ..color = AppPalette.robe
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(-15, -76),
      Offset(-24, -50 + swing * 0.3),
      armPaint,
    );
    canvas.drawLine(
      const Offset(15, -76),
      Offset(24, -50 - swing * 0.3),
      armPaint,
    );

    // الرقبة والعمامة
    canvas.drawCircle(
      const Offset(0, -94),
      12,
      Paint()..color = AppPalette.skin,
    );
    canvas.drawCircle(
      const Offset(0, -100),
      15,
      Paint()..color = AppPalette.sash,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, -100), radius: 15),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    if (state == PlayerState.celebrating) {
      canvas.drawCircle(
        const Offset(0, -56),
        58,
        Paint()..color = AppPalette.gold.withValues(alpha: 0.16),
      );
    }

    canvas.restore();
  }
}
