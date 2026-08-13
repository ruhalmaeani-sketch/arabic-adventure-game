import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rihlat_alarabiyya/data/repositories/asset_question_repository.dart';
import 'package:rihlat_alarabiyya/domain/models/question.dart';
import 'package:rihlat_alarabiyya/domain/models/stage_definition.dart';

/// حارسُ المحتوى.
///
/// بنك الأسئلة يكبر بمرور الوقت، وخطأٌ واحدٌ فيه يعلّم المتعلّم خطأً.
/// هذه الاختبارات تسري على ملفّات المراحل الخمسة الحقيقيّة المرفقة
/// بالتطبيق، لا على بياناتٍ صوريّة، وتتكرّر على كلّ ملفٍّ منها.
void main() {
  /// موضوعاتُ كلّ مرحلةٍ — الحدُّ الأدنى الذي يجب أن يغطّيه ملفُّها.
  const expectedTopics = <int, List<String>>{
    1: ['ism', 'fil', 'harf'],
    2: ['fael', 'naib_fael', 'mubtada', 'khabar'],
    3: ['mafool_bih', 'mafool_mutlaq', 'mafool_liajlih', 'dharf', 'hal'],
    4: ['jumla_ismiyya', 'jumla_filiyya'],
    5: ['naat', 'badal', 'tawkid', 'atf'],
  };

  for (final stage in StageCatalog.all) {
    group('المستوى ${stage.index} — ${stage.title}', () {
      late List<Question> questions;

      setUpAll(() {
        final file = File('assets/content/questions/level_${stage.index}.json');
        expect(file.existsSync(), isTrue,
            reason: 'ملفّ المستوى ${stage.index} مفقود');
        questions = AssetQuestionRepository.parseLevel(file.readAsStringSync());
      });

      test('يحتوي على بوّابات المرحلة كلّها معتمدةً', () {
        expect(questions.length, stage.gatesPerStage);
        expect(
          questions.every((q) => q.reviewStatus == ReviewStatus.approved),
          isTrue,
        );
      });

      test('لا معرّفات مكرّرة', () {
        final ids = questions.map((q) => q.id).toSet();
        expect(ids.length, questions.length);
      });

      test('كلّ سؤال يصلح لمسارين على الأقلّ', () {
        for (final question in questions) {
          expect(
            question.wrongAnswers.length,
            greaterThanOrEqualTo(1),
            reason: 'السؤال ${question.id} لا يملك بديلًا خاطئًا',
          );
        }
      });

      test('الكلمة المستهدفة موجودة فعلًا في الجملة عند أسئلة الإعراب', () {
        for (final question in questions.where((q) => q.hasTargetWord)) {
          expect(
            question.words[question.targetWordIndex],
            question.targetWord,
            reason: 'السؤال ${question.id}: الكلمة المستهدفة لا تطابق موضعها',
          );
        }
      });

      test('كلّ سؤال يحمل شرحًا كافيًا لا مجرّد كلمة', () {
        for (final question in questions) {
          expect(
            question.explanation.trim().length,
            greaterThan(24),
            reason: 'السؤال ${question.id}: الشرح أقصر من أن يفيد',
          );
        }
      });

      test('كلّ إجابة خاطئة تحمل كلمةَ المعلّم على اللافتة', () {
        for (final question in questions) {
          for (final wrong in question.wrongAnswers) {
            expect(
              wrong.nudge,
              isNotNull,
              reason:
                  'السؤال ${question.id}: الخيار ${wrong.id} بلا كلمةٍ استنطاقيّة',
            );
            expect(
              wrong.nudge!.trim().length,
              greaterThan(20),
              reason: 'السؤال ${question.id}: كلمةُ اللافتة أقصرُ من أن تُفيد',
            );
          }
        }
      });

      test('كلّ إجابة خاطئة تُفسِّر سببَ الالتباس', () {
        for (final question in questions) {
          for (final wrong in question.wrongAnswers) {
            expect(
              wrong.misconception,
              isNotNull,
              reason: 'السؤال ${question.id}: الخيار ${wrong.id} بلا تعليل',
            );
          }
        }
      });

      test('الجمل مشكولةٌ لا مهملة', () {
        final harakat = RegExp('[ً-ْ]');
        for (final question in questions) {
          expect(
            harakat.hasMatch(question.sentence),
            isTrue,
            reason: 'السؤال ${question.id}: الجملة بلا ضبطٍ بالشكل',
          );
        }
      });

      test('كلّ نصٍّ منسوبٍ يحتاج توثيقًا؛ والنسخة الأولى جملٌ أصليّة', () {
        for (final question in questions) {
          expect(
            question.sourceType,
            'original',
            reason: 'السؤال ${question.id}: نصٌّ منسوبٌ بلا مصدرٍ موثَّق',
          );
        }
      });

      test('التغطية النحوية تشمل موضوعات هذه المرحلة', () {
        final topics = questions.map((q) => q.grammarTopic).toSet();
        expect(topics, containsAll(expectedTopics[stage.index]!));
      });

      test('الصعوبة داخل المدى المسموح، والمستوى مطابقٌ لرقم الملفّ', () {
        for (final question in questions) {
          expect(question.difficulty, inInclusiveRange(1, 5));
          expect(question.level, stage.index);
          expect(question.xp, greaterThan(0));
        }
      });
    });
  }

  test('لا سؤال يتكرّر معرّفُه بين مرحلةٍ وأخرى', () {
    final allIds = <String>{};
    for (final stage in StageCatalog.all) {
      final file = File('assets/content/questions/level_${stage.index}.json');
      final questions = AssetQuestionRepository.parseLevel(file.readAsStringSync());
      for (final q in questions) {
        expect(
          allIds.add(q.id),
          isTrue,
          reason: 'معرّفٌ مكرّرٌ عبر المراحل: ${q.id}',
        );
      }
    }
  });
}
