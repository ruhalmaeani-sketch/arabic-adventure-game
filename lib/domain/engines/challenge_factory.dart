import 'dart:math';

import '../models/answer_option.dart';
import '../models/challenge.dart';
import '../models/question.dart';

/// يحوّل السؤالَ إلى تحدٍّ ذي مسارات.
///
/// عددُ المسارات معطًى للمصنع لا ثابتٌ في الكود: النسخة الأولى تلتزم بمسارين،
/// وزيادةُ العدد لاحقًا لا تحتاج إلّا تغييرَ قيمةٍ واحدةٍ في الإعدادات.
class ChallengeFactory {
  ChallengeFactory({required this.laneCount, Random? random})
      : _random = random ?? Random() {
    if (laneCount < 2) {
      throw ArgumentError('التحدّي يحتاج مسارين على الأقلّ.');
    }
  }

  final int laneCount;
  final Random _random;

  Challenge build(Question question) {
    final wrongNeeded = laneCount - 1;
    final available = List<AnswerOption>.of(question.wrongAnswers);

    if (available.length < wrongNeeded) {
      throw StateError(
        'السؤال ${question.id} يملك ${available.length} إجابةً خاطئة، '
        'والمطلوب $wrongNeeded لتغطية $laneCount مسارات.',
      );
    }

    available.shuffle(_random);
    final options = <AnswerOption>[
      question.correctAnswer,
      ...available.take(wrongNeeded),
    ]..shuffle(_random);

    return Challenge(
      question: question,
      options: List.unmodifiable(options),
      correctIndex: options.indexWhere((o) => o.id == question.correctAnswer.id),
    );
  }
}
