import 'package:flutter/material.dart';

/// أجواءُ المرحلة: لوحةُ ألوانٍ كاملةٌ للسماء والأرض والطريق والمدينة.
///
/// الشعلاتُ التي يجمعها اللاعبُ ليست عملةً زائدة؛ بها يبدّل جوَّ الرحلة،
/// فيكسر رتابةَ المشهد بيده لا بانتظار مرحلةٍ جديدة.
@immutable
class Atmosphere {
  const Atmosphere({
    required this.id,
    required this.name,
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.orb,
    required this.orbGlow,
    required this.cityFar,
    required this.cityNear,
    required this.ground,
    required this.roadLight,
    required this.roadDark,
    required this.roadEdge,
    required this.lampGlow,
    this.hasStars = false,
  });

  final String id;
  final String name;

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;

  /// قرصُ الشمس أو القمر.
  final Color orb;
  final Color orbGlow;

  final Color cityFar;
  final Color cityNear;

  final Color ground;
  final Color roadLight;
  final Color roadDark;
  final Color roadEdge;

  /// لونُ ضوء المصابيح على جانبَي الطريق.
  final Color lampGlow;

  final bool hasStars;

  /// لونُ الضباب عند الأفق؛ فيه تذوب الأشياءُ البعيدة.
  Color get hazeColor => skyBottom;

  static const Atmosphere dusk = Atmosphere(
    id: 'dusk',
    name: 'غروبُ القرية',
    skyTop: Color(0xFF2E4A6B),
    skyMid: Color(0xFF7A6A7B),
    skyBottom: Color(0xFFE8A65C),
    orb: Color(0xFFF6D79A),
    orbGlow: Color(0xFFF6C877),
    cityFar: Color(0xFF6E6A82),
    cityNear: Color(0xFF4A4059),
    ground: Color(0xFF8A7A56),
    roadLight: Color(0xFFC9A874),
    roadDark: Color(0xFFB9986A),
    roadEdge: Color(0xFF7A5E3A),
    lampGlow: Color(0xFFFFCB6B),
  );

  static const Atmosphere dawn = Atmosphere(
    id: 'dawn',
    name: 'فجرُ الرحلة',
    skyTop: Color(0xFF213A5C),
    skyMid: Color(0xFF8E7E92),
    skyBottom: Color(0xFFF3C9A8),
    orb: Color(0xFFFFF1D6),
    orbGlow: Color(0xFFFFE0B2),
    cityFar: Color(0xFF7C86A0),
    cityNear: Color(0xFF515C74),
    ground: Color(0xFF95886A),
    roadLight: Color(0xFFD8C29B),
    roadDark: Color(0xFFC9B189),
    roadEdge: Color(0xFF8A7452),
    lampGlow: Color(0xFFFFE3A3),
  );

  static const Atmosphere moonlit = Atmosphere(
    id: 'moonlit',
    name: 'ليلٌ مقمر',
    skyTop: Color(0xFF0B1830),
    skyMid: Color(0xFF1B2C4E),
    skyBottom: Color(0xFF32456B),
    orb: Color(0xFFEFF3FF),
    orbGlow: Color(0xFFAFC4EC),
    cityFar: Color(0xFF2A3A5A),
    cityNear: Color(0xFF17223A),
    ground: Color(0xFF2C3350),
    roadLight: Color(0xFF5A6180),
    roadDark: Color(0xFF4B5270),
    roadEdge: Color(0xFF313858),
    lampGlow: Color(0xFFFFD98A),
    hasStars: true,
  );

  static const Atmosphere clearDay = Atmosphere(
    id: 'clear_day',
    name: 'نهارٌ صافٍ',
    skyTop: Color(0xFF3E7BB8),
    skyMid: Color(0xFF8FC0DE),
    skyBottom: Color(0xFFDCEBF2),
    orb: Color(0xFFFFFBEA),
    orbGlow: Color(0xFFFFF2C4),
    cityFar: Color(0xFFA9B4C4),
    cityNear: Color(0xFF7A8798),
    ground: Color(0xFFB9A87C),
    roadLight: Color(0xFFE2CDA2),
    roadDark: Color(0xFFD3BC8E),
    roadEdge: Color(0xFF9C8659),
    lampGlow: Color(0xFFFFE9B0),
  );

  /// دورةُ الأجواء بالترتيب الذي يتنقّل بينه اللاعب.
  static const List<Atmosphere> all = [dusk, dawn, moonlit, clearDay];

  static Atmosphere byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => dusk);

  Atmosphere get next => all[(all.indexOf(this) + 1) % all.length];
}
