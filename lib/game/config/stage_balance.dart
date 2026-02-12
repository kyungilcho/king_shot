part of '../base_defense_game.dart';

const int _stageCount = 20;

const List<StageDifficulty> _difficultyPattern = [
  StageDifficulty.normal,
  StageDifficulty.normal,
  StageDifficulty.hard,
  StageDifficulty.normal,
  StageDifficulty.veryHard,
  StageDifficulty.normal,
  StageDifficulty.normal,
  StageDifficulty.hard,
  StageDifficulty.normal,
  StageDifficulty.hell,
];

const List<StageConfig> _normalPhaseTemplate = [
  StageConfig(
    name: 'Phase 1',
    duration: 42,
    spawnPerSecond: 1.2,
    enemyTable: [StageEnemyWeight(EnemyType.grunt, 1)],
  ),
  StageConfig(
    name: 'Phase 2',
    duration: 48,
    spawnPerSecond: 1.5,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.88),
      StageEnemyWeight(EnemyType.brute, 0.12),
    ],
  ),
  StageConfig(
    name: 'Phase 3',
    duration: 54,
    spawnPerSecond: 1.9,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.8),
      StageEnemyWeight(EnemyType.brute, 0.2),
    ],
    isFinal: true,
  ),
];

const List<StageConfig> _hardPhaseTemplate = [
  StageConfig(
    name: 'Phase 1',
    duration: 45,
    spawnPerSecond: 1.8,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.78),
      StageEnemyWeight(EnemyType.brute, 0.22),
    ],
  ),
  StageConfig(
    name: 'Phase 2',
    duration: 52,
    spawnPerSecond: 2.2,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.66),
      StageEnemyWeight(EnemyType.brute, 0.3),
      StageEnemyWeight(EnemyType.elite, 0.04),
    ],
  ),
  StageConfig(
    name: 'Phase 3',
    duration: 58,
    spawnPerSecond: 2.6,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.56),
      StageEnemyWeight(EnemyType.brute, 0.34),
      StageEnemyWeight(EnemyType.elite, 0.1),
    ],
    isFinal: true,
  ),
];

const List<StageConfig> _veryHardPhaseTemplate = [
  StageConfig(
    name: 'Phase 1',
    duration: 50,
    spawnPerSecond: 2.4,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.6),
      StageEnemyWeight(EnemyType.brute, 0.33),
      StageEnemyWeight(EnemyType.elite, 0.07),
    ],
  ),
  StageConfig(
    name: 'Phase 2',
    duration: 56,
    spawnPerSecond: 2.9,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.5),
      StageEnemyWeight(EnemyType.brute, 0.37),
      StageEnemyWeight(EnemyType.elite, 0.13),
    ],
  ),
  StageConfig(
    name: 'Phase 3',
    duration: 62,
    spawnPerSecond: 3.3,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.42),
      StageEnemyWeight(EnemyType.brute, 0.4),
      StageEnemyWeight(EnemyType.elite, 0.18),
    ],
    isFinal: true,
  ),
];

const List<StageConfig> _hellPhaseTemplate = [
  StageConfig(
    name: 'Phase 1',
    duration: 54,
    spawnPerSecond: 2.9,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.53),
      StageEnemyWeight(EnemyType.brute, 0.35),
      StageEnemyWeight(EnemyType.elite, 0.12),
    ],
  ),
  StageConfig(
    name: 'Phase 2',
    duration: 60,
    spawnPerSecond: 3.5,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.45),
      StageEnemyWeight(EnemyType.brute, 0.38),
      StageEnemyWeight(EnemyType.elite, 0.17),
    ],
  ),
  StageConfig(
    name: 'Phase 3',
    duration: 66,
    spawnPerSecond: 4.0,
    enemyTable: [
      StageEnemyWeight(EnemyType.grunt, 0.38),
      StageEnemyWeight(EnemyType.brute, 0.41),
      StageEnemyWeight(EnemyType.elite, 0.21),
    ],
    isFinal: true,
  ),
];

List<StageDefinition> _buildStageDefinitions() {
  final stages = <StageDefinition>[];
  for (var stageNumber = 1; stageNumber <= _stageCount; stageNumber += 1) {
    final difficulty =
        _difficultyPattern[(stageNumber - 1) % _difficultyPattern.length];
    final percent = (stageNumber - 1) + difficulty.bonusPercent;
    final multiplier = 1 + (percent / 100);
    stages.add(
      StageDefinition(
        name: 'Stage $stageNumber - ${difficulty.label}',
        difficulty: difficulty,
        phases: _phaseTemplateForDifficulty(difficulty),
        spawnRateMultiplier: multiplier,
        enemyHpMultiplier: multiplier,
        enemyDamageMultiplier: multiplier,
        rewardMultiplier: multiplier,
      ),
    );
  }
  return stages;
}

List<StageConfig> _phaseTemplateForDifficulty(StageDifficulty difficulty) {
  return switch (difficulty) {
    StageDifficulty.normal => _normalPhaseTemplate,
    StageDifficulty.hard => _hardPhaseTemplate,
    StageDifficulty.veryHard => _veryHardPhaseTemplate,
    StageDifficulty.hell => _hellPhaseTemplate,
  };
}
