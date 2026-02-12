part of '../base_defense_game.dart';

enum EnemyType { grunt, brute, elite, boss }

enum UpgradePadType { weapon, barracks, watchtower }

enum StageDifficulty { normal, hard, veryHard, hell }

extension StageDifficultyX on StageDifficulty {
  String get label => switch (this) {
    StageDifficulty.normal => 'Normal',
    StageDifficulty.hard => 'Hard',
    StageDifficulty.veryHard => 'Very Hard',
    StageDifficulty.hell => 'Hell',
  };

  double get bonusPercent => switch (this) {
    StageDifficulty.normal => 0,
    StageDifficulty.hard => 1.5,
    StageDifficulty.veryHard => 3.0,
    StageDifficulty.hell => 4.5,
  };
}

class EnemySpec {
  const EnemySpec({
    required this.label,
    required this.radius,
    required this.maxHp,
    required this.speed,
    required this.baseDamagePerSecond,
    required this.color,
    required this.score,
    required this.coinDrop,
  });

  final String label;
  final double radius;
  final double maxHp;
  final double speed;
  final double baseDamagePerSecond;
  final Color color;
  final int score;
  final int coinDrop;
}

const Map<EnemyType, EnemySpec> enemySpecs = {
  EnemyType.grunt: EnemySpec(
    label: 'Grunt',
    radius: 14,
    maxHp: 34,
    speed: 90,
    baseDamagePerSecond: 6.2,
    color: Color(0xFFCB4A3A),
    score: 10,
    coinDrop: 1,
  ),
  EnemyType.brute: EnemySpec(
    label: 'Brute',
    radius: 20,
    maxHp: 82,
    speed: 75,
    baseDamagePerSecond: 14.5,
    color: Color(0xFF8F2B1F),
    score: 30,
    coinDrop: 2,
  ),
  EnemyType.elite: EnemySpec(
    label: 'Elite',
    radius: 24,
    maxHp: 154,
    speed: 78,
    baseDamagePerSecond: 27,
    color: Color(0xFF5D1A12),
    score: 75,
    coinDrop: 5,
  ),
  EnemyType.boss: EnemySpec(
    label: 'Boss',
    radius: 36,
    maxHp: 760,
    speed: 62,
    baseDamagePerSecond: 55,
    color: Color(0xFF2B1026),
    score: 280,
    coinDrop: 20,
  ),
};

class StageEnemyWeight {
  const StageEnemyWeight(this.type, this.weight);

  final EnemyType type;
  final double weight;
}

class StageConfig {
  const StageConfig({
    required this.name,
    required this.duration,
    required this.spawnPerSecond,
    required this.enemyTable,
    this.isFinal = false,
  });

  final String name;
  final double duration;
  final double spawnPerSecond;
  final List<StageEnemyWeight> enemyTable;
  final bool isFinal;

  EnemyType pickEnemy(math.Random random) {
    final total = enemyTable.fold<double>(0, (sum, row) => sum + row.weight);
    var roll = random.nextDouble() * total;
    for (final row in enemyTable) {
      roll -= row.weight;
      if (roll <= 0) {
        return row.type;
      }
    }
    return enemyTable.last.type;
  }
}

class StageDefinition {
  const StageDefinition({
    required this.name,
    required this.difficulty,
    required this.phases,
    required this.spawnRateMultiplier,
    required this.enemyHpMultiplier,
    required this.enemyDamageMultiplier,
    required this.rewardMultiplier,
  });

  final String name;
  final StageDifficulty difficulty;
  final List<StageConfig> phases;
  final double spawnRateMultiplier;
  final double enemyHpMultiplier;
  final double enemyDamageMultiplier;
  final double rewardMultiplier;
}

@immutable
class HudModel {
  const HudModel({
    required this.baseHp,
    required this.baseMaxHp,
    required this.stageIndex,
    required this.stageName,
    required this.score,
    required this.coins,
    required this.weaponLevel,
    required this.weaponUpgradeCost,
    required this.barracksLevel,
    required this.barracksUpgradeCost,
    required this.watchtowerCount,
    required this.watchtowerBuildCost,
    required this.allyCount,
    required this.allyCap,
    required this.garrisonedAllyCount,
    required this.garrisonedAllyCap,
    required this.nearbyActionLabel,
    required this.nearbyActionCost,
    required this.nearbyActionAffordable,
    required this.nextStageSeconds,
    required this.stageBanner,
    required this.bossHp,
    required this.bossMaxHp,
    required this.isGameOver,
  });

  final double baseHp;
  final double baseMaxHp;
  final int stageIndex;
  final String stageName;
  final int score;
  final int coins;
  final int weaponLevel;
  final int weaponUpgradeCost;
  final int barracksLevel;
  final int barracksUpgradeCost;
  final int watchtowerCount;
  final int watchtowerBuildCost;
  final int allyCount;
  final int allyCap;
  final int garrisonedAllyCount;
  final int garrisonedAllyCap;
  final String? nearbyActionLabel;
  final int? nearbyActionCost;
  final bool nearbyActionAffordable;
  final double? nextStageSeconds;
  final String? stageBanner;
  final double? bossHp;
  final double? bossMaxHp;
  final bool isGameOver;
}
