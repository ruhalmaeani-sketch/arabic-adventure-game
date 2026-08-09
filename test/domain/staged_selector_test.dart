import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rihlat_alarabiyya/domain/content/encouragement.dart';
import 'package:rihlat_alarabiyya/domain/engines/staged_question_selector.dart';
import 'package:rihlat_alarabiyya/domain/models/answer_option.dart';
import 'package:rihlat_alarabiyya/domain/models/question.dart';

Question q(String id, int difficulty) => Question(
      id: id,
      kind: QuestionKind.irab,
      sentence: 'يَحْفَظُ الطَّالِبُ الدَّرْسَ',
      targetWordIndex: 1,
      targetWord: 'الطَّالِبُ',
      correctAnswer: const AnswerOption(id: 'fael', label: 'فاعل'),
      wrongAnswers: const [AnswerOption(id: 'mafool_bih', label: 'مفعول به')],
      grammarTopic: 'fael',
      level: 1,
      difficulty: difficulty,
      explanation: 'شرح',
      xp: 10,
      tags: const [],
      sourceType: 'original',
      presentationHints: const [],
      reviewStatus: ReviewStatus.approved,
    );

/// بنكٌ فيه من كلّ صعوبةٍ نصيب.
List<Question> bank() => [
      for (var d = 1; d <= 5; d++)
        for (var i = 0; i < 6; i++) q('q_${d}_$i', d),
    ];

void main() {
  group('StagedQuestionSelector', () {
    test('المرحلةُ تتقدّم بعدد التحدّيات لا بالزمن', () {
      final selector = StagedQuestionSelector(
        questions: bank(),
        challengesPerStage: 3,
        random: Random(1),
      );

      expect(selector.stage, 1);
      selector.selectNext();
      selector.selectNext();
      expect(selector.stage, 1);
      selector.selectNext();
      expect(selector.stage, 2);
    });

    test('سقفُ الصعوبة يرتفع مع المراحل ولا يتجاوز الخمسة', () {
      final selector = StagedQuestionSelector(
        questions: bank(),
        challengesPerStage: 1,
        random: Random(2),
      );

      final ceilings = <int>[];
      for (var i = 0; i < 8; i++) {
        ceilings.add(selector.difficultyWindow.max);
        selector.selectNext();
      }

      expect(ceilings.first, 2);
      expect(ceilings, ceilings.toList()..sort());
      expect(ceilings.last, 5);
    });

    test('المرحلةُ الأولى لا تقدّم أصعبَ ما في البنك', () {
      final selector = StagedQuestionSelector(
        questions: bank(),
        challengesPerStage: 6,
        random: Random(3),
      );

      for (var i = 0; i < 6; i++) {
        expect(selector.selectNext().difficulty, lessThanOrEqualTo(2));
      }
    });

    test('المراحلُ المتأخّرة تترك السهلَ الذي أُتقن', () {
      final selector = StagedQuestionSelector(
        questions: bank(),
        challengesPerStage: 1,
        random: Random(4),
      );

      for (var i = 0; i < 4; i++) {
        selector.selectNext();
      }
      for (var i = 0; i < 8; i++) {
        expect(selector.selectNext().difficulty, greaterThanOrEqualTo(3));
      }
    });

    test('بنكٌ ضيّقٌ لا يُعطّل اللعبة، بل يتّسع المدى له', () {
      // كلُّ الأسئلة صعوبتُها ٥، والمرحلةُ الأولى تطلب ما دون ذلك.
      final selector = StagedQuestionSelector(
        questions: [q('a', 5), q('b', 5)],
        challengesPerStage: 4,
        random: Random(5),
      );

      expect(() => selector.selectNext(), returnsNormally);
      expect(selector.selectNext().difficulty, 5);
    });

    test('لا يعيد السؤالَ نفسَه مباشرةً ما دام في البنك غيرُه', () {
      final selector = StagedQuestionSelector(
        questions: bank(),
        challengesPerStage: 20,
        random: Random(6),
      );

      String? previous;
      for (var i = 0; i < 20; i++) {
        final id = selector.selectNext().id;
        expect(id, isNot(previous));
        previous = id;
      }
    });

    test('بنك أسئلة فارغ مرفوض', () {
      expect(
        () => StagedQuestionSelector(questions: const [], challengesPerStage: 3),
        throwsArgumentError,
      );
    });
  });

  group('Encouragement', () {
    test('لا تتكرّر العبارةُ مرّتين متتاليتين', () {
      final encouragement = Encouragement(random: Random(7));
      String? previous;
      for (var i = 0; i < 40; i++) {
        final phrase = encouragement.phraseFor(streak: i % 5);
        expect(phrase, isNot(previous));
        previous = phrase;
      }
    });

    test('العباراتُ ترتقي مع طول السلسلة', () {
      final encouragement = Encouragement(random: Random(8));
      final short = {for (var i = 0; i < 12; i++) encouragement.phraseFor(streak: 1)};
      final long = {for (var i = 0; i < 12; i++) encouragement.phraseFor(streak: 9)};

      expect(short.intersection(long), isEmpty);
    });
  });
}
