import 'answer_option.dart';
import 'question.dart';

/// نتيجة اختيارِ اللاعبِ طريقًا — لا نتيجةَ ضغطِه زرًّا.
class AnswerResult {
  const AnswerResult({
    required this.question,
    required this.chosen,
    required this.chosenLaneIndex,
    required this.isCorrect,
    required this.xpAwarded,
    required this.streakAfter,
    required this.coinsAwarded,
  });

  final Question question;
  final AnswerOption chosen;
  final int chosenLaneIndex;
  final bool isCorrect;

  /// الخبرة الممنوحة شاملةً مكافأةَ السلسلة.
  final int xpAwarded;

  /// طول سلسلة الإجابات الصحيحة بعد هذه الإجابة (يعود إلى صفر عند الخطأ).
  final int streakAfter;

  final int coinsAwarded;

  /// الشرح الذي يعرضه المعلّم في العالم عند الخطأ.
  String get explanation => question.explanation;

  /// سببُ الوقوع في هذا الخطأ بعينه، إن كان مسجَّلًا.
  String? get misconception => isCorrect ? null : chosen.misconception;

  /// كلمةُ المعلّم على اللافتة عند الخطأ: سؤالٌ يستنطق الفكرَ أو تعليلٌ لطيف.
  ///
  /// إن لم يُكتب للخيار نصٌّ خاصّ، رجعنا إلى شرح السؤال؛ فلا يُترك المتعلّم
  /// بلا بيانٍ في حال.
  String get nudge =>
      chosen.nudge ?? chosen.misconception ?? question.explanation;

  @override
  String toString() =>
      'AnswerResult(${question.id}, ${isCorrect ? "صحيح" : "خطأ"}, +$xpAwarded)';
}
