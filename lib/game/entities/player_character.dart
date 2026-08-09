import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../domain/models/outfit.dart';
import '../config/game_config.dart';
import '../world/perspective.dart';

enum PlayerState { running, celebrating, stumbling }

/// شخصيّة اللاعب: طالبُ علمٍ يصعد الطريقَ مبتعدًا عن الكاميرا.
///
/// نراه من الخلف، فلا وجهَ له ولا ملامح، وإنّما ثوبٌ وعمامةٌ وخطو. وهيئتُه
/// تتبدّل بتبدّل [outfit]، وهو ما تفتحه الكتبُ التي يجمعها.
class PlayerCharacter extends Component {
  PlayerCharacter({super.priority});

  double lateralX = 0;

  /// الزيُّ الحاليّ؛ يُحدَّث حين يفتح اللاعبُ زيًّا جديدًا.
  Outfit outfit = Outfit.student;

  /// شدّةُ الانطلاق (٠ إلى ١) — تُطيل الخطوَ وتُظهر أثرًا خلف المسافر.
  double turbo = 0;

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

    final cadence = state == PlayerState.stumbling ? 4.5 : 12 + turbo * 10;
    _phase += dt * cadence;

    final previousX = lateralX;
    lateralX += (_targetX - lateralX) *
        (GameConfig.playerFollowSpeed * dt).clamp(0.0, 1.0);

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

    if (turbo > 0.02) _renderTurboTrail(canvas);

    final bob = state == PlayerState.stumbling ? 0.0 : math.sin(_phase) * 2.6;
    canvas.translate(0, bob);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 58, height: 15),
      Paint()..color = Colors.black.withValues(alpha: 0.26),
    );

    canvas.rotate(_lean);

    final robe = Color(outfit.robe);
    final robeShade = Color(outfit.robeShade);
    final swing = math.sin(_phase) * (13 + turbo * 6);

    // الساقان
    final legPaint = Paint()
      ..color = robeShade
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -30), Offset(-swing * 0.5, 0), legPaint);
    canvas.drawLine(const Offset(0, -30), Offset(swing * 0.5, 0), legPaint);

    // الثوب من الخلف
    final robePath = Path()
      ..moveTo(-17, -84)
      ..lineTo(17, -84)
      ..lineTo(25, -22)
      ..quadraticBezierTo(0, -14, -25, -22)
      ..close();
    canvas.drawPath(robePath, Paint()..color = robe);
    canvas.drawPath(
      robePath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -82)
        ..lineTo(0, -20),
      Paint()
        ..color = robeShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    if (outfit.hasCloak) _renderCloak(canvas, robeShade);

    // الحزام
    canvas.drawRect(
      const Rect.fromLTWH(-18, -62, 36, 8),
      Paint()..color = Color(outfit.sash),
    );

    // الذراعان
    final armPaint = Paint()
      ..color = robe
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

    if (outfit.carriesBook) _renderCarriedBook(canvas);

    // الرقبة والعمامة
    canvas.drawCircle(
      const Offset(0, -94),
      12,
      Paint()..color = AppPalette.skin,
    );
    canvas.drawCircle(
      const Offset(0, -100),
      15,
      Paint()..color = Color(outfit.turban),
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, -100), radius: 15),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
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

  /// بِشتٌ يتماوج مع الخطو.
  void _renderCloak(Canvas canvas, Color shade) {
    final sway = math.sin(_phase * 0.5) * 4;
    canvas.drawPath(
      Path()
        ..moveTo(-19, -82)
        ..lineTo(19, -82)
        ..lineTo(31 + sway, -10)
        ..quadraticBezierTo(0, -2, -31 + sway, -10)
        ..close(),
      Paint()..color = shade.withValues(alpha: 0.9),
    );
  }

  /// كتابٌ تحت الإبط — علامةُ من جمع الكتب.
  void _renderCarriedBook(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, -66, 16, 24),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF8E2F3F),
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, -62, 16, 3),
      Paint()..color = const Color(0xFFC9A227),
    );
  }

  /// أثرُ الانطلاق: خطوطٌ تتخلّف وراء المسافر.
  void _renderTurboTrail(Canvas canvas) {
    final strength = turbo.clamp(0.0, 1.0);
    final paint = Paint()
      ..color = AppPalette.gold.withValues(alpha: 0.32 * strength)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final offsetX = -30.0 + i * 20;
      final length = 34 + math.sin(_phase * 2 + i) * 12;
      canvas.drawLine(
        Offset(offsetX, -34),
        Offset(offsetX, -34 + length),
        paint,
      );
    }
  }
}
