import 'answer_option.dart';
import 'question.dart';

/// تحدٍّ جاهز للتجسيد في العالم: سؤالٌ + خياراتٌ مرتَّبةٌ ترتيبًا نهائيًّا.
///
/// ترتيبُ الخيارات هنا هو ترتيبُ المسارات في العالم (من الأعلى إلى الأسفل)،
/// وقد رُتِّب عشوائيًّا في طبقة المجال حتى يبقى قابلًا للاختبار،
/// ولا تتكفّل به طبقةُ الرسم.
class Challenge {
  const Challenge({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final Question question;

  /// الخيارات بترتيب المسارات. طولها يساوي عدد المسارات في هذا التحدّي.
  final List<AnswerOption> options;

  /// فهرس المسار الذي يحمل الإجابة الصحيحة.
  final int correctIndex;

  int get laneCount => options.length;

  AnswerOption optionAt(int laneIndex) => options[laneIndex];

  bool isCorrectLane(int laneIndex) => laneIndex == correctIndex;

  @override
  String toString() =>
      'Challenge(${question.id}, lanes: ${options.map((o) => o.label).join(" | ")})';
}
