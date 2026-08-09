import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rihlat_alarabiyya/data/repositories/asset_question_repository.dart';
import 'package:rihlat_alarabiyya/domain/models/question.dart';

/// حارسُ المحتوى.
///
/// بنك الأسئلة يكبر بمرور الوقت، وخطأٌ واحدٌ فيه يعلّم المتعلّم خطأً.
/// هذه الاختبارات تسري على الملفّ الحقيقيّ المرفق بالتطبيق، لا على بياناتٍ صوريّة.
void main() {
  late List<Question> questions;

  setUpAll(() {
    final file = File('assets/content/questions/level_1.json');
    expect(file.existsSync(), isTrue, reason: 'ملفّ المستوى الأوّل مفقود');
    questions = AssetQuestionRepository.parseLevel(file.readAsStringSync());
  });

  test('المستوى الأوّل يحتوي ثلاثين سؤالًا معتمدًا', () {
    expect(questions.length, 30);
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

  test('التغطية النحوية تشمل موضوعات المستوى الأوّل', () {
    final topics = questions.map((q) => q.grammarTopic).toSet();
    expect(
      topics,
      containsAll(<String>[
        'fael',
        'mafool_bih',
        'mubtada',
        'khabar',
        'naat',
        'jar_majroor',
        'dharf',
        'atf',
      ]),
    );
  });

  test('الصعوبة داخل المدى المسموح', () {
    for (final question in questions) {
      expect(question.difficulty, inInclusiveRange(1, 5));
      expect(question.level, 1);
      expect(question.xp, greaterThan(0));
    }
  });
}
