/// مراتب اللاعب في طلب العربيّة. الأسماء قابلة للتعديل، والعتبات قابلة للضبط.
class PlayerLevel {
  const PlayerLevel({
    required this.index,
    required this.title,
    required this.requiredXp,
  });

  final int index;
  final String title;

  /// مجموع الخبرة اللازم لبلوغ هذه المرتبة.
  final int requiredXp;
}

/// نظام المستويات: تحويلُ الخبرة إلى مرتبةٍ علميّة.
class LevelSystem {
  const LevelSystem._();

  static const List<PlayerLevel> levels = [
    PlayerLevel(index: 1, title: 'طالب اللغة', requiredXp: 0),
    PlayerLevel(index: 2, title: 'محبّ العربيّة', requiredXp: 120),
    PlayerLevel(index: 3, title: 'طالب النحو', requiredXp: 320),
    PlayerLevel(index: 4, title: 'النحويّ الناشئ', requiredXp: 640),
    PlayerLevel(index: 5, title: 'صاحب الملَكة', requiredXp: 1100),
    PlayerLevel(index: 6, title: 'النحويّ المتمكّن', requiredXp: 1800),
  ];

  static PlayerLevel levelForXp(int xp) {
    var current = levels.first;
    for (final level in levels) {
      if (xp >= level.requiredXp) {
        current = level;
      } else {
        break;
      }
    }
    return current;
  }

  /// المرتبة التالية، أو `null` إذا بلَغ اللاعب أعلى المراتب المعرَّفة.
  static PlayerLevel? nextLevel(int xp) {
    final current = levelForXp(xp);
    final nextIndex = current.index; // المراتب مرقَّمة من ١، والقائمة من ٠
    if (nextIndex >= levels.length) return null;
    return levels[nextIndex];
  }

  /// نسبة التقدّم نحو المرتبة التالية، من ٠ إلى ١.
  static double progressToNext(int xp) {
    final current = levelForXp(xp);
    final next = nextLevel(xp);
    if (next == null) return 1;
    final span = next.requiredXp - current.requiredXp;
    if (span <= 0) return 1;
    return ((xp - current.requiredXp) / span).clamp(0.0, 1.0);
  }
}
