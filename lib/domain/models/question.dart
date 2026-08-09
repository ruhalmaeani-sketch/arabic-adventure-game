import 'answer_option.dart';

/// نوع التحدّي اللغويّ.
enum QuestionKind {
  /// إعراب كلمة بعينها داخل الجملة.
  irab,

  /// تحديد نوع الجملة كلِّها (اسميّة/فعليّة) — لا كلمة مستهدفة فيه.
  sentenceType;

  static QuestionKind fromId(String id) {
    switch (id) {
      case 'irab':
        return QuestionKind.irab;
      case 'sentence_type':
        return QuestionKind.sentenceType;
      default:
        throw FormatException('نوع سؤال غير معروف: $id');
    }
  }
}

/// حالة المراجعة التربويّة للسؤال.
/// المحرّك لا يقدّم للاعب إلّا ما كان `approved`، حمايةً من تسرّب محتوى غير مراجَع.
enum ReviewStatus {
  draft,
  needsReview,
  approved;

  static ReviewStatus fromId(String id) {
    switch (id) {
      case 'approved':
        return ReviewStatus.approved;
      case 'needs_review':
        return ReviewStatus.needsReview;
      default:
        return ReviewStatus.draft;
    }
  }
}

/// سؤال واحد في بنك الأسئلة.
///
/// النموذج مستقلّ تمامًا عن الواجهة والمحرّك الرسوميّ: هو يصف *المعرفة*،
/// وطريقةُ تجسيدها في العالم (لوحة، بوابة، جسر...) قرارٌ تتّخذه طبقة اللعبة.
class Question {
  const Question({
    required this.id,
    required this.kind,
    required this.sentence,
    required this.targetWordIndex,
    required this.targetWord,
    required this.correctAnswer,
    required this.wrongAnswers,
    required this.grammarTopic,
    required this.level,
    required this.difficulty,
    required this.explanation,
    required this.xp,
    required this.tags,
    required this.sourceType,
    required this.presentationHints,
    required this.reviewStatus,
  });

  final String id;
  final QuestionKind kind;

  /// الجملة العربيّة الفصيحة مشكولةً بالقدر الذي يوضّح ولا يُثقِل.
  final String sentence;

  /// فهرس الكلمة المستهدفة بعد التقسيم على المسافات، أو `-1` إذا لا كلمة مستهدفة.
  final int targetWordIndex;

  /// نصّ الكلمة المستهدفة (للتحقّق والعرض)، أو سلسلة فارغة.
  final String targetWord;

  final AnswerOption correctAnswer;
  final List<AnswerOption> wrongAnswers;

  /// معرّف الموضوع النحويّ الذي يقيسه السؤال — أساسُ نموذج المهارات.
  final String grammarTopic;

  final int level;

  /// صعوبة من ١ إلى ٥.
  final int difficulty;

  /// الشرح الذي يعرضه المعلّم داخل العالم عند الخطأ.
  final String explanation;

  final int xp;
  final List<String> tags;

  /// `original` للجمل التعليميّة الأصليّة، و`classical_cited` لما له مصدر موثَّق.
  final String sourceType;

  /// اقتراحات لكيفيّة تجسيد السؤال في العالم (لوحة خشبيّة، بوابة حجريّة...).
  final List<String> presentationHints;

  final ReviewStatus reviewStatus;

  /// كلمات الجملة مقسَّمةً على المسافات.
  List<String> get words => sentence.split(RegExp(r'\s+'));

  bool get hasTargetWord =>
      kind == QuestionKind.irab && targetWordIndex >= 0;

  /// كلّ الخيارات (الصحيح والخاطئ) دون ترتيب مضمون.
  List<AnswerOption> get allOptions => [correctAnswer, ...wrongAnswers];

  bool isCorrect(AnswerOption option) => option.id == correctAnswer.id;

  factory Question.fromJson(Map<String, dynamic> json) {
    final wrong = (json['wrongAnswers'] as List<dynamic>)
        .map((e) => AnswerOption.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    if (wrong.isEmpty) {
      throw FormatException('السؤال ${json['id']} بلا إجابات خاطئة.');
    }

    final question = Question(
      id: json['id'] as String,
      kind: QuestionKind.fromId(json['kind'] as String),
      sentence: json['sentence'] as String,
      targetWordIndex: json['targetWordIndex'] as int,
      targetWord: json['targetWord'] as String,
      correctAnswer:
          AnswerOption.fromJson(json['correctAnswer'] as Map<String, dynamic>),
      wrongAnswers: wrong,
      grammarTopic: json['grammarTopic'] as String,
      level: json['level'] as int,
      difficulty: json['difficulty'] as int,
      explanation: json['explanation'] as String,
      xp: json['xp'] as int,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      sourceType: json['sourceType'] as String,
      presentationHints:
          (json['presentationHints'] as List<dynamic>).cast<String>(),
      reviewStatus: ReviewStatus.fromId(json['reviewStatus'] as String),
    );

    question._validate();
    return question;
  }

  /// تحقّق بنيويّ يمنع وصولَ سؤالٍ مكسورٍ إلى اللاعب.
  void _validate() {
    if (kind == QuestionKind.irab) {
      if (targetWordIndex < 0 || targetWordIndex >= words.length) {
        throw FormatException(
          'السؤال $id: فهرس الكلمة المستهدفة ($targetWordIndex) خارج حدود الجملة.',
        );
      }
      if (words[targetWordIndex] != targetWord) {
        throw FormatException(
          'السؤال $id: الكلمة المستهدفة «$targetWord» لا تطابق '
          'كلمة الجملة «${words[targetWordIndex]}» عند الفهرس $targetWordIndex.',
        );
      }
    }
    if (difficulty < 1 || difficulty > 5) {
      throw FormatException('السؤال $id: الصعوبة يجب أن تكون بين ١ و٥.');
    }
    for (final option in wrongAnswers) {
      if (option.id == correctAnswer.id) {
        throw FormatException(
          'السؤال $id: خيار خاطئ يحمل معرّف الإجابة الصحيحة (${option.id}).',
        );
      }
    }
  }

  @override
  String toString() => 'Question($id, $grammarTopic, d$difficulty)';
}
