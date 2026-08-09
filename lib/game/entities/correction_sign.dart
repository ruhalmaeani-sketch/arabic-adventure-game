import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../domain/models/answer_result.dart';
import '../config/game_config.dart';
import '../text/arabic_text.dart';

/// لافتةُ التصحيح: تعيد الجملةَ أمام عين اللاعب، وتبيّن له إعرابَ الكلمة،
/// ثمّ يسأله المعلّمُ سؤالًا يستنطق فكرَه.
///
/// لا تنصرف من تلقاء نفسها؛ تبقى حتى يلمس اللاعبُ الشاشة. فالتصحيحُ لا يُقرأ
/// على عجل، والوقتُ في يد المتعلّم لا في يد المؤقّت.
class CorrectionSign extends PositionComponent with TapCallbacks {
  CorrectionSign({required this.result, required this.onDismissed})
      : super(
          size: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
          priority: 60,
        );

  final AnswerResult result;
  final VoidCallback onDismissed;

  late final TextPainter _sentencePainter;
  late final TextPainter _verdictPainter;
  late final TextPainter _nudgePainter;
  late final TextPainter _hintPainter;
  late final double _boardHeight;

  static const double _boardWidth = 384;
  static const double _centerX = GameConfig.worldWidth / 2;
  static const double _topY = 176;
  static const double _padding = 26;
  static const double _riseDuration = 0.34;

  double _elapsed = 0;
  bool _closing = false;
  double _closeProgress = 0;

  @override
  Future<void> onLoad() async {
    final question = result.question;
    final innerWidth = _boardWidth - _padding * 2;

    // الجملةُ أوّلًا: التصحيحُ بلا نصِّه معلَّقٌ في الهواء.
    _sentencePainter = question.hasTargetWord
        ? ArabicText.highlightedSentence(
            question.sentence,
            targetWordIndex: question.targetWordIndex,
            fontSize: 26,
            baseColor: AppPalette.ink,
            highlightColor: const Color(0xFF9C3B1B),
            maxWidth: innerWidth,
            height: 1.7,
          )
        : ArabicText.painter(
            question.sentence,
            fontSize: 26,
            color: AppPalette.ink,
            maxWidth: innerWidth,
          );

    // الحكمُ صريحٌ: الكلمةُ وإعرابُها في سطرٍ واحد.
    _verdictPainter = ArabicText.painter(
      question.hasTargetWord
          ? '«${question.targetWord}» ${question.correctAnswer.label}'
          : question.correctAnswer.label,
      fontSize: 25,
      color: const Color(0xFF2F6B44),
      fontWeight: FontWeight.w700,
      maxWidth: innerWidth,
    );

    _nudgePainter = ArabicText.painter(
      result.nudge,
      fontSize: 21,
      color: AppPalette.inkSoft,
      maxWidth: innerWidth,
      height: 1.85,
    );

    _hintPainter = ArabicText.painter(
      'المس الشاشةَ لتُتابع رحلتَك',
      fontSize: 15,
      color: AppPalette.inkSoft.withValues(alpha: 0.7),
      maxWidth: innerWidth,
    );

    _boardHeight = _padding +
        _sentencePainter.height +
        16 +
        _verdictPainter.height +
        18 +
        _nudgePainter.height +
        22 +
        _hintPainter.height +
        _padding;
  }

  bool get _canDismiss => _elapsed >= GameConfig.correctionMinDuration;

  void dismiss() {
    if (_closing || !_canDismiss) return;
    _closing = true;
  }

  @override
  void onTapDown(TapDownEvent event) => dismiss();

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

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
    final clamped = appearance.clamp(0.0, 1.0);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, GameConfig.worldWidth, GameConfig.worldHeight),
      Paint()..color = Colors.black.withValues(alpha: 0.4 * clamped),
    );

    _renderTeacher(canvas, clamped);

    canvas.save();
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
      Paint()..color = Colors.black.withValues(alpha: 0.34),
    );
    canvas.drawRRect(rrect, Paint()..color = AppPalette.parchment);
    canvas.drawRRect(
      rrect.deflate(9),
      Paint()
        ..color = AppPalette.woodDark.withValues(alpha: 0.32)
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

    final postPaint = Paint()..color = AppPalette.woodDark;
    for (final x in [_centerX - 100, _centerX + 100]) {
      canvas.drawRect(Rect.fromLTWH(x - 7, rect.bottom - 4, 14, 58), postPaint);
    }

    var cursorY = rect.top + _padding;
    void write(TextPainter painter, double gap) {
      painter.paint(canvas, Offset(_centerX - painter.width / 2, cursorY));
      cursorY += painter.height + gap;
    }

    write(_sentencePainter, 16);

    canvas.drawLine(
      Offset(rect.left + 48, cursorY - 8),
      Offset(rect.right - 48, cursorY - 8),
      Paint()
        ..color = AppPalette.parchmentDark
        ..strokeWidth = 1.5,
    );

    write(_verdictPainter, 18);
    write(_nudgePainter, 22);

    final pulse = 0.65 + 0.35 * math.sin(_elapsed * 3.1);
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: pulse),
    );
    write(_hintPainter, 0);
    canvas.restore();

    canvas.restore();
  }

  void _renderTeacher(Canvas canvas, double appearance) {
    final x = 74 - (1 - appearance) * 70;
    const feetY = 726.0;

    canvas.save();
    canvas.translate(x, feetY);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 58, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.26),
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
