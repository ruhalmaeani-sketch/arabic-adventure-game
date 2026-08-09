import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../domain/models/challenge.dart';
import '../config/game_config.dart';
import '../text/arabic_text.dart';

/// بوابةُ التحدّي: بناءٌ حجريٌّ واحدٌ يحمل الجملةَ على عتَبته العليا،
/// وينفتح تحتها بابان، لكلِّ بابٍ طريقُه وإعرابُه.
///
/// جُمع النصُّ والطريقان في بناءٍ واحدٍ عن قصد: فبذلك يبقى النصُّ أمام عين
/// اللاعب وهو يختار، ولا يحتاج إلى نافذة سؤالٍ تعلو الشاشة.
class ChallengeGate extends PositionComponent {
  ChallengeGate({required this.challenge, required double startX})
      : super(
          position: Vector2(startX, 0),
          size: Vector2(GameConfig.challengeWidth, GameConfig.worldHeight),
          anchor: Anchor.topLeft,
          priority: 20,
        );

  final Challenge challenge;

  late final TextPainter _sentencePainter;
  late final List<TextPainter> _labelPainters;

  bool _resolved = false;
  int? _chosenLane;
  bool _chosenWasCorrect = false;
  double _glow = 0;

  /// موضع مستوى الأبواب في إحداثيّات العالم؛ عنده تُحسم الإجابة.
  double get gatePlaneWorldX => position.x + GameConfig.gatePlaneX;

  bool get isResolved => _resolved;

  /// هل جاوز البناءُ اللاعبَ وخرج من الشاشة؟
  bool get isOffScreen => position.x > GameConfig.worldWidth + 80;

  @override
  Future<void> onLoad() async {
    final question = challenge.question;
    _sentencePainter = question.hasTargetWord
        ? ArabicText.highlightedSentence(
            question.sentence,
            targetWordIndex: question.targetWordIndex,
            fontSize: 25,
            baseColor: AppPalette.ink,
            highlightColor: const Color(0xFF9C3B1B),
            maxWidth: GameConfig.lintelWidth - 32,
          )
        : ArabicText.painter(
            question.sentence,
            fontSize: 25,
            color: AppPalette.ink,
            maxWidth: GameConfig.lintelWidth - 32,
          );

    _labelPainters = [
      for (final option in challenge.options)
        ArabicText.painter(
          option.label,
          fontSize: 22,
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
          maxWidth: GameConfig.doorSignWidth - 14,
          height: 1.15,
        ),
    ];
  }

  /// يسجّل أنَّ اللاعب عبَر من بابٍ بعينه، فيتغيّر مظهرُ البناء تبعًا لذلك.
  void markResolved({required int laneIndex, required bool isCorrect}) {
    _resolved = true;
    _chosenLane = laneIndex;
    _chosenWasCorrect = isCorrect;
    _glow = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_glow > 0) _glow = (_glow - dt * 0.7).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    _renderFork(canvas);
    _renderPillars(canvas);
    for (var i = 0; i < challenge.laneCount; i++) {
      _renderDoor(canvas, i);
    }
    _renderLintel(canvas);
  }

  /// الإسفينُ الذي ينقسم عنده الطريق إلى طريقين حقيقيّين.
  void _renderFork(Canvas canvas) {
    const tipX = GameConfig.forkTipX;
    const planeX = GameConfig.gatePlaneX;
    final top = GameConfig.laneCenters.first + 30;
    final bottom = GameConfig.laneCenters.last - 30;
    final midY = (GameConfig.laneCenters.first + GameConfig.laneCenters.last) / 2;

    final wedge = Path()
      ..moveTo(tipX, midY)
      ..lineTo(planeX - 40, top)
      ..lineTo(planeX - 40, bottom)
      ..close();

    canvas.drawPath(wedge, Paint()..color = const Color(0xFF8A8A63));
    canvas.drawPath(
      wedge,
      Paint()
        ..color = AppPalette.roadEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  /// أعمدةُ البناء الحاملةُ للعتَبة.
  void _renderPillars(Canvas canvas) {
    final paint = Paint()..color = AppPalette.stoneDark;
    const pillarWidth = 18.0;
    final top = GameConfig.lintelCenterY + GameConfig.lintelHeight / 2 - 8;
    for (final x in [
      GameConfig.gatePlaneX - GameConfig.lintelWidth / 2 + 14,
      GameConfig.gatePlaneX + GameConfig.lintelWidth / 2 - 32,
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(x, top, pillarWidth, GameConfig.roadTopY - top + 10),
        paint,
      );
    }
  }

  /// العتَبةُ العليا وعليها الجملة، والكلمةُ المستهدفة مميّزةٌ بلونها.
  void _renderLintel(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: const Offset(GameConfig.gatePlaneX, GameConfig.lintelCenterY),
      width: GameConfig.lintelWidth,
      height: GameConfig.lintelHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 5)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRRect(rrect, Paint()..color = AppPalette.parchment);
    canvas.drawRRect(
      rrect.deflate(7),
      Paint()
        ..color = AppPalette.woodDark.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppPalette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    ArabicText.paintCentered(
      canvas,
      _sentencePainter,
      const Offset(GameConfig.gatePlaneX, GameConfig.lintelCenterY),
    );
  }

  /// بابٌ واحدٌ يحمل إعرابًا؛ الدخولُ منه هو الإجابة.
  ///
  /// قاعدةُ الباب موضوعةٌ على خطّ مشي المسار، فيبدو المسافرُ عابرًا من داخله
  /// لا واقفًا فوقه.
  void _renderDoor(Canvas canvas, int laneIndex) {
    final laneY = GameConfig.laneCenters[laneIndex];
    final centerY = laneY + GameConfig.doorBaseOffset - GameConfig.doorHeight / 2;
    final rect = Rect.fromCenter(
      center: Offset(GameConfig.gatePlaneX, centerY),
      width: GameConfig.doorWidth,
      height: GameConfig.doorHeight,
    );
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(46),
      topRight: const Radius.circular(46),
    );

    var frameColor = AppPalette.stone;
    var fillColor = AppPalette.woodDark;

    if (_resolved && _chosenLane == laneIndex) {
      frameColor = _chosenWasCorrect ? AppPalette.gold : AppPalette.failure;
      fillColor = Color.lerp(
        AppPalette.woodDark,
        frameColor,
        0.45 * _glow,
      )!;
    }

    canvas.drawRRect(rrect, Paint()..color = fillColor);
    // عمقُ الممرّ: ظلٌّ داخليٌّ يوحي بأنَّ الباب منفَذٌ لا لوحةٌ مسطّحة.
    canvas.drawRRect(
      rrect.deflate(14),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = frameColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    if (_glow > 0 && _chosenLane == laneIndex) {
      canvas.drawRRect(
        rrect.inflate(8),
        Paint()
          ..color = frameColor.withValues(alpha: 0.35 * _glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
    }

    _renderDoorSign(canvas, laneIndex, rect.top);
  }

  /// لافتةٌ خشبيّةٌ فوق الباب تحمل الإعراب.
  void _renderDoorSign(Canvas canvas, int laneIndex, double doorTop) {
    final center = Offset(
      GameConfig.gatePlaneX,
      doorTop - GameConfig.doorSignGap - GameConfig.doorSignHeight / 2,
    );
    final rect = Rect.fromCenter(
      center: center,
      width: GameConfig.doorSignWidth,
      height: GameConfig.doorSignHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    final isChosen = _resolved && _chosenLane == laneIndex;
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawRRect(rrect, Paint()..color = AppPalette.parchment);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isChosen
            ? (_chosenWasCorrect ? AppPalette.gold : AppPalette.failure)
            : AppPalette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    ArabicText.paintCentered(canvas, _labelPainters[laneIndex], center);
  }
}
