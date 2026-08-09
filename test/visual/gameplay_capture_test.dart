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
import 'package:rihlat_alarabiyya/domain/engines/question_selector.dart';
import 'package:rihlat_alarabiyya/domain/engines/session_engine.dart';
import 'package:rihlat_alarabiyya/domain/models/question.dart';
import 'package:rihlat_alarabiyya/game/config/game_config.dart';
import 'package:rihlat_alarabiyya/game/rihla_game.dart';

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

    final game = RihlaGame(
      sessionEngine: SessionEngine(
        selector: ShuffledQuestionSelector(
          questions: questions,
          random: Random(seed),
        ),
        challengeFactory: ChallengeFactory(
          laneCount: GameConfig.laneCount,
          random: Random(seed),
        ),
      ),
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
    game.player.targetY = GameConfig.laneCenters[challenge.correctIndex];

    // التقدّمُ خطوةً خطوةً حتى لحظة العبور نفسِها.
    var captured = false;
    for (var i = 0; i < 260 && !captured; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (game.stats.value.answered == 1) {
        await tester.pump(const Duration(milliseconds: 160));
        await capture(tester, '04_crossing_correct');
        captured = true;
      }
    }
    expect(captured, isTrue, reason: 'لم تبلغ البوابةُ اللاعبَ في الوقت المتوقّع');

    await advance(tester, 1.2);
    await capture(tester, '04b_reward');

    expect(game.stats.value.correct, 1,
        reason: 'دخولُ المسار الصحيح يجب أن يُحتسب إجابةً صحيحة');
    expect(game.stats.value.xp, greaterThan(0));
  });

  testWidgets('المسار الخاطئ يستدعي المعلّم والمخطوطة', (tester) async {
    final game = await pumpGame(tester, seed: 11);

    await advance(tester, 6.0);
    final challenge = game.sessionEngine.currentChallenge!;
    game.player.targetY =
        GameConfig.laneCenters[1 - challenge.correctIndex];

    await advance(tester, 4.2);
    await capture(tester, '05_correction');

    expect(game.stats.value.answered, 1);
    expect(game.stats.value.correct, 0);
    expect(game.phase, GamePhase.correcting);

    // المخطوطة تنطوي وحدَها فيعود اللاعب إلى طريقه.
    await advance(tester, 5.0);
    await capture(tester, '06_resumed');
    expect(game.phase, isNot(GamePhase.correcting));
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
