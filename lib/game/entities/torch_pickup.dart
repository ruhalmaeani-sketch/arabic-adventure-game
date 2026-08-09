import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../world/perspective.dart';

/// شعلةٌ قائمةٌ على الطريق يلتقطها اللاعبُ بمروره فوقها.
///
/// الشعلاتُ ليست عملةً أخرى؛ بها يبدّل اللاعبُ جوَّ الرحلة، فيكون جمعُها
/// سببًا في تغيّر المشهد بيده.
class TorchPickup extends Component {
  TorchPickup({
    required this.lateralX,
    required double spawnZ,
    super.priority,
  }) : z = spawnZ;

  final double lateralX;
  double z;

  bool _collected = false;
  double _flicker = 0;

  bool get isCollected => _collected;

  bool get isBehindCamera => z < GameConfig.nearClipZ;

  /// هل بلَغها اللاعبُ وهو على محاذاتها؟
  bool canBeCollectedBy(double playerLateralX) =>
      !_collected &&
      z <= GameConfig.playerZ &&
      (playerLateralX - lateralX).abs() < 62;

  void collect() => _collected = true;

  @override
  void update(double dt) {
    super.update(dt);
    _flicker += dt * 9;
  }

  @override
  void render(Canvas canvas) {
    if (_collected || !Perspective.isVisible(z)) return;

    final scale = Perspective.scaleAt(z);
    final base = Perspective.project(lateralX, z);
    final fade = 1 - Perspective.hazeAt(z);
    if (fade <= 0.05) return;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale);

    // عمودُ الشعلة
    canvas.drawRect(
      const Rect.fromLTWH(-5, -74, 10, 74),
      Paint()..color = const Color(0xFF5C4326).withValues(alpha: fade),
    );

    // اللهب: طبقتان ترتجفان فيبدو حيًّا
    final wobble = math.sin(_flicker) * 4;
    final outer = Path()
      ..moveTo(-17, -76)
      ..quadraticBezierTo(wobble, -132, 17, -76)
      ..close();
    canvas.drawPath(
      outer,
      Paint()..color = const Color(0xFFE8813A).withValues(alpha: 0.92 * fade),
    );

    final inner = Path()
      ..moveTo(-9, -78)
      ..quadraticBezierTo(wobble * 0.6, -114, 9, -78)
      ..close();
    canvas.drawPath(
      inner,
      Paint()..color = const Color(0xFFFFD98A).withValues(alpha: 0.95 * fade),
    );

    // هالةُ الضوء حول اللهب
    canvas.drawCircle(
      Offset(0, -96),
      42,
      Paint()..color = const Color(0xFFFFB347).withValues(alpha: 0.16 * fade),
    );

    canvas.restore();
  }
}
