import 'dart:math';

import '../models/question.dart';

/// واجهة اختيار السؤال التالي.
///
/// في النموذج الأوّليّ نستعمل اختيارًا عشوائيًّا غيرَ مكرِّر،
/// وسيحلّ محلَّه لاحقًا `AdaptiveDifficultyEngine` المبنيّ على نموذج المهارات
/// دون أن تتغيّر أيُّ طبقةٍ أخرى — فالعقد واحد.
abstract class QuestionSelector {
  Question selectNext();

  /// إعلامُ المحرّك بنتيجة الإجابة ليبني عليها اختيارَه القادم.
  void recordResult(Question question, {required bool isCorrect});
}

/// اختيارٌ عشوائيّ يستنفد البنكَ كلَّه قبل أن يعيد الكرّة،
/// ولا يسمح بتكرار سؤالٍ مباشرةً بعد نفسه.
class ShuffledQuestionSelector implements QuestionSelector {
  ShuffledQuestionSelector({
    required List<Question> questions,
    Random? random,
  })  : _questions = List.of(questions),
        _random = random ?? Random() {
    if (_questions.isEmpty) {
      throw ArgumentError('لا يمكن إنشاء محرّك اختيار من بنك أسئلة فارغ.');
    }
    _refill();
  }

  final List<Question> _questions;
  final Random _random;
  final List<Question> _bag = [];
  Question? _lastServed;

  @override
  Question selectNext() {
    if (_bag.isEmpty) _refill();

    var question = _bag.removeLast();

    // تفادي تكرار السؤال نفسِه مرّتين متتاليتين عند انقلاب الكيس.
    if (question.id == _lastServed?.id && _bag.isNotEmpty) {
      final replacement = _bag.removeLast();
      _bag.add(question);
      question = replacement;
    }

    _lastServed = question;
    return question;
  }

  @override
  void recordResult(Question question, {required bool isCorrect}) {
    // النموذج الأوّليّ لا يتكيّف بعدُ؛ التكيّف يأتي في مرحلة نموذج المهارات.
  }

  void _refill() {
    _bag
      ..clear()
      ..addAll(_questions)
      ..shuffle(_random);
  }
}
