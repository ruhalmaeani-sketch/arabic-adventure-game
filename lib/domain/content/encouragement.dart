import 'dart:math';

/// كلماتُ التشجيع التي ترافق الإجابةَ الصحيحة.
///
/// التنويعُ مقصود: تكرارُ «أحسنت» وحدَها يفقدها معناها بعد عشر مرّات،
/// فتصير ضوضاءَ لا ثناء. والعباراتُ ترتقي مع طول السلسلة، فيشعر اللاعب
/// أنّ اللعبةَ تلاحظ اتّصالَ توفيقه لا مجرّد إصابته.
class Encouragement {
  Encouragement({Random? random}) : _random = random ?? Random();

  final Random _random;
  String? _lastPhrase;

  static const List<String> _plain = [
    'أحسنتَ',
    'إعرابٌ سديد',
    'وُفِّقتَ',
    'هذا هو الطريق',
    'أصبتَ المحزّ',
    'نِعمَ النظر',
    'مضيتَ على بصيرة',
    'قراءةٌ متأنّية',
  ];

  static const List<String> _streak = [
    'ما شاء الله، لا تتوقّف',
    'سلسلةٌ لا تنقطع',
    'الملَكةُ تُبنى هكذا',
    'خطوةً بعد خطوة',
  ];

  static const List<String> _mastery = [
    'صرتَ تُعرِب بلا تردّد',
    'هذه سليقةُ من مارس',
    'أنت في طريق النحاة',
  ];

  /// عبارةٌ مناسبةٌ لطول السلسلة، لا تكرّر سابقتَها مباشرةً.
  String phraseFor({required int streak}) {
    final pool = streak >= 8
        ? _mastery
        : streak >= 3
            ? _streak
            : _plain;

    if (pool.length < 2) return pool.first;

    String candidate;
    do {
      candidate = pool[_random.nextInt(pool.length)];
    } while (candidate == _lastPhrase);

    _lastPhrase = candidate;
    return candidate;
  }
}
