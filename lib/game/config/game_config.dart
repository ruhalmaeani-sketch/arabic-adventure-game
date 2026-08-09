/// كلّ أرقام ضبط اللعبة في موضعٍ واحد.
///
/// اللعبة تُرسم داخل دقّةٍ افتراضيّةٍ ثابتة ([worldWidth] × [worldHeight])
/// تُحجَّم إلى شاشة الجهاز، فيبقى تخطيط العالم واحدًا على كلّ الهواتف،
/// ويصير حسابُ المواضع قابلًا للاختبار بلا جهاز.
///
/// المسيرُ عموديٌّ من أسفل الشاشة إلى أعلاها في طريقٍ يمتدّ إلى الأفق،
/// والعمقُ مصنوعٌ بإسقاط منظورٍ لا برسمٍ مسطّح. تفصيلُه في [Perspective].
class GameConfig {
  const GameConfig._();

  // ── أبعاد العالم الافتراضيّة (نسبة ٩:١٨) ──
  static const double worldWidth = 432;
  static const double worldHeight = 864;

  // ── الكاميرا والمنظور ──
  /// البعدُ البؤريّ: كلّما صغر اشتدّ المنظورُ وبدا الطريقُ أعمق.
  static const double focalLength = 300;

  /// ارتفاع خطّ الأفق على الشاشة.
  static const double horizonY = 336;

  /// موضعُ نقطة الأرض عند قدمَي الكاميرا؛ تحت حافّة الشاشة عمدًا
  /// ليمتدّ الطريقُ خارجها فيقوى الإحساس بالقرب.
  static const double roadBaseY = 916;

  /// نصفُ عرض الطريق في وحدات العالم عند البعد صفر.
  static const double roadHalfWidth = 178;

  static const double nearClipZ = -120;
  static const double farClipZ = 3200;

  /// البعدُ الذي يبدأ عنده الضبابُ في إذابة الأشياء بلون الأفق.
  static const double hazeStartZ = 700;
  static const double hazeMaxOpacity = 0.92;

  // ── المساران ──
  /// انحرافُ كلّ مسارٍ عن محور الطريق. الأوّلُ يمينًا موافقةً لترتيب القراءة
  /// العربيّة، فيقرأ اللاعبُ الخيارَ الأوّل في الجهة التي تبدأ منها عينُه.
  static const List<double> laneOffsets = [92, -92];
  static int get laneCount => laneOffsets.length;

  /// أقصى انحرافٍ مسموحٍ للاعب خارج أبعد مسار.
  static const double laneOvershoot = 46;

  // ── اللاعب ──
  /// بُعدُ اللاعب الثابت عن الكاميرا؛ عنده تُحسم الإجابة.
  static const double playerZ = 76;
  static const double playerHeight = 104;
  static const double playerFollowSpeed = 11;

  /// شدّة انجذاب اللاعب إلى محور أقرب مسارٍ أثناء التحدّي (٠ = بلا انجذاب).
  static const double laneMagnetism = 3.0;

  // ── سرعة السير (وحدات عالمٍ في الثانية) ──
  static const double cruiseSpeed = 460;
  static const double challengeSpeed = 360;

  /// سرعةُ القراءة: يتمهّل المسافرُ وهو يقرأ اللوحةَ المقبلة.
  static const double readingSpeed = 165;

  /// المسافة التي يبدأ عندها التمهُّلُ للقراءة.
  static const double readingDistance = 900;

  /// سرعةُ السير أثناء عرض التصحيح — يكاد يقف ولا يقف.
  static const double correctionSpeed = 26;
  static const double speedLerpRate = 2.2;

  // ── بنية التحدّي ──
  /// بُعدُ ظهور البوابة أوّلَ مرّة.
  static const double challengeSpawnZ = 2600;

  /// المسافة الفاصلة بين تحدٍّ وآخر.
  static const double gapBetweenChallenges = 1500;

  /// اللوحةُ الحاملة للجملة: كبيرةٌ في وحدات العالم كي تُقرأ من بعيد.
  static const double bannerWidth = 560;
  static const double bannerHeight = 210;
  static const double bannerBaseHeight = 210;
  static const double bannerFontSize = 52;

  /// البابان تحت اللوحة.
  static const double doorWidth = 150;
  static const double doorHeight = 168;
  static const double doorSignFontSize = 40;

  // ── الشعلات ──
  /// كم شعلةً يلزم لتبديل أجواء المرحلة.
  static const int torchesPerAtmosphere = 3;

  /// كم تحدّيًا في المرحلة الواحدة قبل أن ترتفع الصعوبة.
  static const int challengesPerStage = 6;

  // ── التصحيح ──
  /// أقلُّ مدّةٍ قبل قبول لمسة المتابعة، منعًا من إغلاقٍ عرَضيّ باللمسة نفسها
  /// التي كان اللاعب يوجّه بها شخصيّتَه.
  static const double correctionMinDuration = 0.45;
}
