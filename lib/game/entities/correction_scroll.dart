import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../domain/models/answer_result.dart';
import '../config/game_config.dart';
import '../text/arabic_text.dart';

/// التصحيحُ داخل العالم: معلّمٌ يقف على الطريق، ومخطوطةٌ تنفرد أمام اللاعب.
///
/// ليس هذا حوارَ خطأٍ ولا شاشةَ خسارة؛ العالم يبطئ ولا يقف، والمخطوطةُ تنطوي
/// من نفسها بعد لحظات، أو بلمسةٍ من اللاعب إن أراد المضيّ.
class CorrectionScroll extends PositionComponent with TapCallbacks {
  CorrectionScroll({required this.result, required this.onDismissed})
      : super(
          size: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
          priority: 60,
        );

  final AnswerResult result;
  final VoidCallback onDismissed;

  late final TextPainter _headerPainter;
  late final TextPainter _correctPainter;
  late final TextPainter _explanationPainter;
  late final TextPainter _hintPainter;
  late final double _panelHeight;

  static const double _panelWidth = 356;
  static const double _panelCenterX = GameConfig.worldWidth / 2;
  static const double _panelCenterY = 300;
  static const double _unrollDuration = 0.32;

  double _elapsed = 0;
  bool _closing = false;
  double _closeProgress = 0;

  @override
  Future<void> onLoad() async {
    _headerPainter = ArabicText.painter(
      'ليست هذه هي الإجابةَ الصحيحة',
      fontSize: 21,
      color: AppPalette.failure,
      fontWeight: FontWeight.w700,
      maxWidth: _panelWidth - 48,
    );

    _correctPainter = ArabicText.painter(
      'الصوابُ: ${result.question.correctAnswer.label}',
      fontSize: 24,
      color: AppPalette.ink,
      fontWeight: FontWeight.w700,
      maxWidth: _panelWidth - 48,
    );

    _explanationPainter = ArabicText.painter(
      result.explanation,
      fontSize: 19,
      color: AppPalette.inkSoft,
      maxWidth: _panelWidth - 48,
      height: 1.75,
    );

    _hintPainter = ArabicText.painter(
      'المس الشاشةَ لتُتابع',
      fontSize: 15,
      color: AppPalette.inkSoft.withValues(alpha: 0.7),
      maxWidth: _panelWidth - 48,
    );

    _panelHeight = 56 +
        _headerPainter.height +
        _correctPainter.height +
        _explanationPainter.height +
        _hintPainter.height +
        46;
  }

  /// هل مضى من الزمن ما يكفي لقبول لمسة التخطّي؟
  bool get canDismiss => _elapsed >= GameConfig.correctionMinDuration;

  void dismiss() {
    if (_closing || !canDismiss) return;
    _closing = true;
  }

  /// أيُّ لمسةٍ على الشاشة تطوي المخطوطةَ وتُعيد اللاعبَ إلى طريقه.
  @override
  void onTapDown(TapDownEvent event) => dismiss();

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (!_closing && _elapsed >= GameConfig.correctionDuration) {
      _closing = true;
    }

    if (_closing) {
      _closeProgress += dt * 4;
      if (_closeProgress >= 1) {
        onDismissed();
        removeFromParent();
      }
    }
  }

  double get _unroll {
    final opening = (_elapsed / _unrollDuration).clamp(0.0, 1.0);
    final closing = 1 - _closeProgress.clamp(0.0, 1.0);
    return math.min(opening, closing);
  }

  @override
  void render(Canvas canvas) {
    final progress = _unroll;
    if (progress <= 0) return;

    _renderTeacher(canvas, progress);

    final height = _panelHeight * Curves.easeOutCubic.transform(progress);
    final rect = Rect.fromCenter(
      center: const Offset(_panelCenterX, _panelCenterY),
      width: _panelWidth,
      height: height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 6)), const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawRect(rect, Paint()..color = AppPalette.parchment);
    canvas.drawRect(
      rect,
      Paint()
        ..color = AppPalette.parchmentDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // أسطوانتا المخطوطة أعلى وأسفل.
    for (final y in [rect.top, rect.bottom]) {
      final roller = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(_panelCenterX, y),
          width: _panelWidth + 18,
          height: 16,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(roller, Paint()..color = AppPalette.wood);
      canvas.drawRRect(
        roller,
        Paint()
          ..color = AppPalette.woodDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // لا يُكتب على مخطوطةٍ لم تنفرد بعد.
    if (progress < 0.85) return;

    canvas.save();
    canvas.clipRect(rect.deflate(6));

    var cursorY = rect.top + 26;
    void write(TextPainter painter, double gap) {
      painter.paint(
        canvas,
        Offset(_panelCenterX - painter.width / 2, cursorY),
      );
      cursorY += painter.height + gap;
    }

    write(_headerPainter, 6);
    write(_correctPainter, 12);

    canvas.drawLine(
      Offset(rect.left + 40, cursorY - 6),
      Offset(rect.right - 40, cursorY - 6),
      Paint()
        ..color = AppPalette.parchmentDark
        ..strokeWidth = 1.5,
    );
    cursorY += 8;

    write(_explanationPainter, 14);
    write(_hintPainter, 0);

    canvas.restore();
  }

  /// المعلّم: هيئةٌ وقورٌ تقف على حافّة الطريق، لا شخصيّةٌ طفوليّة.
  void _renderTeacher(Canvas canvas, double progress) {
    final x = 74 - (1 - progress) * 60;
    const double feetY = 668;

    canvas.save();
    canvas.translate(x, feetY);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 52, height: 13),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );

    final robe = Path()
      ..moveTo(-16, -84)
      ..lineTo(16, -84)
      ..lineTo(24, 0)
      ..lineTo(-24, 0)
      ..close();
    canvas.drawPath(robe, Paint()..color = const Color(0xFF3F4F63));

    // العصا
    canvas.drawLine(
      const Offset(26, -70),
      const Offset(30, 2),
      Paint()
        ..color = AppPalette.woodDark
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      const Offset(0, -95),
      13,
      Paint()..color = AppPalette.skin,
    );
    // اللحية
    canvas.drawPath(
      Path()
        ..moveTo(-8, -88)
        ..quadraticBezierTo(0, -66, 8, -88)
        ..close(),
      Paint()..color = const Color(0xFFE8E4DC),
    );
    // العمامة
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, -101), radius: 16),
      math.pi,
      math.pi,
      true,
      Paint()..color = AppPalette.parchment,
    );

    canvas.restore();
  }
}
