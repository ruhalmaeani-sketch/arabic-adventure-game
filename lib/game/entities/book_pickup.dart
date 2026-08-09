import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../world/perspective.dart';

/// كتابٌ يلوح على الطريق؛ بجمعه تتبدّل هيئةُ المسافر وزيُّه.
///
/// الكتابُ عنصرُ هويّةٍ في هذه اللعبة لا مجرّد عملة، ولذلك رُبِط به ما يظهر
/// على اللاعب نفسِه: كلّما ازداد علمُه ازدادت هيئتُه وقارًا.
class BookPickup extends Component {
  BookPickup({
    required this.lateralX,
    required double spawnZ,
    super.priority,
  }) : z = spawnZ;

  final double lateralX;
  double z;

  bool _collected = false;
  double _spin = 0;

  bool get isCollected => _collected;

  bool get isBehindCamera => z < GameConfig.nearClipZ;

  bool canBeCollectedBy(double playerLateralX) =>
      !_collected &&
      z <= GameConfig.playerZ &&
      (playerLateralX - lateralX).abs() < 62;

  void collect() => _collected = true;

  @override
  void update(double dt) {
    super.update(dt);
    _spin += dt * 2.2;
  }

  @override
  void render(Canvas canvas) {
    if (_collected || !Perspective.isVisible(z)) return;

    final scale = Perspective.scaleAt(z);
    final fade = 1 - Perspective.hazeAt(z);
    if (fade <= 0.05) return;

    // يحوم فوق الأرض قليلًا ليُرى من بعيد.
    final hover = 66 + math.sin(_spin * 1.6) * 8;
    final center = Perspective.project(lateralX, z, height: hover);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    // هالةٌ ذهبيّةٌ تدلّ عليه.
    canvas.drawCircle(
      Offset.zero,
      48,
      Paint()..color = const Color(0xFFFFD98A).withValues(alpha: 0.18 * fade),
    );

    // الكتابُ مائلٌ قليلًا فيُقرأ سُمكُه.
    canvas.rotate(math.sin(_spin) * 0.22);

    const coverColor = Color(0xFF8E2F3F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 56, height: 40),
        const Radius.circular(4),
      ),
      Paint()..color = coverColor.withValues(alpha: fade),
    );
    // الأوراقُ بارزةٌ من جانبٍ واحد.
    canvas.drawRect(
      const Rect.fromLTWH(-24, -16, 44, 32),
      Paint()..color = const Color(0xFFF6EEDC).withValues(alpha: fade),
    );
    // الكعبُ والزخرفة.
    canvas.drawRect(
      const Rect.fromLTWH(20, -20, 8, 40),
      Paint()..color = const Color(0xFF6E2230).withValues(alpha: fade),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-14, -4, 24, 3),
      Paint()..color = const Color(0xFFC9A227).withValues(alpha: fade),
    );

    canvas.restore();
  }
}
