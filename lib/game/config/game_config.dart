/// كلّ أرقام ضبط اللعبة في موضعٍ واحد.
///
/// اللعبة تُرسم داخل دقّةٍ افتراضيّةٍ ثابتة ([worldWidth] × [worldHeight])
/// تُحجَّم إلى شاشة الجهاز، فيبقى تخطيط العالم واحدًا على كلّ الهواتف،
/// ويصير حسابُ المواضع قابلًا للاختبار بلا جهاز.
class GameConfig {
  const GameConfig._();

  // ── أبعاد العالم الافتراضيّة (نسبة ٩:١٨) ──
  static const double worldWidth = 432;
  static const double worldHeight = 864;

  // ── الأرض والسماء ──
  static const double horizonY = 430;
  static const double roadTopY = 468;
  static const double roadBottomY = 838;

  // ── المساران ──
  /// النسخة الأولى تلتزم بمسارين، والنظام يقبل الزيادة بتعديل هذه القائمة فقط.
  static const List<double> laneCenters = [542, 712];
  static int get laneCount => laneCenters.length;

  /// أقصى انحراف مسموح للاعب فوق أعلى مسارٍ وتحت أدناه.
  static const double laneOvershoot = 34;

  // ── اللاعب ──
  /// اللاعب يقف في الثلث الأيمن؛ فالعالم يأتيه من اليسار موافقةً لاتّجاه القراءة.
  static const double playerX = 324;
  static const double playerHeight = 96;
  static const double playerFollowSpeed = 12;

  /// شدّة انجذاب اللاعب إلى مركز أقرب مسارٍ أثناء التحدّي (٠ = بلا انجذاب).
  static const double laneMagnetism = 3.2;

  // ── سرعة العالم ──
  static const double cruiseSpeed = 132;
  static const double challengeSpeed = 105;

  /// سرعةُ القراءة: يبطئ المسافرُ من نفسه وهو يقرأ اللوحةَ المقبلة.
  static const double readingSpeed = 46;

  /// المسافة التي يبدأ عندها التمهُّلُ للقراءة.
  static const double readingDistance = 330;

  /// سرعة العالم أثناء عرض التصحيح — يكاد يتوقّف ولا يتوقّف تمامًا.
  static const double correctionSpeed = 14;
  static const double speedLerpRate = 2.4;

  // ── بنية التحدّي (إحداثيّات محلّيّة داخل المقطع، الأكبر يُلاقيه اللاعب أوّلًا) ──
  static const double challengeWidth = 380;

  /// مستوى أبواب البوابة: عنده تُسجَّل الإجابة.
  static const double gatePlaneX = 150;

  /// رأس الإسفين الذي ينقسم عنده الطريق.
  static const double forkTipX = 330;

  static const double lintelCenterY = 288;
  static const double lintelWidth = 300;
  static const double lintelHeight = 144;

  static const double doorWidth = 126;
  static const double doorHeight = 104;

  /// مقدارُ نزول قاعدة الباب تحت خطّ المشي، ليبدو المسافرُ داخلَ الباب.
  static const double doorBaseOffset = 12;

  /// لافتةُ الإعراب فوق قوس الباب، حتى لا تحجبها الشخصيةُ لحظةَ العبور.
  static const double doorSignWidth = 128;
  static const double doorSignHeight = 34;
  static const double doorSignGap = 14;

  // ── إيقاع التوليد ──
  /// المسافة الفاصلة بين نهاية تحدٍّ وبداية الذي يليه.
  static const double gapBetweenChallenges = 420;

  /// مدّة بقاء لوحة التصحيح قبل أن تنزوي وحدها.
  static const double correctionDuration = 4.2;

  /// أقلّ مدّةٍ تُعرض فيها لوحة التصحيح قبل قبول اللمس لتخطّيها.
  static const double correctionMinDuration = 0.6;
}
