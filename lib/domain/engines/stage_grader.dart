/// حَكَمُ المرحلة: قاعدةٌ واحدةٌ بسيطة، معزولةٌ ليسهل اختبارُها ويصعب كسرُها
/// عرَضًا أثناء تعديل منطق اللعبة الأكبر.
class StageGrader {
  const StageGrader._();

  static bool passed({required int correct, required int passScore}) =>
      correct >= passScore;
}
