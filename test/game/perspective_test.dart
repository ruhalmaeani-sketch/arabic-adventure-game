import 'package:flutter_test/flutter_test.dart';
import 'package:rihlat_alarabiyya/game/config/game_config.dart';
import 'package:rihlat_alarabiyya/game/world/perspective.dart';

/// رياضيّاتُ المنظور هي أساسُ المشهد كلِّه: موضعُ الطريق، وحجمُ البوابة،
/// وكِبَرُ النصّ وهو يقترب. خطأٌ فيها يفسد الصورةَ كلَّها، فتُختبر وحدَها
/// بلا رسمٍ ولا جهاز.
void main() {
  group('Perspective', () {
    test('القربُ يملأ العينَ والبُعدُ يتضاءل', () {
      expect(Perspective.scaleAt(0), 1.0);
      expect(Perspective.scaleAt(GameConfig.focalLength), closeTo(0.5, 1e-9));
      expect(Perspective.scaleAt(3000), lessThan(0.11));
    });

    test('كلّما بعُد الشيءُ ارتفع نحو الأفق ولم يتجاوزه', () {
      final near = Perspective.groundY(0);
      final mid = Perspective.groundY(600);
      final far = Perspective.groundY(3000);

      expect(near, GameConfig.roadBaseY);
      expect(mid, lessThan(near));
      expect(far, lessThan(mid));
      expect(far, greaterThan(GameConfig.horizonY));
    });

    test('الطريقُ يضيق مع البعد ويلتقي عند الأفق', () {
      expect(Perspective.roadHalfWidthAt(0), GameConfig.roadHalfWidth);
      expect(
        Perspective.roadHalfWidthAt(1200),
        lessThan(Perspective.roadHalfWidthAt(300)),
      );
    });

    test('المساران ينطبقان على المحور كلّما بعُدا', () {
      final nearRight = Perspective.project(GameConfig.laneOffsets.first, 60);
      final farRight = Perspective.project(GameConfig.laneOffsets.first, 2000);
      const centerX = GameConfig.worldWidth / 2;

      expect(nearRight.dx - centerX, greaterThan(farRight.dx - centerX));
      expect(farRight.dx, greaterThan(centerX));
    });

    test('الارتفاعُ يرفع الشيءَ فوق نقطة الأرض بنسبة قربه', () {
      const z = 400.0;
      final ground = Perspective.project(0, z);
      final raised = Perspective.project(0, z, height: 200);

      expect(raised.dy, lessThan(ground.dy));
      expect(
        ground.dy - raised.dy,
        closeTo(200 * Perspective.scaleAt(z), 1e-9),
      );
    });

    test('الضبابُ ينعدم قريبًا ويشتدّ عند الأفق', () {
      expect(Perspective.hazeAt(100), 0);
      expect(Perspective.hazeAt(GameConfig.hazeStartZ), 0);
      expect(
        Perspective.hazeAt(GameConfig.farClipZ),
        closeTo(GameConfig.hazeMaxOpacity, 1e-9),
      );
    });

    test('بوابةُ الظهور داخل المدى المرئيّ، وما خلف الكاميرا خارجَه', () {
      expect(Perspective.isVisible(GameConfig.challengeSpawnZ), isTrue);
      expect(Perspective.isVisible(GameConfig.playerZ), isTrue);
      expect(Perspective.isVisible(GameConfig.nearClipZ - 1), isFalse);
    });
  });
}
