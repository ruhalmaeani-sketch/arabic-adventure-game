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
import '../domain/models/outfit.dart';
import '../services/audio_service.dart';
import 'config/game_config.dart';
import 'entities/book_pickup.dart';
import 'entities/challenge_gate.dart';
import 'entities/correction_sign.dart';
import 'entities/floating_text.dart';
import 'entities/player_character.dart';
import 'entities/torch_pickup.dart';
import 'world/perspective.dart';
import 'world/realm.dart';
import 'world/scenery.dart';

/// أطوار الحلقة الأساسيّة.
enum GamePhase { travelling, approaching, rewarding, correcting }

/// حصيلةٌ معروضةٌ للواجهة: حالُ اللاعب وما جمعه وما بلغه من المراحل.
@immutable
class HudState {
  const HudState({
    required this.stats,
    required this.torches,
    required this.books,
    required this.stage,
    required this.realmName,
    required this.outfit,
    required this.booksToNextOutfit,
    required this.turboReady,
    required this.turboRemaining,
  });

  final SessionStats stats;
  final int torches;
  final int books;
  final int stage;
  final String realmName;
  final Outfit outfit;
  final int booksToNextOutfit;
  final bool turboReady;

  /// ما بقي من زمن الانطلاق بالثواني؛ صفرٌ إن لم يكن منطلقًا.
  final double turboRemaining;

  bool get canSwitchRealm => torches >= GameConfig.torchesPerRealm;
  bool get isTurboActive => turboRemaining > 0;
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
    HudState(
      stats: const SessionStats(),
      torches: 0,
      books: 0,
      stage: 1,
      realmName: Realm.palmVillage.name,
      outfit: Outfit.student,
      booksToNextOutfit: Outfit.booksToNext(0),
      turboReady: false,
      turboRemaining: 0,
    ),
  );

  final SceneState scene = SceneState();

  late final PlayerCharacter player;

  GamePhase phase = GamePhase.travelling;

  ChallengeGate? _activeGate;
  CorrectionSign? _correction;
  final List<TorchPickup> _torches = [];
  final List<BookPickup> _books = [];

  int torchesCollected = 0;
  int booksCollected = 0;
  int _stage = 1;

  /// ما بقي من زمن الانطلاق؛ صفرٌ إن كان المسافرُ على سيره المعتاد.
  double _turboRemaining = 0;

  double _speed = GameConfig.cruiseSpeed;
  double _targetSpeed = GameConfig.cruiseSpeed;
  double _distanceToNextChallenge = 900;
  double _distanceToNextPickup = 620;

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

    _updateTurbo(dt);

    _speed += (_targetSpeed - _speed) *
        (GameConfig.speedLerpRate * dt).clamp(0.0, 1.0);
    final travelled = _speed * dt;
    scene.travelled += travelled;

    _advanceGate(travelled);
    _advancePickups(travelled);
    _applyLaneMagnetism(dt);
    _applyReadingSlowdown();

    if (phase == GamePhase.travelling || phase == GamePhase.rewarding) {
      _distanceToNextChallenge -= travelled;
      if (_distanceToNextChallenge <= 0 && _activeGate == null) {
        _spawnChallenge();
      }
    }

    _distanceToNextPickup -= travelled;
    if (_distanceToNextPickup <= 0) _spawnPickup();
  }

  // ── الانطلاق ──

  bool get isTurboActive => _turboRemaining > 0;

  /// هل استحقّ اللاعبُ الانطلاقَ بسلسلة إصاباته؟
  bool get isTurboReady =>
      !isTurboActive &&
      sessionEngine.stats.currentStreak >= GameConfig.turboStreakRequirement &&
      phase != GamePhase.correcting;

  /// ينطلق المسافرُ فيطوي الطريقَ ويتجاوز البوابات دون أن تُحسب له ولا عليه.
  bool startTurbo() {
    if (!isTurboReady) return false;
    _turboRemaining = GameConfig.turboDuration;
    audio.play(GameSound.stage);
    _announce('انطلاق!', AppPalette.gold);
    _publish();
    return true;
  }

  void _updateTurbo(double dt) {
    if (_turboRemaining <= 0) {
      scene.turbo += (0 - scene.turbo) * (4 * dt).clamp(0.0, 1.0);
      player.turbo = scene.turbo;
      return;
    }

    _turboRemaining -= dt;
    if (_turboRemaining <= 0) {
      _turboRemaining = 0;
      _targetSpeed = GameConfig.cruiseSpeed;
      _publish();
    } else {
      _targetSpeed = GameConfig.cruiseSpeed * GameConfig.turboSpeedFactor;
    }

    scene.turbo += (1 - scene.turbo) * (5 * dt).clamp(0.0, 1.0);
    player.turbo = scene.turbo;
  }

  // ── البوابة ──

  void _advanceGate(double travelled) {
    final gate = _activeGate;
    if (gate == null) return;

    gate.z -= travelled;

    if (!gate.isResolved && gate.z <= GameConfig.playerZ) {
      if (isTurboActive) {
        _skipGate(gate);
      } else {
        _commitAnswer(gate);
      }
    }

    if (gate.isBehindCamera) {
      gate.removeFromParent();
      _activeGate = null;
    }
  }

  /// يمرّ المنطلقُ بالبوابة دون أن يُجيب، فلا تُحسب له ولا عليه.
  void _skipGate(ChallengeGate gate) {
    sessionEngine.skipCurrent();
    gate.markSkipped();
    phase = GamePhase.travelling;
    _distanceToNextChallenge = GameConfig.gapBetweenChallenges * 0.5;

    final head = player.headScreenPosition;
    world.add(
      FloatingText(
        text: 'تجاوزتَها',
        origin: Vector2(head.dx, head.dy - 44),
        color: AppPalette.parchment,
        fontSize: 20,
        lifetime: 0.9,
        priority: 50,
      ),
    );
  }

  /// يتمهّل المسافرُ كلّما دنا من اللوحة، فيتّسع وقتُ القراءة دون أن يقف العالم.
  ///
  /// ولا تمهُّلَ أثناء الانطلاق؛ فالمنطلقُ لا يقرأ.
  void _applyReadingSlowdown() {
    if (isTurboActive) return;
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
    if (isTurboActive) return;
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
    _turboRemaining = 0;
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

  // ── الشعلات والكتب ──

  /// تُلقى على الطريق شعلةٌ أو كتاب؛ الشعلةُ تنقل إلى إقليمٍ جديد،
  /// والكتابُ يرقّي هيئةَ المسافر.
  void _spawnPickup() {
    _distanceToNextPickup =
        GameConfig.pickupSpacing * (0.75 + _random.nextDouble() * 0.8);

    // لا يُلقى شيءٌ في وجه بوابةٍ مقبلة كيلا يشتّت اللاعبَ عن القراءة.
    final gate = _activeGate;
    if (gate != null && gate.distanceToPlayer < 1200 && !isTurboActive) return;

    final lane = GameConfig.laneOffsets[_random.nextInt(GameConfig.laneCount)];

    // الكتبُ أندر؛ فهي التي ترقّي الهيئة.
    if (_random.nextDouble() < 0.34) {
      final book = BookPickup(
        lateralX: lane,
        spawnZ: GameConfig.challengeSpawnZ,
        priority: 16,
      );
      _books.add(book);
      world.add(book);
    } else {
      final torch = TorchPickup(
        lateralX: lane,
        spawnZ: GameConfig.challengeSpawnZ,
        priority: 15,
      );
      _torches.add(torch);
      world.add(torch);
    }
  }

  void _advancePickups(double travelled) {
    for (final torch in List<TorchPickup>.of(_torches)) {
      torch.z -= travelled;

      if (torch.canBeCollectedBy(player.lateralX)) {
        torch.collect();
        torchesCollected++;
        audio.play(GameSound.torch);
        _popup('شعلة +١', const Color(0xFFFFC061), 42);
        _publish();
      }

      if (torch.isBehindCamera || torch.isCollected) {
        torch.removeFromParent();
        _torches.remove(torch);
      }
    }

    for (final book in List<BookPickup>.of(_books)) {
      book.z -= travelled;

      if (book.canBeCollectedBy(player.lateralX)) {
        book.collect();
        booksCollected++;
        audio.play(GameSound.torch);
        _popup('كتاب +١', const Color(0xFFE9C46A), -42);
        _applyOutfit();
        _publish();
      }

      if (book.isBehindCamera || book.isCollected) {
        book.removeFromParent();
        _books.remove(book);
      }
    }
  }

  /// يرقّي هيئةَ المسافر إن بلَغ نصابَ زيٍّ جديد.
  void _applyOutfit() {
    final earned = Outfit.forBooks(booksCollected);
    if (earned.id == player.outfit.id) return;

    player.outfit = earned;
    audio.play(GameSound.levelUp);
    _announce('لبستَ زيَّ ${earned.title}', AppPalette.gold);
  }

  /// ينتقل اللاعبُ إلى إقليمٍ جديدٍ مقابل شعلاته. يُستدعى من الواجهة.
  bool switchRealm() {
    if (torchesCollected < GameConfig.torchesPerRealm) return false;
    torchesCollected -= GameConfig.torchesPerRealm;
    scene.realm = scene.realm.next;
    audio.play(GameSound.ambience);
    _announce(scene.realm.name, AppPalette.parchment);
    _publish();
    return true;
  }

  void _popup(String text, Color color, double dx) {
    final head = player.headScreenPosition;
    world.add(
      FloatingText(
        text: text,
        origin: Vector2(head.dx + dx, head.dy - 10),
        color: color,
        fontSize: 20,
        lifetime: 0.95,
        priority: 50,
      ),
    );
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
      books: booksCollected,
      stage: selector.stage,
      realmName: scene.realm.name,
      outfit: player.outfit,
      booksToNextOutfit: Outfit.booksToNext(booksCollected),
      turboReady: isTurboReady,
      turboRemaining: _turboRemaining,
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
    if (event.logicalKey == LogicalKeyboardKey.keyT) {
      startTurbo();
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

