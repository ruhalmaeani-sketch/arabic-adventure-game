import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../app/theme/app_palette.dart';
import '../domain/content/encouragement.dart';
import '../domain/engines/session_engine.dart';
import '../domain/engines/staged_question_selector.dart';
import '../domain/models/answer_result.dart';
import '../services/audio_service.dart';
import 'config/game_config.dart';
import 'entities/challenge_gate.dart';
import 'entities/correction_sign.dart';
import 'entities/floating_text.dart';
import 'entities/player_character.dart';
import 'entities/torch_pickup.dart';
import 'world/atmosphere.dart';
import 'world/perspective.dart';
import 'world/scenery.dart';

/// أطوار الحلقة الأساسيّة.
enum GamePhase { travelling, approaching, rewarding, correcting }

/// حصيلةٌ معروضةٌ للواجهة: حالُ اللاعب وما جمعه وما بلغه من المراحل.
@immutable
class HudState {
  const HudState({
    required this.stats,
    required this.torches,
    required this.stage,
    required this.atmosphereName,
  });

  final SessionStats stats;
  final int torches;
  final int stage;
  final String atmosphereName;

  bool get canSwitchAtmosphere => torches >= GameConfig.torchesPerAtmosphere;
}

/// اللعبة: طريقٌ يمتدّ إلى الأفق، واللاعب يصعده من أسفل الشاشة إلى أعلاها،
/// فتقبل عليه بوابةٌ تحمل جملةً وبابين، فيجيب بدخوله أحدَهما.
class RihlaGame extends FlameGame with PanDetector, KeyboardEvents {
  RihlaGame({
    required this.sessionEngine,
    required this.selector,
    AudioService? audio,
    math.Random? random,
  })  : audio = audio ?? SilentAudioService(),
        _random = random ?? math.Random(),
        _encouragement = Encouragement(random: random),
        super(
          camera: CameraComponent.withFixedResolution(
            width: GameConfig.worldWidth,
            height: GameConfig.worldHeight,
          ),
        );

  final SessionEngine sessionEngine;

  /// محرّكُ الاختيار المتدرّج؛ نحتفظ به لنعرض رقمَ المرحلة للاعب.
  final StagedQuestionSelector selector;

  final AudioService audio;
  final math.Random _random;
  final Encouragement _encouragement;

  final ValueNotifier<HudState> hud = ValueNotifier(
    const HudState(
      stats: SessionStats(),
      torches: 0,
      stage: 1,
      atmosphereName: 'غروبُ القرية',
    ),
  );

  final SceneState scene = SceneState();

  late final PlayerCharacter player;

  GamePhase phase = GamePhase.travelling;

  ChallengeGate? _activeGate;
  CorrectionSign? _correction;
  final List<TorchPickup> _torches = [];

  int torchesCollected = 0;
  int _stage = 1;

  double _speed = GameConfig.cruiseSpeed;
  double _targetSpeed = GameConfig.cruiseSpeed;
  double _distanceToNextChallenge = 900;
  double _distanceToNextTorch = 620;

  double _dragStartPointerX = 0;
  double _dragStartTargetX = 0;

  @override
  Future<void> onLoad() async {
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();

    world.addAll([
      SkyLayer(scene, priority: 0),
      RoadLayer(scene, priority: 1),
    ]);

    player = PlayerCharacter(priority: 40);
    world.add(player);

    _publish();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _speed += (_targetSpeed - _speed) *
        (GameConfig.speedLerpRate * dt).clamp(0.0, 1.0);
    final travelled = _speed * dt;
    scene.travelled += travelled;

    _advanceGate(travelled);
    _advanceTorches(travelled);
    _applyLaneMagnetism(dt);
    _applyReadingSlowdown();

    if (phase == GamePhase.travelling || phase == GamePhase.rewarding) {
      _distanceToNextChallenge -= travelled;
      if (_distanceToNextChallenge <= 0 && _activeGate == null) {
        _spawnChallenge();
      }
    }

    _distanceToNextTorch -= travelled;
    if (_distanceToNextTorch <= 0) _spawnTorch();
  }

  // ── البوابة ──

  void _advanceGate(double travelled) {
    final gate = _activeGate;
    if (gate == null) return;

    gate.z -= travelled;

    if (!gate.isResolved && gate.z <= GameConfig.playerZ) {
      _commitAnswer(gate);
    }

    if (gate.isBehindCamera) {
      gate.removeFromParent();
      _activeGate = null;
    }
  }

  /// يتمهّل المسافرُ كلّما دنا من اللوحة، فيتّسع وقتُ القراءة دون أن يقف العالم.
  void _applyReadingSlowdown() {
    final gate = _activeGate;
    if (gate == null || gate.isResolved) return;

    final remaining = gate.distanceToPlayer;
    if (remaining > GameConfig.readingDistance) return;

    final closeness =
        (1 - remaining / GameConfig.readingDistance).clamp(0.0, 1.0);
    _targetSpeed = GameConfig.challengeSpeed +
        (GameConfig.readingSpeed - GameConfig.challengeSpeed) * closeness;
  }

  /// انجذابٌ لطيفٌ نحو محور أقرب مسارٍ عند اقتراب البوابة،
  /// حتى لا يُحرم اللاعبُ من إجابةٍ يعرفها بسبب دقّة إصبعه.
  void _applyLaneMagnetism(double dt) {
    final gate = _activeGate;
    if (gate == null || gate.isResolved) return;
    if (gate.distanceToPlayer > 520) return;

    final laneX = GameConfig.laneOffsets[player.nearestLaneIndex];
    final pull = (GameConfig.laneMagnetism * dt).clamp(0.0, 1.0);
    player.targetX = player.targetX + (laneX - player.targetX) * pull;
  }

  void _spawnChallenge() {
    final challenge = sessionEngine.nextChallenge();
    final gate = ChallengeGate(
      challenge: challenge,
      scene: scene,
      priority: 20,
    );
    _activeGate = gate;
    world.add(gate);

    phase = GamePhase.approaching;
    _targetSpeed = GameConfig.challengeSpeed;

    if (selector.stage != _stage) {
      _stage = selector.stage;
      audio.play(GameSound.stage);
      _announce('المرحلة $_stage — ترتفع الصعوبة', AppPalette.parchment);
    }
    _publish();
  }

  void _commitAnswer(ChallengeGate gate) {
    final laneIndex = player.nearestLaneIndex;
    final result = sessionEngine.submitLane(laneIndex);

    gate.markResolved(laneIndex: laneIndex, isCorrect: result.isCorrect);

    if (result.isCorrect) {
      _onCorrect(result);
    } else {
      _onWrong(result);
    }
    _publish();
  }

  void _onCorrect(AnswerResult result) {
    phase = GamePhase.rewarding;
    _targetSpeed = GameConfig.cruiseSpeed;
    _distanceToNextChallenge = GameConfig.gapBetweenChallenges;

    player.setState(PlayerState.celebrating, duration: 0.9);
    audio.play(GameSound.correct);

    final head = player.headScreenPosition;
    world.add(
      FloatingText(
        text: '${_encouragement.phraseFor(streak: result.streakAfter)}'
            '   +${result.xpAwarded}',
        origin: Vector2(head.dx, head.dy - 40),
        color: AppPalette.gold,
        priority: 50,
      ),
    );

    if (result.streakAfter >= 3) {
      world.add(
        FloatingText(
          text: 'سلسلةٌ متّصلة × ${result.streakAfter}',
          origin: Vector2(head.dx, head.dy - 92),
          color: AppPalette.success,
          fontSize: 19,
          lifetime: 1.5,
          priority: 50,
        ),
      );
    }
  }

  void _onWrong(AnswerResult result) {
    phase = GamePhase.correcting;
    _targetSpeed = GameConfig.correctionSpeed;

    player.setState(PlayerState.stumbling, duration: 1.6);
    audio.play(GameSound.wrong);

    final correction = CorrectionSign(
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

  // ── الشعلات ──

  void _spawnTorch() {
    // لا تُلقى شعلةٌ في وجه بوابةٍ مقبلة، كيلا تشتّت اللاعبَ عن القراءة.
    final gate = _activeGate;
    final busy = gate != null && gate.distanceToPlayer < 1200;
    _distanceToNextTorch = 520 + _random.nextDouble() * 620;
    if (busy) return;

    final lane = GameConfig.laneOffsets[_random.nextInt(GameConfig.laneCount)];
    final torch = TorchPickup(
      lateralX: lane,
      spawnZ: GameConfig.challengeSpawnZ,
      priority: 15,
    );
    _torches.add(torch);
    world.add(torch);
  }

  void _advanceTorches(double travelled) {
    for (final torch in List<TorchPickup>.of(_torches)) {
      torch.z -= travelled;

      if (torch.canBeCollectedBy(player.lateralX)) {
        torch.collect();
        torchesCollected++;
        audio.play(GameSound.torch);
        final head = player.headScreenPosition;
        world.add(
          FloatingText(
            text: 'شعلة +١',
            origin: Vector2(head.dx + 42, head.dy - 10),
            color: const Color(0xFFFFC061),
            fontSize: 20,
            lifetime: 0.9,
            priority: 50,
          ),
        );
        _publish();
      }

      if (torch.isBehindCamera || torch.isCollected) {
        torch.removeFromParent();
        _torches.remove(torch);
      }
    }
  }

  /// يبدّل جوَّ الرحلة مقابل شعلات. يُستدعى من الواجهة.
  bool switchAtmosphere() {
    if (torchesCollected < GameConfig.torchesPerAtmosphere) return false;
    torchesCollected -= GameConfig.torchesPerAtmosphere;
    scene.atmosphere = scene.atmosphere.next;
    audio.play(GameSound.ambience);
    _announce(scene.atmosphere.name, AppPalette.parchment);
    _publish();
    return true;
  }

  void _announce(String text, Color color) {
    world.add(
      FloatingText(
        text: text,
        origin: Vector2(GameConfig.worldWidth / 2, GameConfig.horizonY + 96),
        color: color,
        fontSize: 24,
        lifetime: 2.0,
        rise: 26,
        priority: 55,
      ),
    );
  }

  void _publish() {
    hud.value = HudState(
      stats: sessionEngine.stats,
      torches: torchesCollected,
      stage: selector.stage,
      atmosphereName: scene.atmosphere.name,
    );
  }

  // ── التحكّم باللمس: سحبٌ أفقيٌّ يوجّه المسافرَ بين الطريقين ──

  @override
  void onPanStart(DragStartInfo info) {
    _dragStartPointerX = _toWorldX(info.eventPosition.widget);
    _dragStartTargetX = player.targetX;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final pointerX = _toWorldX(info.eventPosition.widget);
    player.targetX = _dragStartTargetX + (pointerX - _dragStartPointerX);
  }

  /// يحوّل إحداثيَّ الإصبع إلى انحرافٍ جانبيٍّ في العالم عند بُعد اللاعب.
  double _toWorldX(Vector2 widgetPoint) {
    final local = camera.globalToLocal(widgetPoint);
    return (local.x - GameConfig.worldWidth / 2) /
        Perspective.scaleAt(GameConfig.playerZ);
  }

  // ── لوحة المفاتيح: للاختبار على الحاسوب وللإتاحة ──

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      player.targetX = GameConfig.laneOffsets.first;
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      player.targetX = GameConfig.laneOffsets.last;
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
    hud.dispose();
    super.onRemove();
  }
}

/// جوُّ البداية معروضٌ للواجهة قبل أن تبدأ اللعبة.
const Atmosphere defaultAtmosphere = Atmosphere.dusk;
