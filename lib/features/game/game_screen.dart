import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../data/repositories/asset_question_repository.dart';
import '../../domain/engines/challenge_factory.dart';
import '../../domain/engines/question_selector.dart';
import '../../domain/engines/session_engine.dart';
import '../../game/config/game_config.dart';
import '../../game/hud/game_hud.dart';
import '../../game/rihla_game.dart';

/// شاشةُ اللعب: تحمّل بنك الأسئلة، ثمّ تُسلّمه إلى محرّك الجلسة واللعبة.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final Future<RihlaGame> _gameFuture = _createGame();

  Future<RihlaGame> _createGame() async {
    final repository = AssetQuestionRepository();
    final questions = await repository.loadLevel(1);

    return RihlaGame(
      sessionEngine: SessionEngine(
        selector: ShuffledQuestionSelector(questions: questions),
        challengeFactory: ChallengeFactory(laneCount: GameConfig.laneCount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.ink,
      body: FutureBuilder<RihlaGame>(
        future: _gameFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadFailure(error: snapshot.error!);
          }
          final game = snapshot.data;
          if (game == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppPalette.gold),
            );
          }
          return Stack(
            children: [
              GameWidget(game: game, autofocus: true),
              GameHud(
                game: game,
                onExit: () => Navigator.of(context).maybePop(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final isContentError = error is FormatException || error is StateError;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded,
                size: 46, color: AppPalette.gold),
            const SizedBox(height: 16),
            Text(
              isContentError
                  ? 'تعذّر فتحُ بنك الأسئلة؛ في المحتوى خللٌ يحتاج مراجعة.'
                  : 'تعذّر تحميلُ الرحلة.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                color: AppPalette.parchment,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.parchment.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
