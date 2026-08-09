import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../domain/models/answer_result.dart';
import '../config/game_config.dart';
import '../text/arabic_text.dart';

/// لافتةُ التصحيح: يقف عندها المعلّم فيسأل اللاعبَ سؤالًا يستنطق فكرَه،
/// أو يعلّل له الصوابَ في كلمةٍ لطيفة.
///
/// لا تنصرف من تلقاء نفسها. تبقى حتى يلمس اللاعبُ الشاشة، فالتصحيحُ لا
/// يُقرأ على عجل، والوقتُ في يد المتعلّم لا في يد المؤقّت.
class CorrectionSign extends PositionComponent with TapCallbacks {
  CorrectionSign({required this.result, required this.onDismissed})
      : super(
          size: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
          priority: 60,
        );

  final AnswerResult result;
  final VoidCallback onDismissed;

  late final TextPainter _nudgePainter;
  late final TextPainter _answerPainter;
  late final TextPainter _hintPainter;
  late final double _boardHeight;

  static const double _boardWidth = 372;
  static const double _centerX = GameConfig.worldWidth / 2;
  static const double _topY = 214;
  static const double _riseDuration = 0.34;

  double _elapsed = 0;
  bool _closing = false;
  double _closeProgress = 0;

  @override
  Future<void> onLoad() async {
    _nudgePainter = ArabicText.painter(
      result.nudge,
      fontSize: 23,
      color: AppPalette.ink,
      maxWidth: _boardWidth - 52,
      height: 1.85,
      fontWeight: FontWeight.w700,
    );

    _answerPainter = ArabicText.painter(
      'الصوابُ: ${result.question.correctAnswer.label}',
      fontSize: 20,
      color: AppPalette.success,
      fontWeight: FontWeight.w700,
      maxWidth: _boardWidth - 52,
    );

    _hintPainter = ArabicText.painter(
      'المس الشاشةَ لتُتابع رحلتَك',
      fontSize: 15,
      color: AppPalette.inkSoft.withValues(alpha: 0.75),
      maxWidth: _boardWidth - 52,
    );

    _boardHeight = 46 +
        _nudgePainter.height +
        18 +
        _answerPainter.height +
        26 +
        _hintPainter.height +
        30;
  }

  bool get _canDismiss => _elapsed >= GameConfig.correctionMinDuration;

  void dismiss() {
    if (_closing || !_canDismiss) return;
    _closing = true;
  }

  /// أيُّ لمسةٍ على الشاشة تطوي اللافتةَ وتعيد اللاعبَ إلى طريقه.
  @override
  void onTapDown(TapDownEvent event) => dismiss();

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // لا انصرافَ بمرور الوقت؛ اللمسةُ وحدَها تُنهيها.
    if (_closing) {
      _closeProgress += dt * 4.2;
      if (_closeProgress >= 1) {
        onDismissed();
        removeFromParent();
      }
    }
  }

  double get _appearance {
    final rising = (_elapsed / _riseDuration).clamp(0.0, 1.0);
    final leaving = 1 - _closeProgress.clamp(0.0, 1.0);
    return math.min(Curves.easeOutBack.transform(rising), leaving);
  }

  @override
  void render(Canvas canvas) {
    final appearance = _appearance;
    if (appearance <= 0) return;

    // تعتيمٌ خفيفٌ يُبرز اللافتة دون أن يحجب العالمَ خلفها.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, GameConfig.worldWidth, GameConfig.worldHeight),
      Paint()..color = Colors.black.withValues(alpha: 0.28 * appearance.clamp(0.0, 1.0)),
    );

    _renderTeacher(canvas, appearance);

    canvas.save();
    // تنهض اللافتةُ من أسفلَ قليلًا مع ظهورها.
    canvas.translate(0, (1 - appearance) * 40);

    final rect = Rect.fromLTWH(
      _centerX - _boardWidth / 2,
      _topY,
      _boardWidth,
      _boardHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 8)),
      Paint()..color = Colors.black.withValues(alpha: 0.32),
    );
    canvas.drawRRect(rrect, Paint()..color = AppPalette.parchment);
    canvas.drawRRect(
      rrect.deflate(9),
      Paint()
        ..color = AppPalette.woodDark.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppPalette.wood
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    // عمودا اللافتة المغروزان في الأرض.
    final postPaint = Paint()..color = AppPalette.woodDark;
    for (final x in [_centerX - 96, _centerX + 96]) {
      canvas.drawRect(
        Rect.fromLTWH(x - 7, rect.bottom - 4, 14, 58),
        postPaint,
      );
    }

    var cursorY = rect.top + 26;
    void write(TextPainter painter, double gap) {
      painter.paint(
        canvas,
        Offset(_centerX - painter.width / 2, cursorY),
      );
      cursorY += painter.height + gap;
    }

    write(_nudgePainter, 18);

    canvas.drawLine(
      Offset(rect.left + 46, cursorY - 9),
      Offset(rect.right - 46, cursorY - 9),
      Paint()
        ..color = AppPalette.parchmentDark
        ..strokeWidth = 1.5,
    );

    write(_answerPainter, 26);

    // نبضةٌ خفيفةٌ في التلميح تدلّ على أنّ اللافتة تنتظر لمسة.
    final pulse = 0.65 + 0.35 * math.sin(_elapsed * 3.1);
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: pulse),
    );
    write(_hintPainter, 0);
    canvas.restore();

    canvas.restore();
  }

  /// المعلّم: هيئةٌ وقورٌ تقف إلى جانب اللافتة.
  void _renderTeacher(Canvas canvas, double appearance) {
    final x = 74 - (1 - appearance.clamp(0.0, 1.0)) * 70;
    const feetY = 690.0;

    canvas.save();
    canvas.translate(x, feetY);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 58, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );

    canvas.drawPath(
      Path()
        ..moveTo(-18, -92)
        ..lineTo(18, -92)
        ..lineTo(27, 0)
        ..lineTo(-27, 0)
        ..close(),
      Paint()..color = const Color(0xFF3F4F63),
    );

    canvas.drawLine(
      const Offset(29, -76),
      const Offset(33, 2),
      Paint()
        ..color = AppPalette.woodDark
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      const Offset(0, -104),
      14,
      Paint()..color = AppPalette.skin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-9, -97)
        ..quadraticBezierTo(0, -72, 9, -97)
        ..close(),
      Paint()..color = const Color(0xFFEFEBE3),
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, -111), radius: 17),
      math.pi,
      math.pi,
      true,
      Paint()..color = AppPalette.parchment,
    );

    canvas.restore();
  }
}
