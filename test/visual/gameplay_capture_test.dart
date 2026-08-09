import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:rihlat_alarabiyya/data/repositories/asset_question_repository.dart';
import 'package:rihlat_alarabiyya/domain/engines/challenge_factory.dart';
import 'package:rihlat_alarabiyya/domain/engines/session_engine.dart';
import 'package:rihlat_alarabiyya/domain/engines/staged_question_selector.dart';
import 'package:rihlat_alarabiyya/domain/models/question.dart';
import 'package:rihlat_alarabiyya/domain/models/outfit.dart';
import 'package:rihlat_alarabiyya/game/config/game_config.dart';
import 'package:rihlat_alarabiyya/game/rihla_game.dart';
import 'package:rihlat_alarabiyya/game/world/realm.dart';

/// مِشْحَنَةُ تحقّقٍ بصريّ: تشغّل اللعبة داخل محرّك Flutter وتلتقط إطاراتٍ حقيقيّة
/// إلى `build/screens/`، فيمكن الحكمُ على المشهد بالعين لا بالظنّ.
///
/// ليست هذه اختبارَ تثبيتٍ للصور (golden)؛ الغرضُ منها المعاينةُ أثناء التطوير،
/// ولذلك تتحقّق فقط من أنَّ اللعبة تدور دون استثناء.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const outputDirectory = 'build/screens';
  final captureKey = GlobalKey();

  late List<Question> questions;

  setUpAll(() async {
    questions = AssetQuestionRepository.parseLevel(
      File('assets/content/questions/level_1.json').readAsStringSync(),
    );
    Directory(outputDirectory).createSync(recursive: true);

    // بيئةُ الاختبار لا تسجّل خطوطَ الحزمة تلقائيًّا،
    // ولا معنى لمعاينةِ لعبةٍ عربيّةٍ بخطٍّ بديل.
    await _registerFont('Amiri', const [
      'assets/fonts/Amiri-Regular.ttf',
      'assets/fonts/Amiri-Bold.ttf',
    ]);
    await _registerFont('Cairo', const ['assets/fonts/Cairo-Regular.ttf']);
    await _registerFont(
      'NotoEmoji',
      const ['assets/fonts/NotoEmoji-Regular.ttf'],
    );
  });

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outputDirectory/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<RihlaGame> pumpGame(WidgetTester tester, {int seed = 3}) async {
    tester.view
      ..physicalSize = const Size(824, 1760)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final selector = StagedQuestionSelector(
      questions: questions,
      challengesPerStage: GameConfig.challengesPerStage,
      random: Random(seed),
    );
    final game = RihlaGame(
      sessionEngine: SessionEngine(
        selector: selector,
        challengeFactory: ChallengeFactory(
          laneCount: GameConfig.laneCount,
          random: Random(seed),
        ),
      ),
      selector: selector,
      random: Random(seed),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: captureKey,
          child: GameWidget(game: game),
        ),
      ),
    );

    // منح Flame فرصةَ إنهاء onLoad قبل تدوير الحلقة.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    return game;
  }

  /// يدفع الزمنَ إلى الأمام بخطواتٍ ثابتة، فتكون النتائج قابلةً للتكرار.
  Future<void> advance(WidgetTester tester, double seconds) async {
    final steps = (seconds / 0.016).round();
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('الحلقة الأساسيّة تدور وتُلتقط مشاهدُها', (tester) async {
    final game = await pumpGame(tester);

    await capture(tester, '01_travelling');

    // انتظارُ وصول البوابة إلى مدى القراءة.
    await advance(tester, 4.0);
    await capture(tester, '02_gate_approaching');

    await advance(tester, 2.6);
    await capture(tester, '03_gate_readable');

    // اختيارُ المسار الصحيح بالحركة لا بالضغط.
    final challenge = game.sessionEngine.currentChallenge!;
    game.player.targetX = GameConfig.laneOffsets[challenge.correctIndex];

    // التقدّمُ خطوةً خطوةً حتى لحظة العبور نفسِها.
    var captured = false;
    for (var i = 0; i < 260 && !captured; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (game.hud.value.stats.answered == 1) {
        await tester.pump(const Duration(milliseconds: 160));
        await capture(tester, '04_crossing_correct');
        captured = true;
      }
    }
    expect(captured, isTrue, reason: 'لم تبلغ البوابةُ اللاعبَ في الوقت المتوقّع');

    await advance(tester, 1.2);
    await capture(tester, '04b_reward');

    expect(game.hud.value.stats.correct, 1,
        reason: 'دخولُ المسار الصحيح يجب أن يُحتسب إجابةً صحيحة');
    expect(game.hud.value.stats.xp, greaterThan(0));
  });

  testWidgets('المسار الخاطئ يستدعي المعلّم واللافتة، ولا تنصرف إلّا بلمسة',
      (tester) async {
    final game = await pumpGame(tester, seed: 11);

    await advance(tester, 6.0);
    final challenge = game.sessionEngine.currentChallenge!;
    game.player.targetX =
        GameConfig.laneOffsets[1 - challenge.correctIndex];

    await advance(tester, 4.2);
    await capture(tester, '05_correction');

    expect(game.hud.value.stats.answered, 1);
    expect(game.hud.value.stats.correct, 0);
    expect(game.phase, GamePhase.correcting);

    // اللافتةُ لا تنصرف بمرور الوقت مهما طال؛ هذا شرطُ التصميم.
    await advance(tester, 6.0);
    expect(
      game.phase,
      GamePhase.correcting,
      reason: 'اللافتة يجب أن تنتظر لمسةَ اللاعب لا أن تنصرف وحدَها',
    );

    // لمسةٌ واحدةٌ تُنهيها وتعيد اللاعبَ إلى طريقه.
    await tester.tapAt(const Offset(206, 440));
    await advance(tester, 1.2);
    await capture(tester, '06_resumed');
    expect(game.phase, isNot(GamePhase.correcting));
  });


  testWidgets('لكلّ إقليمٍ هيئتُه، ولكلّ زيٍّ صورتُه', (tester) async {
    final game = await pumpGame(tester, seed: 5);
    await advance(tester, 1.0);

    for (var i = 0; i < Realm.all.length; i++) {
      game.scene.realm = Realm.all[i];
      game.player.outfit = Outfit.all[i % Outfit.all.length];
      await advance(tester, 0.6);
      await capture(tester, 'realm_${i}_${Realm.all[i].id}');
    }

    expect(game.scene.realm.id, Realm.all.last.id);
  });

  testWidgets('الانطلاقُ يتجاوز البوابةَ فلا تُحسب له ولا عليه',
      (tester) async {
    final game = await pumpGame(tester, seed: 13);

    // إصابتان متّصلتان تفتحان الانطلاق.
    for (var i = 0; i < 2; i++) {
      var answered = false;
      for (var f = 0; f < 900 && !answered; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        final challenge = game.sessionEngine.currentChallenge;
        if (challenge != null) {
          game.player.targetX = GameConfig.laneOffsets[challenge.correctIndex];
        }
        answered = game.hud.value.stats.correct == i + 1;
      }
      expect(answered, isTrue, reason: 'لم تُسجَّل الإصابة رقم ${i + 1}');
    }

    expect(game.isTurboReady, isTrue);
    expect(game.startTurbo(), isTrue);

    final before = game.hud.value.stats;
    await advance(tester, 0.8);
    await capture(tester, '07_turbo');

    // أثناء الانطلاق تمرّ البواباتُ دون أن تُحسب.
    await advance(tester, GameConfig.turboDuration - 1.0);
    final after = game.hud.value.stats;

    expect(after.answered, before.answered,
        reason: 'البوّابةُ المتجاوَزة لا تُحتسب إجابة');
    expect(after.currentStreak, before.currentStreak,
        reason: 'التجاوزُ لا يكسر السلسلة');
  });
}

/// يسجّل خطًّا من ملفّات المشروع في محرّك الاختبار.
Future<void> _registerFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}
