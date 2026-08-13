/// تعريفُ مرحلةٍ من مراحل الرحلة: منهجُها، وعددُ بوّاباتها، ونصابُ نجاحها.
///
/// كلّ مرحلةٍ ملفُّ أسئلةٍ مستقلٌّ (`level_<index>.json`)، فالمنهجُ محتوًى
/// لا كود؛ إضافةُ مرحلةٍ سادسةٍ يومًا ما تعديلُ [StageCatalog.all] وملفٍّ جديد،
/// لا لمسَ منطقِ اللعبة.
class StageDefinition {
  const StageDefinition({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.gatesPerStage,
    required this.passScore,
  });

  /// رقمُ المرحلة من ١، وهو نفسُه رقمُ ملفّ الأسئلة `level_<index>.json`.
  final int index;

  final String title;
  final String subtitle;

  /// كم بوّابةً يواجهها اللاعب في هذه المرحلة.
  final int gatesPerStage;

  /// أقلُّ عددِ إجاباتٍ صحيحةٍ للفوز بالمرحلة.
  final int passScore;
}

/// فهرسُ المراحل الخمس ومنهجُ كلٍّ منها.
class StageCatalog {
  const StageCatalog._();

  static const List<StageDefinition> all = [
    StageDefinition(
      index: 1,
      title: 'أقسامُ الكلام',
      subtitle: 'اسمٌ، وفعلٌ، وحرفٌ، وعلاماتُ كلٍّ منها',
      gatesPerStage: 20,
      passScore: 15,
    ),
    StageDefinition(
      index: 2,
      title: 'المرفوعات',
      subtitle: 'الفاعل، ونائبُ الفاعل، والمبتدأ، والخبر',
      gatesPerStage: 20,
      passScore: 15,
    ),
    StageDefinition(
      index: 3,
      title: 'المنصوبات',
      subtitle: 'المفعولُ به، والمطلقُ، ولأجله، والظرفان، والحال',
      gatesPerStage: 20,
      passScore: 15,
    ),
    StageDefinition(
      index: 4,
      title: 'الجملتان',
      subtitle: 'الجملةُ الاسميّةُ والجملةُ الفعليّة',
      gatesPerStage: 20,
      passScore: 15,
    ),
    StageDefinition(
      index: 5,
      title: 'التوابع',
      subtitle: 'النعتُ، والبدلُ، والتوكيدُ، والعطف',
      gatesPerStage: 20,
      passScore: 15,
    ),
  ];

  static int get count => all.length;

  static bool hasStage(int index) => index >= 1 && index <= count;

  static StageDefinition byIndex(int index) {
    if (!hasStage(index)) {
      throw RangeError.value(index, 'index', 'لا مرحلة بهذا الرقم');
    }
    return all[index - 1];
  }
}
