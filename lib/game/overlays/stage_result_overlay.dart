import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../domain/models/stage_definition.dart';
import '../rihla_game.dart';

/// شاشةُ نتيجة المرحلة: تظهر بعد آخر بوّابةٍ من عشرين، وتعرض الحكم
/// والخيارات المتاحة بعده.
///
/// الفوزُ يفتح خيارين: المتابعةُ إلى المرحلة التالية، أو إعادةُ هذه المرحلة.
/// الخسارةُ لا تفتح إلّا خيارًا واحدًا: إعادةَ المحاولة. فلا يُسمح بالتقدّم
/// بمنهجٍ لم يُتقَن.
class StageResultOverlay extends StatelessWidget {
  const StageResultOverlay({
    required this.game,
    required this.onNextStage,
    required this.onRetryStage,
    super.key,
  });

  final RihlaGame game;
  final VoidCallback onNextStage;
  final VoidCallback onRetryStage;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: game.stageOutcome,
      builder: (context, outcome, _) {
        if (outcome == null) return const SizedBox.shrink();

        final passed = outcome.passed;
        final hasNextStage = StageCatalog.hasStage(outcome.stageIndex + 1);

        return Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.62),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: AppPalette.parchment,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: passed ? AppPalette.gold : AppPalette.failure,
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      passed
                          ? Icons.emoji_events_rounded
                          : Icons.sentiment_dissatisfied_rounded,
                      size: 46,
                      color: passed ? AppPalette.gold : AppPalette.failure,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      passed ? 'فُزتَ بالمرحلة' : 'لم تكتمل المرحلة',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أصبتَ ${outcome.correct} من ${outcome.total}'
                      '، والنصابُ ${outcome.passScore}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppPalette.inkSoft,
                      ),
                    ),
                    if (!passed) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'راجِع ما أخطأتَ فيه، ثمّ أعِد المحاولة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppPalette.inkSoft,
                        ),
                      ),
                    ],
                    if (passed && !hasNextStage) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'أتممتَ مراحلَ الرحلة كلَّها. أحسنتَ!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          color: AppPalette.gold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (passed && hasNextStage)
                      FilledButton(
                        onPressed: onNextStage,
                        child: const Text('المرحلةُ التالية'),
                      ),
                    if (passed && hasNextStage) const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: onRetryStage,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 52),
                        side: const BorderSide(color: AppPalette.woodDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'أعِد المحاولة',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          color: AppPalette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
