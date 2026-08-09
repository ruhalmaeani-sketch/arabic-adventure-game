import '../models/answer_result.dart';
import '../models/challenge.dart';
import '../models/player_level.dart';
import 'challenge_factory.dart';
import 'question_selector.dart';
import 'reward_rules.dart';

/// حصيلة الجلسة الجارية.
class SessionStats {
  const SessionStats({
    this.xp = 0,
    this.coins = 0,
    this.answered = 0,
    this.correct = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  final int xp;
  final int coins;
  final int answered;
  final int correct;
  final int currentStreak;
  final int bestStreak;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  PlayerLevel get level => LevelSystem.levelForXp(xp);

  double get levelProgress => LevelSystem.progressToNext(xp);

  SessionStats copyWith({
    int? xp,
    int? coins,
    int? answered,
    int? correct,
    int? currentStreak,
    int? bestStreak,
  }) {
    return SessionStats(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      answered: answered ?? this.answered,
      correct: correct ?? this.correct,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }
}

/// قلبُ اللعبة المنطقيّ: يقدّم التحدّي، ويستقبل المسارَ الذي دخَله اللاعب،
/// ويُخرج نتيجةً كاملة.
///
/// هذا الصنف لا يعرف شيئًا عن الرسم ولا اللمس ولا Flutter؛
/// كلّ ما يعرفه أنَّ اللاعب «دخَل المسار رقم كذا».
class SessionEngine {
  SessionEngine({
    required QuestionSelector selector,
    required ChallengeFactory challengeFactory,
    RewardRules rewardRules = const RewardRules(),
  })  // المعاملات معلَنةٌ في الواجهة العامّة والحقول خاصّة، فالفصل بينهما مقصود.
      // ignore: prefer_initializing_formals
      : _selector = selector,
        // ignore: prefer_initializing_formals
        _challengeFactory = challengeFactory,
        // ignore: prefer_initializing_formals
        _rewardRules = rewardRules;

  final QuestionSelector _selector;
  final ChallengeFactory _challengeFactory;
  final RewardRules _rewardRules;

  SessionStats _stats = const SessionStats();
  Challenge? _current;

  SessionStats get stats => _stats;

  /// التحدّي المعروض حاليًّا، أو `null` إن لم يُطلب بعد.
  Challenge? get currentChallenge => _current;

  /// يُنشئ التحدّي التالي ويجعله الجاري.
  Challenge nextChallenge() {
    final question = _selector.selectNext();
    final challenge = _challengeFactory.build(question);
    _current = challenge;
    return challenge;
  }

  /// يُلغي التحدّي الجاري دون احتسابه للاعب ولا عليه.
  ///
  /// يُستعمل حين يمرّ المسافرُ بالبوابة منطلقًا: تجاوَزها ولم يُجب، فلا يصحّ
  /// أن تُحسب له إصابةً ولا عليه خطأً، ولا أن تنكسر سلسلتُه.
  void skipCurrent() => _current = null;

  /// يسجّل دخولَ اللاعب مسارًا بعينه، ويُرجع نتيجةَ ذلك.
  ///
  /// يرمي [StateError] إن استُدعي بلا تحدٍّ جارٍ — وهو خطأ برمجيّ لا حالةَ لعب.
  AnswerResult submitLane(int laneIndex) {
    final challenge = _current;
    if (challenge == null) {
      throw StateError('لا يوجد تحدٍّ جارٍ لتسجيل إجابةٍ عليه.');
    }
    if (laneIndex < 0 || laneIndex >= challenge.laneCount) {
      throw RangeError.index(laneIndex, challenge.options, 'laneIndex');
    }

    final chosen = challenge.optionAt(laneIndex);
    final isCorrect = challenge.isCorrectLane(laneIndex);

    final streakAfter = isCorrect ? _stats.currentStreak + 1 : 0;
    final xpAwarded = isCorrect
        ? _rewardRules.xpFor(
            baseXp: challenge.question.xp,
            streakAfter: streakAfter,
          )
        : 0;
    final coinsAwarded =
        isCorrect ? _rewardRules.coinsFor(streakAfter: streakAfter) : 0;

    _stats = _stats.copyWith(
      xp: _stats.xp + xpAwarded,
      coins: _stats.coins + coinsAwarded,
      answered: _stats.answered + 1,
      correct: _stats.correct + (isCorrect ? 1 : 0),
      currentStreak: streakAfter,
      bestStreak:
          streakAfter > _stats.bestStreak ? streakAfter : _stats.bestStreak,
    );

    _selector.recordResult(challenge.question, isCorrect: isCorrect);
    _current = null;

    return AnswerResult(
      question: challenge.question,
      chosen: chosen,
      chosenLaneIndex: laneIndex,
      isCorrect: isCorrect,
      xpAwarded: xpAwarded,
      streakAfter: streakAfter,
      coinsAwarded: coinsAwarded,
    );
  }
}
