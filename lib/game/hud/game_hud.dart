import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../config/game_config.dart';
import '../rihla_game.dart';

/// شريطٌ علويٌّ خفيفٌ يعرض حالَ اللاعب، وزرُّ الشعلات أسفلَه.
///
/// السؤالُ نفسُه في العالم لا هنا؛ فبقيت الواجهةُ نحيفةً لا تزاحم المشهد.
class GameHud extends StatelessWidget {
  const GameHud({required this.game, required this.onExit, super.key});

  final RihlaGame game;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<HudState>(
        valueListenable: game.hud,
        builder: (context, hud, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _RoundButton(icon: Icons.close_rounded, onTap: onExit),
                    const SizedBox(width: 10),
                    Expanded(child: _LevelBar(hud: hud)),
                    const SizedBox(width: 8),
                    _Badge(
                      icon: Icons.local_fire_department_rounded,
                      value: '${hud.stats.currentStreak}',
                      color: hud.stats.currentStreak >= 3
                          ? AppPalette.failure
                          : AppPalette.inkSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _TorchButton(
                    hud: hud,
                    onTap: () => game.switchAtmosphere(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.hud});

  final HudState hud;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                hud.stats.level.title,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'المرحلة ${hud.stage}',
                style: const TextStyle(fontSize: 12, color: AppPalette.inkSoft),
              ),
              const Spacer(),
              Text(
                '${hud.stats.xp} خبرة',
                style: const TextStyle(fontSize: 13, color: AppPalette.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hud.stats.levelProgress,
              minHeight: 6,
              backgroundColor: AppPalette.parchmentDark,
              valueColor: const AlwaysStoppedAnimation(AppPalette.gold),
            ),
          ),
        ],
      ),
    );
  }
}

/// زرُّ الشعلات: يعرض ما جُمِع، ويبدّل جوَّ الرحلة متى اكتمل النصاب.
class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.hud, required this.onTap});

  final HudState hud;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ready = hud.canSwitchAtmosphere;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: ready ? onTap : null,
        child: _Pill(
          highlighted: ready,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: Color(0xFFE8813A),
              ),
              const SizedBox(width: 5),
              Text(
                '${hud.torches}/${GameConfig.torchesPerAtmosphere}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ready ? 'بدّل الأجواء' : hud.atmosphereName,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  fontWeight: ready ? FontWeight.w700 : FontWeight.w400,
                  color: ready ? AppPalette.ink : AppPalette.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.highlighted = false});

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.parchment.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: highlighted
              ? AppPalette.gold
              : AppPalette.woodDark.withValues(alpha: 0.4),
          width: highlighted ? 2 : 1,
        ),
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.parchment.withValues(alpha: 0.93),
      shape: CircleBorder(
        side: BorderSide(color: AppPalette.woodDark.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppPalette.ink),
        ),
      ),
    );
  }
}
