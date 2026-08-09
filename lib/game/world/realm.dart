import 'package:flutter/material.dart';

/// ما يقوم على جانبَي الطريق. تغييرُه هو ما يبدّل هيئةَ العالم فعلًا،
/// لا لونَ سمائه فحسب.
enum RoadsideKind { palms, marketColumns, cypressLanterns, libraryShelves, dunes }

/// ما يعلو الأفق.
enum SkylineKind { domes, arches, dunes, colonnade }

/// كسوةُ الطريق نفسِه.
enum RoadSurface { dirt, stoneTiles, carpet, sand }

/// ما يطفو في الهواء.
enum AmbientParticle { none, dust, fireflies, embers }

/// إقليمٌ كامل: سماءٌ وأرضٌ وطريقٌ وما يقوم على جانبيه وما يطفو في هوائه.
///
/// الشعلاتُ تنقل اللاعبَ من إقليمٍ إلى إقليم. ولم يُكتفَ بتبديل الألوان لأنّ
/// المشهدَ يبقى هو هو ما دامت الأشجارُ والطريقُ على حالها؛ فصار لكلّ إقليمٍ
/// نوعُ ما على جانبيه، وكسوةُ طريقه، وخطُّ أفقه، وما يطفو في هوائه.
@immutable
class Realm {
  const Realm({
    required this.id,
    required this.name,
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.orb,
    required this.orbGlow,
    required this.structureFar,
    required this.structureNear,
    required this.ground,
    required this.roadLight,
    required this.roadDark,
    required this.roadEdge,
    required this.lampGlow,
    required this.roadside,
    required this.skyline,
    required this.surface,
    this.particle = AmbientParticle.none,
    this.hasStars = false,
    this.showOrb = true,
  });

  final String id;
  final String name;

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;

  final Color orb;
  final Color orbGlow;
  final bool showOrb;

  final Color structureFar;
  final Color structureNear;

  final Color ground;
  final Color roadLight;
  final Color roadDark;
  final Color roadEdge;
  final Color lampGlow;

  final RoadsideKind roadside;
  final SkylineKind skyline;
  final RoadSurface surface;
  final AmbientParticle particle;
  final bool hasStars;

  Color get hazeColor => skyBottom;

  static const Realm palmVillage = Realm(
    id: 'palm_village',
    name: 'قريةُ النخيل',
    skyTop: Color(0xFF2E4A6B),
    skyMid: Color(0xFF7A6A7B),
    skyBottom: Color(0xFFE8A65C),
    orb: Color(0xFFF6D79A),
    orbGlow: Color(0xFFF6C877),
    structureFar: Color(0xFF6E6A82),
    structureNear: Color(0xFF4A4059),
    ground: Color(0xFF8A7A56),
    roadLight: Color(0xFFC9A874),
    roadDark: Color(0xFFB9986A),
    roadEdge: Color(0xFF7A5E3A),
    lampGlow: Color(0xFFFFCB6B),
    roadside: RoadsideKind.palms,
    skyline: SkylineKind.domes,
    surface: RoadSurface.dirt,
    particle: AmbientParticle.dust,
  );

  static const Realm grammarMarket = Realm(
    id: 'grammar_market',
    name: 'سوقُ النحو',
    skyTop: Color(0xFF4C86BE),
    skyMid: Color(0xFF9FC8E3),
    skyBottom: Color(0xFFF0E3CB),
    orb: Color(0xFFFFFBEA),
    orbGlow: Color(0xFFFFF0C0),
    structureFar: Color(0xFFB6A88E),
    structureNear: Color(0xFF8A7A62),
    ground: Color(0xFFC3B491),
    roadLight: Color(0xFFE9DCC2),
    roadDark: Color(0xFFD5C6A8),
    roadEdge: Color(0xFF9A886A),
    lampGlow: Color(0xFFFFE9B0),
    roadside: RoadsideKind.marketColumns,
    skyline: SkylineKind.arches,
    surface: RoadSurface.stoneTiles,
  );

  static const Realm nightOasis = Realm(
    id: 'night_oasis',
    name: 'واحةُ الليل',
    skyTop: Color(0xFF060F24),
    skyMid: Color(0xFF14213F),
    skyBottom: Color(0xFF2B3D60),
    orb: Color(0xFFEFF3FF),
    orbGlow: Color(0xFFAFC4EC),
    structureFar: Color(0xFF243354),
    structureNear: Color(0xFF101A2E),
    ground: Color(0xFF1E2740),
    roadLight: Color(0xFF46506F),
    roadDark: Color(0xFF3A4360),
    roadEdge: Color(0xFF232B44),
    lampGlow: Color(0xFFFFD98A),
    roadside: RoadsideKind.cypressLanterns,
    skyline: SkylineKind.domes,
    surface: RoadSurface.dirt,
    particle: AmbientParticle.fireflies,
    hasStars: true,
  );

  static const Realm scholarsHall = Realm(
    id: 'scholars_hall',
    name: 'رِواقُ المكتبة',
    skyTop: Color(0xFF2A1D14),
    skyMid: Color(0xFF4A3324),
    skyBottom: Color(0xFF7A5533),
    orb: Color(0xFFFFE0A3),
    orbGlow: Color(0xFFFFC978),
    structureFar: Color(0xFF6B4B32),
    structureNear: Color(0xFF4A3122),
    ground: Color(0xFF3E2A1C),
    roadLight: Color(0xFF8E2F2F),
    roadDark: Color(0xFF7A2626),
    roadEdge: Color(0xFFD9B36A),
    lampGlow: Color(0xFFFFCE7A),
    roadside: RoadsideKind.libraryShelves,
    skyline: SkylineKind.colonnade,
    surface: RoadSurface.carpet,
    particle: AmbientParticle.embers,
    showOrb: false,
  );

  static const Realm sandSea = Realm(
    id: 'sand_sea',
    name: 'بحرُ الرمال',
    skyTop: Color(0xFF8B5E2A),
    skyMid: Color(0xFFD79B4E),
    skyBottom: Color(0xFFF3D7A1),
    orb: Color(0xFFFFF3D0),
    orbGlow: Color(0xFFFFDFA0),
    structureFar: Color(0xFFD9BC88),
    structureNear: Color(0xFFBE9C66),
    ground: Color(0xFFDCC08A),
    roadLight: Color(0xFFEBD6A6),
    roadDark: Color(0xFFDCC591),
    roadEdge: Color(0xFFB99A65),
    lampGlow: Color(0xFFFFE7B5),
    roadside: RoadsideKind.dunes,
    skyline: SkylineKind.dunes,
    surface: RoadSurface.sand,
    particle: AmbientParticle.dust,
  );

  /// ترتيبُ الأقاليم الذي ينتقل بينه اللاعب بشعلاته.
  static const List<Realm> all = [
    palmVillage,
    grammarMarket,
    nightOasis,
    scholarsHall,
    sandSea,
  ];

  Realm get next => all[(all.indexOf(this) + 1) % all.length];
}
