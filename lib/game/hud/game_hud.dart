import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../domain/engines/session_engine.dart';
import '../rihla_game.dart';

/// شريطٌ علويٌّ خفيفٌ يعرض حالَ اللاعب.
///
/// هذه معلوماتٌ مساعِدةٌ فحسب؛ فالسؤالُ نفسُه في العالم لا هنا،
/// ولذلك بقي الشريطُ نحيفًا لا يزاحم المشهد.
class GameHud extends StatelessWidget {
  const GameHud({required this.game, required this.onExit, super.key});

  final RihlaGame game;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<SessionStats>(
        valueListenable: game.stats,
        builder: (context, stats, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _IconButtonPill(icon: Icons.close_rounded, onTap: onExit),
                    const SizedBox(width: 10),
                    Expanded(child: _LevelBar(stats: stats)),
                    const SizedBox(width: 10),
                    _Badge(
                      icon: Icons.local_fire_department_rounded,
                      value: '${stats.currentStreak}',
                      color: stats.currentStreak >= 3
                          ? AppPalette.failure
                          : AppPalette.inkSoft,
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      icon: Icons.monetization_on_rounded,
                      value: '${stats.coins}',
                      color: AppPalette.gold,
                    ),
                  ],
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
  const _LevelBar({required this.stats});

  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.parchment.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppPalette.woodDark.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                stats.level.title,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.xp} خبرة',
                style: const TextStyle(fontSize: 13, color: AppPalette.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.levelProgress,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.parchment.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppPalette.woodDark.withValues(alpha: 0.4)),
      ),
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

class _IconButtonPill extends StatelessWidget {
  const _IconButtonPill({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.parchment.withValues(alpha: 0.92),
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
