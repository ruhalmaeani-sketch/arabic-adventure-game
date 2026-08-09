/// قواعد المكافأة في مكانٍ واحد، حتى يكون ضبطُ توازن اللعبة تعديلَ أرقامٍ
/// لا مطاردةَ ثوابتَ متفرّقةٍ في الكود.
class RewardRules {
  const RewardRules({
    this.streakBonusStep = 2,
    this.maxStreakBonus = 10,
    this.coinsPerCorrect = 2,
    this.streakCoinMilestone = 5,
    this.milestoneCoins = 10,
  });

  /// خبرة إضافيّة عن كلّ إجابةٍ صحيحةٍ بعد الأولى في السلسلة.
  final int streakBonusStep;

  /// سقف مكافأة السلسلة، منعًا لانفلات الاقتصاد.
  final int maxStreakBonus;

  final int coinsPerCorrect;

  /// كلّ كم إجابةٍ صحيحةٍ متتاليةٍ تُمنح مكافأةُ الدنانير الكبرى.
  final int streakCoinMilestone;

  final int milestoneCoins;

  /// الخبرة الممنوحة عن إجابةٍ صحيحةٍ، مع مراعاة طول السلسلة *بعد* هذه الإجابة.
  int xpFor({required int baseXp, required int streakAfter}) {
    final bonus =
        ((streakAfter - 1) * streakBonusStep).clamp(0, maxStreakBonus);
    return baseXp + bonus;
  }

  int coinsFor({required int streakAfter}) {
    var coins = coinsPerCorrect;
    if (streakAfter > 0 && streakAfter % streakCoinMilestone == 0) {
      coins += milestoneCoins;
    }
    return coins;
  }
}
