import 'dart:math';

import '../models/question.dart';
import 'question_selector.dart';

/// اختيارٌ يتدرّج في الصعوبة كلّما أتمّ اللاعبُ مرحلة.
///
/// المرحلةُ عددٌ ثابتٌ من التحدّيات. وكلّما انتهت مرحلةٌ ارتفع سقفُ الصعوبة
/// وارتفعت أرضيّتُها معه — فلا يعود اللاعبُ إلى أسهل ما أتقنه، ولا يُقذف
/// فجأةً إلى أصعب ما في البنك.
///
/// وإذا خلا البنكُ من سؤالٍ في المدى المطلوب، اتُّسع المدى بدل أن تتوقّف
/// اللعبة؛ فنقصُ المحتوى لا يجوز أن يكون عطلًا.
class StagedQuestionSelector implements QuestionSelector {
  StagedQuestionSelector({
    required List<Question> questions,
    required this.challengesPerStage,
    Random? random,
  })  : _questions = List.of(questions),
        _random = random ?? Random() {
    if (_questions.isEmpty) {
      throw ArgumentError('لا يمكن إنشاء محرّك اختيار من بنك أسئلة فارغ.');
    }
    if (challengesPerStage < 1) {
      throw ArgumentError('المرحلة لا تقلّ عن تحدٍّ واحد.');
    }
  }

  final List<Question> _questions;
  final Random _random;

  /// كم تحدّيًا في المرحلة الواحدة.
  final int challengesPerStage;

  int _served = 0;
  final List<String> _recentIds = [];

  /// رقمُ المرحلة الحاليّة، يبدأ من واحد.
  int get stage => _served ~/ challengesPerStage + 1;

  /// مدى الصعوبة المسموح في المرحلة الحاليّة.
  ({int min, int max}) get difficultyWindow {
    final max = (stage + 1).clamp(2, 5);
    final min = (stage - 1).clamp(1, 4);
    return (min: min > max ? max : min, max: max);
  }

  @override
  Question selectNext() {
    final window = difficultyWindow;

    var pool = _questions
        .where((q) =>
            q.difficulty >= window.min &&
            q.difficulty <= window.max &&
            !_recentIds.contains(q.id))
        .toList(growable: false);

    // اتّساعٌ متدرّج عند ضيق البنك: أوّلًا نتجاوز حاجزَ التكرار القريب،
    // ثمّ نتجاوز مدى الصعوبة نفسَه.
    if (pool.isEmpty) {
      pool = _questions
          .where((q) =>
              q.difficulty >= window.min && q.difficulty <= window.max)
          .toList(growable: false);
    }
    if (pool.isEmpty) {
      pool = _questions
          .where((q) => !_recentIds.contains(q.id))
          .toList(growable: false);
    }
    if (pool.isEmpty) pool = _questions;

    final question = pool[_random.nextInt(pool.length)];

    _served++;
    _recentIds.add(question.id);
    // نافذةُ منعِ التكرار تتّسع بسعة البنك ولا تبتلعه كلَّه.
    final memory = (_questions.length / 3).floor().clamp(1, 12);
    while (_recentIds.length > memory) {
      _recentIds.removeAt(0);
    }

    return question;
  }

  @override
  void recordResult(Question question, {required bool isCorrect}) {
    // التدرّجُ هنا مبنيٌّ على المراحل. والتكيّفُ مع مهارات اللاعب
    // محرّكٌ مستقلٌّ يأتي لاحقًا، ويحلّ محلَّ هذا الصنف دون تغييرٍ في سواه.
  }
}
