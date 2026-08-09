import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rihlat_alarabiyya/domain/engines/challenge_factory.dart';
import 'package:rihlat_alarabiyya/domain/engines/question_selector.dart';
import 'package:rihlat_alarabiyya/domain/engines/session_engine.dart';
import 'package:rihlat_alarabiyya/domain/models/answer_option.dart';
import 'package:rihlat_alarabiyya/domain/models/question.dart';

Question buildQuestion({String id = 'q1', int xp = 10}) {
  return Question(
    id: id,
    kind: QuestionKind.irab,
    sentence: 'يَحْفَظُ الطَّالِبُ الدَّرْسَ',
    targetWordIndex: 1,
    targetWord: 'الطَّالِبُ',
    correctAnswer: const AnswerOption(id: 'fael', label: 'فاعل'),
    wrongAnswers: const [AnswerOption(id: 'mafool_bih', label: 'مفعول به')],
    grammarTopic: 'fael',
    level: 1,
    difficulty: 1,
    explanation: 'شرح',
    xp: xp,
    tags: const [],
    sourceType: 'original',
    presentationHints: const [],
    reviewStatus: ReviewStatus.approved,
  );
}

SessionEngine buildEngine(List<Question> questions) {
  return SessionEngine(
    selector: ShuffledQuestionSelector(
      questions: questions,
      random: Random(7),
    ),
    challengeFactory: ChallengeFactory(laneCount: 2, random: Random(7)),
  );
}

void main() {
  group('SessionEngine', () {
    test('المسار الصحيح يمنح خبرةً ويزيد السلسلة', () {
      final engine = buildEngine([buildQuestion()]);
      final challenge = engine.nextChallenge();

      final result = engine.submitLane(challenge.correctIndex);

      expect(result.isCorrect, isTrue);
      expect(result.xpAwarded, greaterThan(0));
      expect(result.streakAfter, 1);
      expect(engine.stats.correct, 1);
      expect(engine.stats.answered, 1);
    });

    test('المسار الخاطئ لا يمنح خبرةً ويصفّر السلسلة', () {
      final engine = buildEngine([buildQuestion()]);

      final first = engine.nextChallenge();
      engine.submitLane(first.correctIndex);
      expect(engine.stats.currentStreak, 1);

      final second = engine.nextChallenge();
      final wrongLane = 1 - second.correctIndex;
      final result = engine.submitLane(wrongLane);

      expect(result.isCorrect, isFalse);
      expect(result.xpAwarded, 0);
      expect(result.coinsAwarded, 0);
      expect(engine.stats.currentStreak, 0);
      expect(engine.stats.bestStreak, 1);
    });

    test('مكافأة السلسلة تتصاعد ثمّ تقف عند سقفها', () {
      final engine = buildEngine([buildQuestion(xp: 10)]);

      final awarded = <int>[];
      for (var i = 0; i < 8; i++) {
        final challenge = engine.nextChallenge();
        awarded.add(engine.submitLane(challenge.correctIndex).xpAwarded);
      }

      expect(awarded.first, 10);
      expect(awarded[1], 12);
      expect(awarded.last, lessThanOrEqualTo(20));
      expect(awarded.last, greaterThanOrEqualTo(awarded[1]));
    });

    test('الإجابة بلا تحدٍّ جارٍ خطأٌ برمجيّ صريح', () {
      final engine = buildEngine([buildQuestion()]);
      expect(() => engine.submitLane(0), throwsStateError);
    });

    test('مسارٌ خارج المدى يُرفض', () {
      final engine = buildEngine([buildQuestion()])..nextChallenge();
      expect(() => engine.submitLane(5), throwsRangeError);
    });

    test('الخطأ يحمل معه سببَ الالتباس ليُستفاد منه في التشخيص', () {
      final engine = buildEngine([buildQuestion()]);
      final challenge = engine.nextChallenge();
      final result = engine.submitLane(1 - challenge.correctIndex);

      expect(result.misconception, isNull);
      expect(result.explanation, 'شرح');
    });
  });

  group('ChallengeFactory', () {
    test('يبني عددَ المسارات المطلوب ويضع الصحيحَ في أحدها', () {
      final factory = ChallengeFactory(laneCount: 2, random: Random(1));
      final challenge = factory.build(buildQuestion());

      expect(challenge.laneCount, 2);
      expect(challenge.options.length, 2);
      expect(
        challenge.options[challenge.correctIndex].id,
        'fael',
      );
      expect(challenge.isCorrectLane(challenge.correctIndex), isTrue);
    });

    test('يرفض سؤالًا لا يكفي عددُ خياراته الخاطئة للمسارات', () {
      final factory = ChallengeFactory(laneCount: 3, random: Random(1));
      expect(() => factory.build(buildQuestion()), throwsStateError);
    });

    test('ترتيبُ المسارات يتبدّل بين التحدّيات فلا يحفظ اللاعبُ الموضع', () {
      final factory = ChallengeFactory(laneCount: 2, random: Random(3));
      final indices = <int>{};
      for (var i = 0; i < 20; i++) {
        indices.add(factory.build(buildQuestion()).correctIndex);
      }
      expect(indices.length, 2, reason: 'يجب أن يظهر الصوابُ في المسارين معًا');
    });
  });

  group('ShuffledQuestionSelector', () {
    test('يستنفد البنكَ قبل أن يعيد سؤالًا', () {
      final questions = List.generate(6, (i) => buildQuestion(id: 'q$i'));
      final selector =
          ShuffledQuestionSelector(questions: questions, random: Random(5));

      final served = List.generate(6, (_) => selector.selectNext().id);
      expect(served.toSet().length, 6);
    });

    test('لا يقدّم السؤالَ نفسَه مرّتين متتاليتين', () {
      final questions = List.generate(4, (i) => buildQuestion(id: 'q$i'));
      final selector =
          ShuffledQuestionSelector(questions: questions, random: Random(11));

      String? previous;
      for (var i = 0; i < 40; i++) {
        final id = selector.selectNext().id;
        expect(id, isNot(previous));
        previous = id;
      }
    });

    test('بنك أسئلة فارغ مرفوض', () {
      expect(
        () => ShuffledQuestionSelector(questions: const []),
        throwsArgumentError,
      );
    });
  });
}
