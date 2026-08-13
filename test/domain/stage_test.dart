import 'package:flutter_test/flutter_test.dart';
import 'package:rihlat_alarabiyya/domain/engines/stage_grader.dart';
import 'package:rihlat_alarabiyya/domain/models/stage_definition.dart';

void main() {
  group('StageCatalog', () {
    test('خمسُ مراحلَ مرقَّمةٌ بالتتابع من ١', () {
      expect(StageCatalog.count, 5);
      for (var i = 0; i < StageCatalog.all.length; i++) {
        expect(StageCatalog.all[i].index, i + 1);
      }
    });

    test('كلّ مرحلةٍ عشرون بوّابةً ونصابُها خمسةَ عشرَ', () {
      for (final stage in StageCatalog.all) {
        expect(stage.gatesPerStage, 20);
        expect(stage.passScore, 15);
        expect(stage.passScore, lessThan(stage.gatesPerStage));
      }
    });

    test('عناوينُ المراحل مميّزةٌ ولا تتكرّر', () {
      final titles = StageCatalog.all.map((s) => s.title).toSet();
      expect(titles.length, StageCatalog.count);
    });

    test('byIndex يعيد المرحلةَ الصحيحة ويرفض رقمًا خارج المدى', () {
      expect(StageCatalog.byIndex(1).title, 'أقسامُ الكلام');
      expect(StageCatalog.byIndex(5).title, 'التوابع');
      expect(() => StageCatalog.byIndex(0), throwsRangeError);
      expect(() => StageCatalog.byIndex(6), throwsRangeError);
    });

    test('hasStage يوافق مدى المراحل المعرَّفة', () {
      expect(StageCatalog.hasStage(1), isTrue);
      expect(StageCatalog.hasStage(5), isTrue);
      expect(StageCatalog.hasStage(0), isFalse);
      expect(StageCatalog.hasStage(6), isFalse);
    });
  });

  group('StageGrader', () {
    test('النجاحُ ببلوغ النصاب أو تجاوزه', () {
      expect(StageGrader.passed(correct: 15, passScore: 15), isTrue);
      expect(StageGrader.passed(correct: 20, passScore: 15), isTrue);
    });

    test('الإخفاقُ دون النصاب', () {
      expect(StageGrader.passed(correct: 14, passScore: 15), isFalse);
      expect(StageGrader.passed(correct: 0, passScore: 15), isFalse);
    });
  });
}
