import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../game/game_screen.dart';

/// شاشةُ البداية: عنوانٌ هادئٌ، ومبدأُ اللعبة في سطر، ثمّ الطريق.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E4A6B), Color(0xFF7A6A7B), Color(0xFFE8A65C)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _TitlePlate(),
                  const SizedBox(height: 26),
                  Text(
                    'الإعرابُ يحدّد الطريق',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 25,
                      color: AppPalette.parchment.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 46),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GameScreen(),
                      ),
                    ),
                    child: const Text('ابدأ الرحلة'),
                  ),
                  const SizedBox(height: 34),
                  const _ControlsHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitlePlate extends StatelessWidget {
  const _TitlePlate();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
      decoration: BoxDecoration(
        color: AppPalette.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.woodDark, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: const Text(
        'رِحْلَةُ العَرَبِيَّة',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 42,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: AppPalette.ink,
        ),
      ),
    );
  }
}

class _ControlsHint extends StatelessWidget {
  const _ControlsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'اسحب إصبعَك رأسيًّا لتوجيه المسافر بين الطريقين.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.8,
              color: AppPalette.parchment.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اقرأ الجملةَ على البوابة، ثمّ ادخل البابَ الذي يحمل الإعرابَ الصحيح.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.8,
              color: AppPalette.parchment.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
