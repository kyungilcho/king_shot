import 'package:flutter/material.dart';

import '../../../core/utils/time_format.dart';
import '../../../game/base_defense_game.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    required this.game,
    required this.hearts,
    required this.maxHearts,
    required this.nextHeartIn,
    required this.onRetry,
    required this.onBackHome,
    super.key,
  });

  final BaseDefenseGame game;
  final int hearts;
  final int maxHearts;
  final Duration? nextHeartIn;
  final VoidCallback onRetry;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xB0000000),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF121920),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5C7287)),
          ),
          child: ValueListenableBuilder<HudModel>(
            valueListenable: game.hud,
            builder: (context, hud, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Color(0xFFF7FBFF),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reached Stage ${hud.stageIndex}',
                    style: const TextStyle(color: Color(0xFFCEE0F0)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Score ${hud.score}',
                    style: const TextStyle(color: Color(0xFFE0ECF8)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Coins ${hud.coins}',
                    style: const TextStyle(color: Color(0xFFFFE08A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hearts $hearts/$maxHearts  (Retry cost: 1)',
                    style: const TextStyle(color: Color(0xFFFFB9C1)),
                  ),
                  if (nextHeartIn != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Next heart in ${formatMmSs(nextHeartIn!)}',
                      style: const TextStyle(
                        color: Color(0xFFFFCBD1),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: hearts > 0 ? onRetry : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D7DF6),
                          disabledBackgroundColor: const Color(0xFF374758),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(120, 42),
                        ),
                        child: Text(
                          hearts > 0 ? 'Retry (-1 Heart)' : 'No Hearts',
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: onBackHome,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD8E6F3),
                          side: const BorderSide(color: Color(0xFF6A8196)),
                          minimumSize: const Size(92, 42),
                        ),
                        child: const Text('Home'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
