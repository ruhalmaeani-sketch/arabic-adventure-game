import 'package:flutter/material.dart';

/// أدوات رسم النصّ العربيّ داخل لوحة اللعبة.
///
/// كلُّ نصٍّ يمرّ عبر [TextPainter] بمحاذاةٍ من اليمين إلى اليسار،
/// فيصل الحروفُ ويُضبط التشكيلُ ويُرتَّب النصُّ ثنائيُّ الاتّجاه ترتيبًا صحيحًا.
/// هذا هو السببُ الأوّل لاختيار هذه التقنية، فلا يجوز الالتفاف عليه
/// برسم الحروف يدويًّا.
class ArabicText {
  const ArabicText._();

  static const String fontFamily = 'Amiri';
  static const String uiFontFamily = 'Cairo';

  /// خطٌّ احتياطيٌّ للرموز التعبيريّة؛ خطوطُ النصّ العربيّ لا تحمل رسومَها،
  /// وبدونه تظهر مربّعاتٍ فارغة.
  static const List<String> _fallback = ['NotoEmoji'];

  /// يبني رسّامَ نصٍّ عربيٍّ جاهزًا للقياس والرسم.
  static TextPainter painter(
    String text, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
    double maxWidth = double.infinity,
    TextAlign align = TextAlign.center,
    double height = 1.5,
    List<Shadow>? shadows,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: _fallback,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: height,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: align,
    )..layout(maxWidth: maxWidth);
    return painter;
  }

  /// يبني رسّامًا لجملةٍ أُبرزت فيها كلمةٌ واحدة.
  ///
  /// الإبرازُ يقع على الكلمة بوصفها مقطعًا مستقلًّا في [TextSpan]،
  /// فلا ينكسر وصلُ الحروف ولا يضيع التشكيل — بخلاف تقطيع النصّ يدويًّا.
  static TextPainter highlightedSentence(
    String sentence, {
    required int targetWordIndex,
    required double fontSize,
    required Color baseColor,
    required Color highlightColor,
    double maxWidth = double.infinity,
    double height = 1.6,
  }) {
    final words = sentence.split(RegExp(r'\s+'));
    final baseStyle = TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: _fallback,
      fontSize: fontSize,
      color: baseColor,
      height: height,
    );
    final highlightStyle = baseStyle.copyWith(
      color: highlightColor,
      fontWeight: FontWeight.w700,
      shadows: [
        Shadow(color: highlightColor.withValues(alpha: 0.45), blurRadius: 10),
      ],
    );

    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      spans.add(
        TextSpan(
          text: words[i],
          style: i == targetWordIndex ? highlightStyle : baseStyle,
        ),
      );
      if (i != words.length - 1) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }
    }

    return TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
  }

  /// يرسم النصَّ متمركزًا حول [center].
  static void paintCentered(Canvas canvas, TextPainter painter, Offset center) {
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }
}
