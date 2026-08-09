import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../domain/models/challenge.dart';
import '../config/game_config.dart';
import '../text/arabic_text.dart';
import '../world/perspective.dart';
import '../world/scenery.dart';

/// بوابةُ التحدّي: قوسٌ حجريٌّ يعترض الطريق، تعلوه لوحةٌ بالجملة، وينفتح
/// تحتها بابان لكلٍّ منهما إعرابُه.
///
/// البناءُ لوحٌ مسطّحٌ قائمٌ عند بُعدٍ واحد، فيصحّ رسمُه كلِّه بتحويل قياسٍ
/// واحدٍ عند ذلك البعد. وهذا بالضبط ما يجعل النصَّ يكبر تدريجيًّا وهو يقترب،
/// فيُقرأ من بعيدٍ صغيرًا ثمّ يتّضح — وهي فائدةُ المنظور التي لم تكن في
/// المشهد المسطّح.
class ChallengeGate extends Component {
  ChallengeGate({
    required this.challenge,
    required this.scene,
    double? spawnZ,
    super.priority,
  }) : z = spawnZ ?? GameConfig.challengeSpawnZ;

  final Challenge challenge;
  final SceneState scene;

  /// بُعدُ البوابة عن الكاميرا؛ يتناقص حتى يبلغ اللاعبَ.
  double z;

  late final TextPainter _sentencePainter;
  late final List<TextPainter> _labelPainters;

  bool _resolved = false;
  int? _chosenLane;
  bool _chosenWasCorrect = false;
  double _glow = 0;
  double _sinceResolved = 0;

  /// بعد العبور تنطفئ البوابةُ تدريجيًّا ثمّ تُزال.
  ///
  /// لولا ذلك لبقيت ماثلةً بحجمها الكامل خلف لافتة التصحيح — والعالمُ يكاد
  /// يقف حينئذٍ — فتزاحم النصَّ الذي يقرؤه اللاعب.
  static const double _fadeDelay = 0.3;
  static const double _fadeDuration = 0.55;

  // ── أبعادُ البناء بوحدات العالم، مقيسةً من نقطة الأرض في محور الطريق ──
  static const double _doorTopY = -GameConfig.doorHeight;
  static const double _plaqueCenterY = _doorTopY - 40;
  static const double _plaqueWidth = 166;
  static const double _plaqueHeight = 58;
  static const double _bannerBottomY = -252;
  static const double _bannerCenterY = _bannerBottomY - GameConfig.bannerHeight / 2;
  static const double _pillarX = 246;

  bool get isResolved => _resolved;

  /// شفافيّةُ البناء بعد العبور: واحدٌ ما دام قائمًا، وصفرٌ حين ينطفئ تمامًا.
  double get _opacity {
    if (!_resolved) return 1;
    final t = (_sinceResolved - _fadeDelay) / _fadeDuration;
    return (1 - t).clamp(0.0, 1.0);
  }

  /// هل انتهى دورُ هذا البناء، إمّا بمجاوزته الكاميرا أو بانطفائه؟
  bool get isBehindCamera =>
      z < GameConfig.nearClipZ || (_resolved && _opacity <= 0);

  /// المسافةُ الباقية حتى يبلغ اللاعبَ.
  double get distanceToPlayer => z - GameConfig.playerZ;

  @override
  Future<void> onLoad() async {
    final question = challenge.question;
    _sentencePainter = question.hasTargetWord
        ? ArabicText.highlightedSentence(
            question.sentence,
            targetWordIndex: question.targetWordIndex,
            fontSize: GameConfig.bannerFontSize,
            baseColor: AppPalette.ink,
            highlightColor: const Color(0xFF9C3B1B),
            maxWidth: GameConfig.bannerWidth - 60,
          )
        : ArabicText.painter(
            question.sentence,
            fontSize: GameConfig.bannerFontSize,
            color: AppPalette.ink,
            maxWidth: GameConfig.bannerWidth - 60,
          );

    _labelPainters = [
      for (final option in challenge.options)
        ArabicText.painter(
          option.label,
          fontSize: GameConfig.doorSignFontSize,
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
          maxWidth: _plaqueWidth - 16,
          height: 1.15,
        ),
    ];
  }

  void markResolved({required int laneIndex, required bool isCorrect}) {
    _resolved = true;
    _chosenLane = laneIndex;
    _chosenWasCorrect = isCorrect;
    _glow = 1;
  }

  /// جاوزها المنطلقُ دون إجابة: تنطفئ كما تنطفئ المُجابةُ، بلا وسمِ صوابٍ
  /// ولا خطأ، فلا يبقى في ذهن اللاعب أثرُ حكمٍ لم يقع.
  void markSkipped() {
    _resolved = true;
    _chosenLane = null;
    _glow = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_glow > 0) _glow = (_glow - dt * 0.75).clamp(0.0, 1.0);
    if (_resolved) _sinceResolved += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!Perspective.isVisible(z)) return;

    final opacity = _opacity;
    if (opacity <= 0) return;

    final scale = Perspective.scaleAt(z);
    final ground = Perspective.project(0, z);

    canvas.save();
    if (opacity < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
    canvas.translate(ground.dx, ground.dy);
    canvas.scale(scale);

    _renderPillars(canvas);
    for (var i = 0; i < challenge.laneCount; i++) {
      _renderDoor(canvas, i);
    }
    for (var i = 0; i < challenge.laneCount; i++) {
      _renderPlaque(canvas, i);
    }
    _renderBanner(canvas);
    _applyHaze(canvas);

    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  void _renderPillars(Canvas canvas) {
    final paint = Paint()..color = AppPalette.stoneDark;
    for (final x in [-_pillarX, _pillarX]) {
      canvas.drawRect(
        Rect.fromLTWH(x - 15, _bannerBottomY, 30, -_bannerBottomY),
        paint,
      );
      // قاعدةٌ أعرضُ تُثبّت العمودَ بصريًّا على الأرض.
      canvas.drawRect(Rect.fromLTWH(x - 22, -18, 44, 18), paint);
    }
  }

  /// بابٌ واحدٌ يحمل إعرابًا؛ الدخولُ منه هو الإجابة.
  void _renderDoor(Canvas canvas, int laneIndex) {
    final x = GameConfig.laneOffsets[laneIndex];
    final rect = Rect.fromLTRB(
      x - GameConfig.doorWidth / 2,
      _doorTopY,
      x + GameConfig.doorWidth / 2,
      0,
    );
    final arch = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(62),
      topRight: const Radius.circular(62),
    );

    final isChosen = _resolved && _chosenLane == laneIndex;
    final frame = isChosen
        ? (_chosenWasCorrect ? AppPalette.gold : AppPalette.failure)
        : AppPalette.stone;

    // إطارُ الباب.
    canvas.drawRRect(arch, Paint()..color = frame);
    // فتحةُ الممرّ: أغمقُ في العمق فيبدو منفَذًا لا لوحًا.
    canvas.drawRRect(
      arch.deflate(13),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A1A10),
            AppPalette.woodDark.withValues(alpha: 0.92),
          ],
        ).createShader(rect),
    );

    if (_glow > 0 && isChosen) {
      canvas.drawRRect(
        arch.inflate(14),
        Paint()
          ..color = frame.withValues(alpha: 0.4 * _glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16,
      );
    }
  }

  /// لوحةُ الإعراب فوق قوس الباب، لا داخلَه، كيلا تحجبها الشخصيّةُ عند العبور.
  void _renderPlaque(Canvas canvas, int laneIndex) {
    final x = GameConfig.laneOffsets[laneIndex];
    final rect = Rect.fromCenter(
      center: Offset(x, _plaqueCenterY),
      width: _plaqueWidth,
      height: _plaqueHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));

    final isChosen = _resolved && _chosenLane == laneIndex;

    canvas.drawRRect(
      rrect.shift(const Offset(0, 5)),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.drawRRect(rrect, Paint()..color = AppPalette.parchment);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isChosen
            ? (_chosenWasCorrect ? AppPalette.gold : AppPalette.failure)
            : AppPalette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    ArabicText.paintCentered(
      canvas,
      _labelPainters[laneIndex],
      Offset(x, _plaqueCenterY),
    );
  }

  /// اللوحةُ العليا وعليها الجملة، والكلمةُ المستهدفة مميّزةٌ بلونها.
  void _renderBanner(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: const Offset(0, _bannerCenterY),
      width: GameConfig.bannerWidth,
      height: GameConfig.bannerHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 9)),
      Paint()..color = Colors.black.withValues(alpha: 0.26),
    );
    canvas.drawRRect(rrect, Paint()..color = AppPalette.parchment);
    canvas.drawRRect(
      rrect.deflate(12),
      Paint()
        ..color = AppPalette.woodDark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppPalette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );

    ArabicText.paintCentered(
      canvas,
      _sentencePainter,
      const Offset(0, _bannerCenterY),
    );
  }

  /// يذيب البناءَ في لون الأفق كلّما بعُد، فيتّسق مع بقيّة المشهد.
  void _applyHaze(Canvas canvas) {
    final haze = Perspective.hazeAt(z);
    if (haze <= 0.01) return;
    canvas.drawRect(
      Rect.fromLTRB(
        -_pillarX - 40,
        _bannerCenterY - GameConfig.bannerHeight,
        _pillarX + 40,
        20,
      ),
      Paint()..color = scene.realm.hazeColor.withValues(alpha: haze),
    );
  }
}
