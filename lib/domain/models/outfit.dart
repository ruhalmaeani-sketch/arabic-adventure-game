/// هيئةُ اللاعب: ثوبُه وعمامتُه وما يحمله.
///
/// الأزياءُ لا تُشترى بعملة؛ تُفتح بجمع الكتب أو باجتياز مراحل المنهج،
/// فيكون تغيّرُ هيئةِ المسافر أثرًا لِما حصّله من علمٍ لا لِما أنفقه من مال.
class Outfit {
  const Outfit({
    required this.id,
    required this.title,
    required this.robe,
    required this.robeShade,
    required this.sash,
    required this.turban,
    required this.turbanAccent,
    required this.booksRequired,
    this.hasCloak = false,
    this.carriesBook = false,
  });

  final String id;
  final String title;

  /// ألوانُ الزيّ بصيغة ARGB.
  final int robe;
  final int robeShade;
  final int sash;

  /// لونا العمامة: أساسُ لفّها، ولونُ شريط لفّاتها الثاني.
  final int turban;
  final int turbanAccent;

  /// كم كتابًا يلزم لفتحه.
  final int booksRequired;

  /// بِشتٌ يعلو الثوب.
  final bool hasCloak;

  /// كتابٌ يحمله المسافرُ تحت إبطه.
  final bool carriesBook;

  static const Outfit student = Outfit(
    id: 'student',
    title: 'طالبُ علم',
    robe: 0xFFF2EDE3,
    robeShade: 0xFFD8CFBE,
    sash: 0xFF3E6B62,
    turban: 0xFF3E6B62,
    turbanAccent: 0xFFF7F3E6,
    booksRequired: 0,
  );

  static const Outfit grammarian = Outfit(
    id: 'grammarian',
    title: 'النحويُّ الناشئ',
    robe: 0xFFE7EDE4,
    robeShade: 0xFFBFCCC0,
    sash: 0xFF2F5D3F,
    turban: 0xFFF7F3E6,
    turbanAccent: 0xFF2F5D3F,
    booksRequired: 3,
    carriesBook: true,
  );

  static const Outfit litterateur = Outfit(
    id: 'litterateur',
    title: 'الأديب',
    robe: 0xFFDCE4F2,
    robeShade: 0xFFB4C0D8,
    sash: 0xFF2C3E66,
    turban: 0xFF2C3E66,
    turbanAccent: 0xFFC9A227,
    booksRequired: 7,
    hasCloak: true,
    carriesBook: true,
  );

  static const Outfit poet = Outfit(
    id: 'poet',
    title: 'الشاعر',
    robe: 0xFFF3E2DA,
    robeShade: 0xFFD8B7A8,
    sash: 0xFF8E2F3F,
    turban: 0xFF8E2F3F,
    turbanAccent: 0xFFF3E2DA,
    booksRequired: 12,
    hasCloak: true,
  );

  static const Outfit sheikh = Outfit(
    id: 'sheikh',
    title: 'شيخُ الرِّواق',
    robe: 0xFF3A3630,
    robeShade: 0xFF272420,
    sash: 0xFFC9A227,
    turban: 0xFFF7F3E6,
    turbanAccent: 0xFFC9A227,
    booksRequired: 18,
    hasCloak: true,
    carriesBook: true,
  );

  /// الأزياءُ مرتَّبةً بحسب ما تتطلّبه من كتب، وهي ترتيبُ مراحل المنهج نفسُه.
  static const List<Outfit> all = [
    student,
    grammarian,
    litterateur,
    poet,
    sheikh,
  ];

  /// أرقى زيٍّ استحقّه اللاعب بعدد كتبه.
  static Outfit forBooks(int books) {
    var current = all.first;
    for (final outfit in all) {
      if (books >= outfit.booksRequired) current = outfit;
    }
    return current;
  }

  /// الزيُّ التالي، أو `null` إن بلَغ آخرَها.
  static Outfit? nextAfter(int books) {
    for (final outfit in all) {
      if (outfit.booksRequired > books) return outfit;
    }
    return null;
  }

  /// كم كتابًا بقي حتى الزيّ التالي.
  static int booksToNext(int books) {
    final next = nextAfter(books);
    return next == null ? 0 : next.booksRequired - books;
  }
}
