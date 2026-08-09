import 'package:flutter/material.dart';

/// لوحة ألوان «رحلة العربية»: ورقٌ قديم، وحبرٌ، وحجرٌ، وخشبٌ، وضوءٌ دافئ.
///
/// هذه ألوانٌ مؤقّتةٌ للنموذج الأوّليّ، وهي معزولةٌ هنا
/// حتى تُستبدل الهويّةُ البصريّةُ النهائيّةُ لاحقًا من ملفٍّ واحد.
class AppPalette {
  const AppPalette._();

  // الحبر والورق
  static const Color ink = Color(0xFF2A1F14);
  static const Color inkSoft = Color(0xFF5B4632);
  static const Color parchment = Color(0xFFF3E4C4);
  static const Color parchmentDark = Color(0xFFE0CBA1);

  // الخشب
  static const Color wood = Color(0xFF8B5E3C);
  static const Color woodDark = Color(0xFF5E3B23);

  // الحجر
  static const Color stone = Color(0xFFBFA88A);
  static const Color stoneDark = Color(0xFF8C775C);

  // السماء والأرض
  static const Color skyTop = Color(0xFF2E4A6B);
  static const Color skyBottom = Color(0xFFE8A65C);
  static const Color hillsFar = Color(0xFF6E6A82);
  static const Color hillsNear = Color(0xFF4E4257);
  static const Color roadTop = Color(0xFFC9A874);
  static const Color roadBottom = Color(0xFF9A7B4F);
  static const Color roadEdge = Color(0xFF7A5E3A);

  // الدلالات
  static const Color gold = Color(0xFFE8B54A);
  static const Color success = Color(0xFF6FA36B);
  static const Color failure = Color(0xFFB4694E);

  // الشخصية
  static const Color robe = Color(0xFFF2EDE3);
  static const Color robeShade = Color(0xFFD8CFBE);
  static const Color sash = Color(0xFF3E6B62);
  static const Color skin = Color(0xFFC79A6B);
}
