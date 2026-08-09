import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../text/arabic_text.dart';

/// نصٌّ يرتفع ويتلاشى — مكافأةٌ عابرةٌ لا تقطع الحركة.
class FloatingText extends PositionComponent {
  FloatingText({
    required this.text,
    required Vector2 origin,
    required this.color,
    this.fontSize = 26,
    this.lifetime = 1.15,
    this.rise = 62,
  }) : super(position: origin, priority: 50);

  final String text;
  final Color color;
  final double fontSize;
  final double lifetime;
  final double rise;

  late final TextPainter _painter;
  double _elapsed = 0;

  @override
  Future<void> onLoad() async {
    _painter = ArabicText.painter(
      text,
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w700,
      shadows: [
        const Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
      ],
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position.y -= rise * dt / lifetime;
    if (_elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / lifetime).clamp(0.0, 1.0);
    final opacity = progress < 0.7 ? 1.0 : (1 - (progress - 0.7) / 0.3);

    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
    );
    _painter.paint(canvas, Offset(-_painter.width / 2, -_painter.height / 2));
    canvas.restore();
  }
}
