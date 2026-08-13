import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../config/game_config.dart';
import '../rihla_game.dart';

/// شريطٌ علويٌّ خفيفٌ يعرض حالَ اللاعب، وتحته ما يجمعه وما يستطيع فعلَه.
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
                      icon: Icons.bolt_rounded,
                      value: '${hud.stats.currentStreak}',
                      color: hud.stats.currentStreak >= 3
                          ? AppPalette.failure
                          : AppPalette.inkSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TorchButton(hud: hud, onTap: game.switchRealm),
                    const SizedBox(width: 8),
                    _BookMeter(hud: hud),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _TurboButton(hud: hud, onTap: game.startTurbo),
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
                '${hud.stageIndex}. ${hud.stageTitle}',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
              ),
              const Spacer(),
              Text(
                '${hud.gatesAnswered}/${hud.gatesTotal}'
                ' • صحيحٌ ${hud.gatesCorrect}',
                style: const TextStyle(fontSize: 12, color: AppPalette.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hud.gatesTotal == 0
                  ? 0
                  : hud.gatesAnswered / hud.gatesTotal,
              minHeight: 6,
              backgroundColor: AppPalette.parchmentDark,
              valueColor: AlwaysStoppedAnimation(
                hud.gatesCorrect >= hud.passScore
                    ? AppPalette.success
                    : AppPalette.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زرُّ الشعلات: ينقل اللاعبَ إلى إقليمٍ جديدٍ متى اكتمل النصاب.
class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.hud, required this.onTap});

  final HudState hud;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ready = hud.canSwitchRealm;
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
                '${hud.torches}/${GameConfig.torchesPerRealm}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ready ? 'ارحل إلى إقليمٍ جديد' : hud.realmName,
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

/// عدّادُ الكتب وما بقي منها حتى الزيّ التالي.
class _BookMeter extends StatelessWidget {
  const _BookMeter({required this.hud});

  final HudState hud;

  @override
  Widget build(BuildContext context) {
    final remaining = hud.booksToNextOutfit;
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 17,
            color: Color(0xFF8E2F3F),
          ),
          const SizedBox(width: 5),
          Text(
            '${hud.books}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(width: 6),
            Text(
              'زيٌّ جديد بعد $remaining',
              style: const TextStyle(fontSize: 12, color: AppPalette.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

/// زرُّ الانطلاق: يُفتح بعد سلسلةِ إصابات، ويطوي به اللاعبُ الطريقَ
/// متجاوزًا البوابات دون أن تُحسب له ولا عليه.
class _TurboButton extends StatelessWidget {
  const _TurboButton({required this.hud, required this.onTap});

  final HudState hud;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = hud.isTurboActive;
    final ready = hud.turboReady;

    if (!ready && !active) {
      return _Pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              size: 17,
              color: AppPalette.inkSoft.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              'الانطلاق يحتاج '
              '${GameConfig.turboStreakRequirement} إجاباتٍ متّصلة',
              style: const TextStyle(fontSize: 12, color: AppPalette.inkSoft),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: active ? null : onTap,
        child: _Pill(
          highlighted: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.rocket_launch_rounded,
                size: 18,
                color: AppPalette.gold,
              ),
              const SizedBox(width: 6),
              Text(
                active
                    ? 'منطلق… ${hud.turboRemaining.ceil()}'
                    : 'انطلق وتجاوز',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
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
