import 'package:flutter/material.dart';

import '../../../game/base_defense_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  final BaseDefenseGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<HudModel>(
        valueListenable: game.hud,
        builder: (context, hud, _) {
          final bossHpRatio = hud.bossHp == null || hud.bossMaxHp == null
              ? null
              : (hud.bossHp! / hud.bossMaxHp!).clamp(0.0, 1.0);
          final nextStageText = hud.nextStageSeconds == null
              ? 'Clear remaining enemies'
              : 'Next phase in ${hud.nextStageSeconds!.ceil()}s';

          return Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB30F1720),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xCC3A4E5F)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Score ${hud.score}',
                            style: const TextStyle(
                              color: Color(0xFFE8EEFA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Coins ${hud.coins}',
                            style: const TextStyle(
                              color: Color(0xFFFFE08A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Allies ${hud.allyCount}/${hud.allyCap}',
                            style: const TextStyle(
                              color: Color(0xFF97D8FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Garrison ${hud.garrisonedAllyCount}/${hud.garrisonedAllyCap}',
                            style: const TextStyle(
                              color: Color(0xFF91B7FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Towers ${hud.watchtowerCount}',
                            style: const TextStyle(
                              color: Color(0xFFB6E2FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (bossHpRatio != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'BOSS',
                          style: TextStyle(
                            color: Color(0xFFFFB8C1),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 280,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: bossHpRatio,
                              minHeight: 9,
                              backgroundColor: const Color(0xFF2D1326),
                              color: const Color(0xFFE34877),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '${hud.stageName}  |  $nextStageText',
                        style: const TextStyle(
                          color: Color(0xFFD5E0EC),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hud.stageBanner != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC182430),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: const Color(0xAA8FB4D0)),
                    ),
                    child: Text(
                      hud.stageBanner!,
                      style: const TextStyle(
                        color: Color(0xFFF6F9FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
