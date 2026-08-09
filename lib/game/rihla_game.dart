import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../app/theme/app_palette.dart';
import '../domain/engines/session_engine.dart';
import '../domain/models/answer_result.dart';
import 'config/game_config.dart';
import 'entities/challenge_gate.dart';
import 'entities/correction_scroll.dart';
import 'entities/floating_text.dart';
import 'entities/player_character.dart';
import 'world/backdrop.dart';

/// أطوار الحلقة الأساسيّة.
enum GamePhase {
  /// سيرٌ هادئٌ بين تحدٍّ وآخر.
  travelling,

  /// بناءُ التحدّي قادمٌ واللاعب يقرأ ويختار طريقَه.
  approaching,

  /// لحظةُ المكافأة بعد إجابةٍ صحيحة.
  rewarding,

  /// المعلّم والمخطوطة بعد إجابةٍ خاطئة.
  correcting,
}

/// اللعبة نفسُها: عالمٌ يسير، وبواباتٌ تحمل الجُمل، وطريقان يختار اللاعب أحدهما
/// بحركته لا بضغطة زرّ.
///
/// كلُّ ما يخصّ صحّةَ الإجابة والمكافأة يجري في [SessionEngine]؛ ودورُ هذا
/// الصنف أن يترجم «أين وقف اللاعب حين عبَر البوابة» إلى «أيّ مسارٍ اختار».
class RihlaGame extends FlameGame with PanDetector, KeyboardEvents {
  RihlaGame({required this.sessionEngine})
      : super(
          camera: CameraComponent.withFixedResolution(
            width: GameConfig.worldWidth,
            height: GameConfig.worldHeight,
          ),
        );

  final SessionEngine sessionEngine;

  /// حصيلةُ الجلسة معروضةً للواجهة دون أن تعرف الواجهةُ شيئًا عن اللعبة.
  final ValueNotifier<SessionStats> stats =
      ValueNotifier(const SessionStats());

  late final PlayerCharacter player;
  late final List<ScrollingLayer> _layers;

  GamePhase phase = GamePhase.travelling;

  ChallengeGate? _activeGate;
  CorrectionScroll? _correction;

  double _speed = GameConfig.cruiseSpeed;
  double _targetSpeed = GameConfig.cruiseSpeed;
  double _distanceToNextChallenge = 320;

  // مرجعُ السحب: نحرّك الشخصية بمقدار إزاحة الإصبع لا بموضعه المطلق،
  // كيلا تقفز الشخصيةُ إلى موضع اللمسة الأولى.
  double _dragStartPointerY = 0;
  double _dragStartTargetY = 0;

  @override
  Future<void> onLoad() async {
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();

    _layers = [
      HillsLayer(parallaxFactor: 0.18, priority: 1),
      VillageLayer(parallaxFactor: 0.42, priority: 2),
      RoadLayer(priority: 3),
    ];

    world.addAll([SkyLayer(priority: 0), ..._layers]);

    player = PlayerCharacter();
    world.add(player);

    _publishStats();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _speed += (_targetSpeed - _speed) *
        (GameConfig.speedLerpRate * dt).clamp(0.0, 1.0);
    final distance = _speed * dt;

    for (final layer in _layers) {
      layer.scroll(distance);
    }

    _advanceGates(distance);
    _applyLaneMagnetism(dt);
    _applyReadingSlowdown();

    if (phase == GamePhase.travelling || phase == GamePhase.rewarding) {
      _distanceToNextChallenge -= distance;
      if (_distanceToNextChallenge <= 0 && _activeGate == null) {
        _spawnChallenge();
      }
    }
  }

  void _advanceGates(double distance) {
    final gate = _activeGate;
    if (gate == null) return;

    gate.position.x += distance;

    if (!gate.isResolved && gate.gatePlaneWorldX >= GameConfig.playerX) {
      _commitAnswer(gate);
    }

    if (gate.isOffScreen) {
      gate.removeFromParent();
      _activeGate = null;
    }
  }

  /// يتمهّل المسافرُ كلّما دنا من اللوحة، فيتّسع وقتُ القراءة دون أن يقف العالم.
  void _applyReadingSlowdown() {
    final gate = _activeGate;
    if (gate == null || gate.isResolved) return;

    // البوابةُ تأتي من اليسار، فالمسافةُ المتبقّية موجبةٌ ما لم يبلغها اللاعب بعد.
    final remaining = GameConfig.playerX - gate.gatePlaneWorldX;
    if (remaining > GameConfig.readingDistance) return;

    final closeness =
        (1 - remaining / GameConfig.readingDistance).clamp(0.0, 1.0);
    _targetSpeed = GameConfig.challengeSpeed +
        (GameConfig.readingSpeed - GameConfig.challengeSpeed) * closeness;
  }

  /// انجذابٌ لطيفٌ نحو مركز أقرب مسارٍ عند اقتراب البوابة،
  /// حتى لا يُحرم اللاعبُ من إجابةٍ يعرفها بسبب دقّة إصبعه.
  void _applyLaneMagnetism(double dt) {
    final gate = _activeGate;
    if (gate == null || gate.isResolved) return;

    final remaining = GameConfig.playerX - gate.gatePlaneWorldX;
    if (remaining > 210) return;

    final laneY = GameConfig.laneCenters[player.nearestLaneIndex];
    final pull = (GameConfig.laneMagnetism * dt).clamp(0.0, 1.0);
    player.targetY = player.targetY + (laneY - player.targetY) * pull;
  }

  void _spawnChallenge() {
    final challenge = sessionEngine.nextChallenge();
    final gate = ChallengeGate(
      challenge: challenge,
      startX: -GameConfig.challengeWidth,
    );
    _activeGate = gate;
    world.add(gate);

    phase = GamePhase.approaching;
    _targetSpeed = GameConfig.challengeSpeed;
  }

  void _commitAnswer(ChallengeGate gate) {
    final laneIndex = player.nearestLaneIndex;
    final result = sessionEngine.submitLane(laneIndex);

    gate.markResolved(laneIndex: laneIndex, isCorrect: result.isCorrect);
    _publishStats();

    if (result.isCorrect) {
      _onCorrect(result);
    } else {
      _onWrong(result);
    }
  }

  void _onCorrect(AnswerResult result) {
    phase = GamePhase.rewarding;
    _targetSpeed = GameConfig.cruiseSpeed;
    _distanceToNextChallenge = GameConfig.gapBetweenChallenges;

    player.setState(PlayerState.celebrating, duration: 0.9);

    world.add(
      FloatingText(
        text: 'أحسنتَ  +${result.xpAwarded}',
        origin: Vector2(GameConfig.playerX - 20, player.position.y - 120),
        color: AppPalette.gold,
      ),
    );

    if (result.streakAfter >= 3) {
      world.add(
        FloatingText(
          text: 'سلسلةٌ متّصلة × ${result.streakAfter}',
          origin: Vector2(GameConfig.playerX - 20, player.position.y - 170),
          color: AppPalette.success,
          fontSize: 19,
          lifetime: 1.4,
        ),
      );
    }
  }

  void _onWrong(AnswerResult result) {
    phase = GamePhase.correcting;
    _targetSpeed = GameConfig.correctionSpeed;

    player.setState(PlayerState.stumbling, duration: 1.4);

    final correction = CorrectionScroll(
      result: result,
      onDismissed: _resumeAfterCorrection,
    );
    _correction = correction;
    world.add(correction);
  }

  void _resumeAfterCorrection() {
    _correction = null;
    phase = GamePhase.travelling;
    _targetSpeed = GameConfig.cruiseSpeed;
    _distanceToNextChallenge = GameConfig.gapBetweenChallenges;
  }

  void _publishStats() => stats.value = sessionEngine.stats;

  // ── التحكّم باللمس ──

  @override
  void onPanStart(DragStartInfo info) {
    _dragStartPointerY = _toWorldY(info.eventPosition.widget);
    _dragStartTargetY = player.targetY;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final pointerY = _toWorldY(info.eventPosition.widget);
    player.targetY = _dragStartTargetY + (pointerY - _dragStartPointerY);
  }

  double _toWorldY(Vector2 widgetPoint) => camera.globalToLocal(widgetPoint).y;

  // ── تحكّمٌ بلوحة المفاتيح، لتيسير الاختبار على الحاسوب وللإتاحة ──

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final lanes = GameConfig.laneCenters;
    final current = player.nearestLaneIndex;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      player.targetY = lanes[(current - 1).clamp(0, lanes.length - 1)];
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      player.targetY = lanes[(current + 1).clamp(0, lanes.length - 1)];
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _correction?.dismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void onRemove() {
    stats.dispose();
    super.onRemove();
  }
}
