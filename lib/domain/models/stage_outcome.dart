/// نتيجةُ مرحلةٍ اكتملت بوّاباتُها العشرون: أصاب اللاعبُ نصابَ النجاح أم لا.
class StageOutcome {
  const StageOutcome({
    required this.stageIndex,
    required this.correct,
    required this.total,
    required this.passScore,
  });

  final int stageIndex;
  final int correct;
  final int total;
  final int passScore;

  bool get passed => correct >= passScore;

  @override
  String toString() =>
      'StageOutcome(stage: $stageIndex, $correct/$total, '
      '${passed ? "فاز" : "خسر"})';
}
