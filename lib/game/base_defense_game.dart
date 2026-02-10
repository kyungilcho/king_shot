import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class BaseDefenseGame extends FlameGame with KeyboardEvents {
  BaseDefenseGame({
    int startStageIndex = 0,
    this.onStageCleared,
    int startingCoins = 0,
    int startingWeaponLevel = 1,
    double baseHpMultiplier = 1.0,
  }) : _selectedStartStageIndex = _clampStageIndex(startStageIndex),
       _startingCoins = math.max(0, startingCoins),
       _startingWeaponLevel = math.max(1, startingWeaponLevel),
       _baseMaxHp = (_defaultBaseHp * baseHpMultiplier.clamp(0.5, 3.0))
           .toDouble(),
       super(
         camera: CameraComponent.withFixedResolution(width: 420, height: 760),
       ) {
    _currentStageIndex = _selectedStartStageIndex;
    _baseHp = _baseMaxHp;
    _coins = _startingCoins;
    _weaponLevel = _startingWeaponLevel;
  }

  static const String hudOverlayId = 'hud';
  static const String gameOverOverlayId = 'game_over';

  static const int _stageCount = 20;

  static const List<StageDifficulty> _difficultyPattern = [
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

  static const List<StageConfig> _normalPhaseTemplate = [
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

  static const List<StageConfig> _hardPhaseTemplate = [
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

  static const List<StageConfig> _veryHardPhaseTemplate = [
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

  static const List<StageConfig> _hellPhaseTemplate = [
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

  static final List<StageDefinition> _stages = _buildStageDefinitions();

  static List<StageDefinition> _buildStageDefinitions() {
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

  static List<StageConfig> _phaseTemplateForDifficulty(
    StageDifficulty difficulty,
  ) {
    return switch (difficulty) {
      StageDifficulty.normal => _normalPhaseTemplate,
      StageDifficulty.hard => _hardPhaseTemplate,
      StageDifficulty.veryHard => _veryHardPhaseTemplate,
      StageDifficulty.hell => _hellPhaseTemplate,
    };
  }

  static int _clampStageIndex(int index) =>
      index.clamp(0, _stages.length - 1).toInt();

  static int get stageCount => _stages.length;

  static String stageNameAt(int index) => _stages[_clampStageIndex(index)].name;

  final arenaSize = Vector2(2200, 1400);
  final _random = math.Random();
  final _keyboardInput = Vector2.zero();
  final _playerFacingDirection = Vector2(0, -1);
  final enemies = <EnemyComponent>{};
  final bullets = <BulletComponent>{};
  final droppedCoins = <CoinComponent>{};
  final allies = <AllyUnitComponent>{};
  final watchtowers = <WatchtowerComponent>{};
  final hud = ValueNotifier<HudModel>(
    const HudModel(
      baseHp: 0,
      baseMaxHp: 0,
      stageIndex: 1,
      stageName: 'Stage 1',
      score: 0,
      coins: 0,
      weaponLevel: 1,
      weaponUpgradeCost: 8,
      barracksLevel: 0,
      barracksUpgradeCost: 10,
      watchtowerCount: 0,
      watchtowerBuildCost: 16,
      allyCount: 0,
      allyCap: 0,
      garrisonedAllyCount: 0,
      garrisonedAllyCap: 0,
      nearbyActionLabel: null,
      nearbyActionCost: null,
      nearbyActionAffordable: false,
      nextStageSeconds: null,
      stageBanner: null,
      bossHp: null,
      bossMaxHp: null,
      isGameOver: false,
    ),
  );

  static const double _defaultBaseHp = 1000;
  static const double _playerToBaseDistance = 110;
  static const double _stageBannerDuration = 2.2;
  static const double _stageClearDelay = 1.2;
  static const double _barracksCollisionWidthScale = 0.84;
  static const double _barracksCollisionHeightScale = 0.72;
  static const double _watchtowerCollisionWidthScale = 0.82;
  static const double _watchtowerCollisionHeightScale = 0.78;

  late final ArenaComponent _arena;
  late final CoreBaseComponent _base;
  late final BarracksComponent _barracks;
  late final PlayerComponent _player;
  late final UpgradePadComponent _weaponPad;
  late final UpgradePadComponent _barracksPad;
  late final UpgradePadComponent _watchtowerPad;
  late final DynamicJoystickComponent _dynamicJoystick;
  final int _selectedStartStageIndex;
  final int _startingCoins;
  final int _startingWeaponLevel;
  final double _baseMaxHp;
  final void Function(int stars)? onStageCleared;

  double _baseHp = 0;
  int _currentStageIndex = 0;
  int _currentPhaseIndex = 0;
  double _stageElapsed = 0;
  double _spawnBudget = 0;
  double _hudRefreshTimer = 0;
  double _stageBannerTimer = _stageBannerDuration;
  int _score = 0;
  int _coins = 0;
  int _weaponLevel = 1;
  int _barracksLevel = 0;
  bool _watchtowerBuilt = false;
  int _allySlotCounter = 0;
  bool _isGameOver = false;
  bool _spawnEnabled = true;
  bool _isStageClear = false;
  bool _stageClearNotified = false;
  double _stageClearTimer = 0;
  int _stageClearStars = 0;
  bool _hellBossSpawned = false;

  StageDefinition get currentStage => _stages[_currentStageIndex];
  StageConfig get currentPhase => currentStage.phases[_currentPhaseIndex];
  bool get isLastPhase => _currentPhaseIndex >= currentStage.phases.length - 1;
  Vector2 get playerPosition => _player.position;
  double get playerRadius => _player.radius;
  Vector2 get playerFacingDirection => _playerFacingDirection;
  int get coins => _coins;
  bool get isGameOver => _isGameOver;
  int get allyCap => _barracksLevel == 0 ? 0 : 1 + _barracksLevel * 2;
  int get garrisonedAllyCount {
    var total = 0;
    for (final tower in watchtowers) {
      total += tower.garrisonCount;
    }
    return total;
  }

  int get garrisonedAllyCap =>
      watchtowers.length * WatchtowerComponent.garrisonCapacity;
  int get weaponUpgradeCost => 8 + (_weaponLevel - 1) * 7;
  int get barracksUpgradeCost => 10 + _barracksLevel * 9;
  int get watchtowerBuildCost => _watchtowerBuilt ? 0 : 16;
  double get playerAttackRange => 270 + (_weaponLevel - 1) * 12;
  double get playerFireCooldown =>
      math.max(0.1, 0.23 - (_weaponLevel - 1) * 0.016);
  double get playerBulletDamage => 30 + (_weaponLevel - 1) * 8;
  double get baseHp => _baseHp;
  double get baseMaxHp => _baseMaxHp;

  Vector2 readMovementInput() {
    final input = _dynamicJoystick.input + _keyboardInput;
    if (input.length2 > 1) {
      input.normalize();
    }
    return input;
  }

  int costForPad(UpgradePadType type) {
    return switch (type) {
      UpgradePadType.weapon => weaponUpgradeCost,
      UpgradePadType.barracks => barracksUpgradeCost,
      UpgradePadType.watchtower => watchtowerBuildCost,
    };
  }

  int levelForPad(UpgradePadType type) {
    return switch (type) {
      UpgradePadType.weapon => _weaponLevel,
      UpgradePadType.barracks => _barracksLevel,
      UpgradePadType.watchtower => watchtowers.length,
    };
  }

  String labelForPad(UpgradePadType type) {
    return switch (type) {
      UpgradePadType.weapon => 'Weapon',
      UpgradePadType.barracks => 'Barracks',
      UpgradePadType.watchtower => 'Watchtower',
    };
  }

  bool canAffordPad(UpgradePadType type) => _coins >= costForPad(type);

  bool upgradeWeapon({bool chargeCoins = true}) {
    if (_isGameOver) {
      return false;
    }
    if (chargeCoins && !_trySpendCoins(weaponUpgradeCost)) {
      return false;
    }
    _weaponLevel += 1;
    _publishHud(force: true);
    return true;
  }

  bool upgradeBarracks({bool chargeCoins = true}) {
    if (_isGameOver) {
      return false;
    }
    if (chargeCoins && !_trySpendCoins(barracksUpgradeCost)) {
      return false;
    }
    _barracksLevel += 1;
    _barracks.setLevel(_barracksLevel);
    _publishHud(force: true);
    return true;
  }

  bool buildWatchtower({bool chargeCoins = true}) {
    if (_isGameOver || _watchtowerBuilt) {
      return false;
    }
    if (chargeCoins && !_trySpendCoins(watchtowerBuildCost)) {
      return false;
    }

    world.add(
      WatchtowerComponent(position: _watchtowerPad.position + Vector2(0, -6)),
    );
    _watchtowerBuilt = true;
    if (_watchtowerPad.isMounted) {
      _watchtowerPad.markCompleted();
    }
    _publishHud(force: true);
    return true;
  }

  bool tryActivateNearestPad() {
    final pad = _nearestPadInRange();
    if (pad == null) {
      return false;
    }
    return switch (pad.type) {
      UpgradePadType.weapon => upgradeWeapon(),
      UpgradePadType.barracks => upgradeBarracks(),
      UpgradePadType.watchtower => buildWatchtower(),
    };
  }

  void setPlayerFacing(Vector2 direction) {
    if (direction.length2 <= 0) {
      return;
    }
    _playerFacingDirection
      ..setFrom(direction)
      ..normalize();
  }

  int claimAllyFollowSlot() {
    final slot = _allySlotCounter;
    _allySlotCounter += 1;
    return slot;
  }

  UpgradePadComponent? _nearestPadInRange() {
    if (!_weaponPad.isMounted ||
        !_barracksPad.isMounted ||
        !_watchtowerPad.isMounted) {
      return null;
    }

    UpgradePadComponent? nearest;
    var bestDistance2 = double.infinity;
    for (final pad in [_weaponPad, _barracksPad, _watchtowerPad]) {
      final distance2 = pad.position.distanceToSquared(playerPosition);
      if (distance2 <= pad.interactionRange * pad.interactionRange &&
          distance2 < bestDistance2) {
        bestDistance2 = distance2;
        nearest = pad;
      }
    }
    return nearest;
  }

  EnemyComponent? findNearestEnemy(Vector2 from, double range) {
    EnemyComponent? nearest;
    var bestDistance2 = range * range;
    for (final enemy in enemies) {
      final distance2 = enemy.position.distanceToSquared(from);
      if (distance2 <= bestDistance2) {
        bestDistance2 = distance2;
        nearest = enemy;
      }
    }
    return nearest;
  }

  AllyUnitComponent? findNearestFreeAlly(Vector2 from, double range) {
    AllyUnitComponent? nearest;
    var bestDistance2 = range * range;
    for (final ally in allies) {
      if (ally.isAssignedToTower || ally.isRemoving) {
        continue;
      }
      final distance2 = ally.position.distanceToSquared(from);
      if (distance2 <= bestDistance2) {
        bestDistance2 = distance2;
        nearest = ally;
      }
    }
    return nearest;
  }

  WatchtowerComponent? findNearestWatchtower(Vector2 from, double range) {
    WatchtowerComponent? nearest;
    var bestDistance2 = range * range;
    for (final tower in watchtowers) {
      final distance2 = tower.position.distanceToSquared(from);
      if (distance2 <= bestDistance2) {
        bestDistance2 = distance2;
        nearest = tower;
      }
    }
    return nearest;
  }

  void spawnBullet({
    required Vector2 from,
    required Vector2 direction,
    required double speed,
    required double damage,
    WatchtowerRewardBoxComponent? rewardBox,
  }) {
    final bullet = BulletComponent(
      position: from.clone(),
      velocity: direction.normalized()..scale(speed),
      damage: damage,
      rewardBox: rewardBox,
    );
    world.add(bullet);
  }

  void damageBase(double amount) {
    if (_isGameOver) {
      return;
    }
    _baseHp = (_baseHp - amount).clamp(0, _baseMaxHp).toDouble();
    _publishHud(force: true);
    if (_baseHp <= 0) {
      _onGameOver();
    }
  }

  void onEnemyKilled(
    EnemySpec spec,
    Vector2 enemyPosition, {
    WatchtowerRewardBoxComponent? rewardBox,
  }) {
    _score += spec.score;
    if (rewardBox != null && rewardBox.isMounted && !rewardBox.isRemoving) {
      rewardBox.addCoins(spec.coinDrop);
    } else {
      world.add(
        CoinComponent(
          position:
              enemyPosition +
              Vector2(
                (_random.nextDouble() - 0.5) * 24,
                (_random.nextDouble() - 0.5) * 24,
              ),
          value: spec.coinDrop,
        ),
      );
    }
    _publishHud(force: true);
  }

  void collectCoin(int value) {
    _coins += value;
    _publishHud(force: true);
  }

  bool spendCoins(int amount) {
    if (_isGameOver || amount <= 0 || _coins < amount) {
      return false;
    }
    _coins -= amount;
    _publishHud(force: true);
    return true;
  }

  bool _trySpendCoins(int cost) {
    return spendCoins(cost);
  }

  bool trySpawnAlly(Vector2 spawnPosition) {
    if (_isGameOver || allyCap == 0 || allies.length >= allyCap) {
      return false;
    }
    world.add(AllyUnitComponent(position: spawnPosition));
    return true;
  }

  void resolveAgainstBuildings(Vector2 actorPosition, double actorRadius) {
    if (!_base.isMounted || _base.isRemoving) {
      return;
    }

    for (var i = 0; i < 2; i += 1) {
      _resolveCircleVsRect(actorPosition, actorRadius, _base.collisionRect);

      if (_barracks.isMounted && !_barracks.isRemoving) {
        _resolveCircleVsRect(
          actorPosition,
          actorRadius,
          Rect.fromCenter(
            center: Offset(_barracks.position.x, _barracks.position.y),
            width: _barracks.size.x * _barracksCollisionWidthScale,
            height: _barracks.size.y * _barracksCollisionHeightScale,
          ),
        );
      }

      for (final tower in watchtowers) {
        if (!tower.isMounted || tower.isRemoving) {
          continue;
        }
        _resolveCircleVsRect(
          actorPosition,
          actorRadius,
          Rect.fromCenter(
            center: Offset(tower.position.x, tower.position.y),
            width: tower.size.x * _watchtowerCollisionWidthScale,
            height: tower.size.y * _watchtowerCollisionHeightScale,
          ),
        );
      }
    }
  }

  void _resolveCircleVsRect(
    Vector2 actorPosition,
    double actorRadius,
    Rect obstacleRect,
  ) {
    final nearestX = actorPosition.x.clamp(
      obstacleRect.left,
      obstacleRect.right,
    );
    final nearestY = actorPosition.y.clamp(
      obstacleRect.top,
      obstacleRect.bottom,
    );
    final dx = actorPosition.x - nearestX;
    final dy = actorPosition.y - nearestY;
    final distance2 = dx * dx + dy * dy;
    if (distance2 >= actorRadius * actorRadius) {
      return;
    }

    if (distance2 > 0.0001) {
      final distance = math.sqrt(distance2);
      final push = actorRadius - distance;
      actorPosition
        ..x += (dx / distance) * push
        ..y += (dy / distance) * push;
      return;
    }

    final leftGap = (actorPosition.x - obstacleRect.left).abs();
    final rightGap = (obstacleRect.right - actorPosition.x).abs();
    final topGap = (actorPosition.y - obstacleRect.top).abs();
    final bottomGap = (obstacleRect.bottom - actorPosition.y).abs();
    final minGap = math.min(
      math.min(leftGap, rightGap),
      math.min(topGap, bottomGap),
    );

    if (minGap == leftGap) {
      actorPosition.x = obstacleRect.left - actorRadius;
    } else if (minGap == rightGap) {
      actorPosition.x = obstacleRect.right + actorRadius;
    } else if (minGap == topGap) {
      actorPosition.y = obstacleRect.top - actorRadius;
    } else {
      actorPosition.y = obstacleRect.bottom + actorRadius;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _arena = ArenaComponent(size: arenaSize);
    _base = CoreBaseComponent(position: arenaSize / 2);
    _barracks = BarracksComponent(
      position: _base.position + Vector2(165, 90),
      level: _barracksLevel,
    );
    _weaponPad = UpgradePadComponent(
      type: UpgradePadType.weapon,
      position: _base.position + Vector2(-170, 92),
    );
    _barracksPad = UpgradePadComponent(
      type: UpgradePadType.barracks,
      position: _base.position + Vector2(25, 190),
    );
    _watchtowerPad = UpgradePadComponent(
      type: UpgradePadType.watchtower,
      position: _base.position + Vector2(-18, -210),
    );
    _player = PlayerComponent(
      position: _base.position + Vector2(0, -_playerToBaseDistance),
    );

    world.addAll([
      _arena,
      _base,
      _barracks,
      _weaponPad,
      _barracksPad,
      _watchtowerPad,
      _player,
    ]);

    _arena.setStage(_currentStageIndex);
    camera.follow(_player, snap: true);

    _dynamicJoystick = DynamicJoystickComponent(priority: 1000);
    camera.viewport.add(_dynamicJoystick);

    _publishHud(force: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) {
      return;
    }

    if (_isStageClear) {
      _stageClearTimer -= dt;
      if (_stageBannerTimer > 0) {
        _stageBannerTimer -= dt;
      }
      if (_stageClearTimer <= 0 && !_stageClearNotified) {
        _stageClearNotified = true;
        pauseEngine();
        onStageCleared?.call(_stageClearStars);
      }
      return;
    }

    _updateStage(dt);
    _spawnFromStage(dt);
    _checkStageClearCondition();

    if (_stageBannerTimer > 0) {
      _stageBannerTimer -= dt;
    }

    _hudRefreshTimer += dt;
    if (_hudRefreshTimer >= 0.12) {
      _hudRefreshTimer = 0;
      _publishHud();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keyboardInput
      ..setValues(0, 0)
      ..x +=
          keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
              keysPressed.contains(LogicalKeyboardKey.keyD)
          ? 1
          : 0
      ..x +=
          keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
              keysPressed.contains(LogicalKeyboardKey.keyA)
          ? -1
          : 0
      ..y +=
          keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
              keysPressed.contains(LogicalKeyboardKey.keyS)
          ? 1
          : 0
      ..y +=
          keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
              keysPressed.contains(LogicalKeyboardKey.keyW)
          ? -1
          : 0;

    return KeyEventResult.handled;
  }

  void registerEnemy(EnemyComponent enemy) {
    enemies.add(enemy);
  }

  void unregisterEnemy(EnemyComponent enemy) {
    enemies.remove(enemy);
  }

  void registerBullet(BulletComponent bullet) {
    bullets.add(bullet);
  }

  void unregisterBullet(BulletComponent bullet) {
    bullets.remove(bullet);
  }

  void registerCoin(CoinComponent coin) {
    droppedCoins.add(coin);
  }

  void unregisterCoin(CoinComponent coin) {
    droppedCoins.remove(coin);
  }

  void registerAlly(AllyUnitComponent ally) {
    allies.add(ally);
    _publishHud(force: true);
  }

  void unregisterAlly(AllyUnitComponent ally) {
    allies.remove(ally);
    _publishHud(force: true);
  }

  void registerWatchtower(WatchtowerComponent tower) {
    watchtowers.add(tower);
    _watchtowerBuilt = true;
    _publishHud(force: true);
  }

  void unregisterWatchtower(WatchtowerComponent tower) {
    watchtowers.remove(tower);
    if (watchtowers.isEmpty) {
      _watchtowerBuilt = false;
    }
    _publishHud(force: true);
  }

  void onWatchtowerDestroyed(WatchtowerComponent tower) {
    if (tower.isRemoving) {
      return;
    }
    _watchtowerBuilt = false;
    _watchtowerPad.resetProgress();
    tower.removeFromParent();
    _publishHud(force: true);
  }

  void resetGame() {
    for (final enemy in enemies.toList(growable: false)) {
      enemy.removeFromParent();
    }
    for (final bullet in bullets.toList(growable: false)) {
      bullet.removeFromParent();
    }
    for (final coin in droppedCoins.toList(growable: false)) {
      coin.removeFromParent();
    }
    for (final ally in allies.toList(growable: false)) {
      ally.removeFromParent();
    }
    for (final tower in watchtowers.toList(growable: false)) {
      tower.removeFromParent();
    }

    _baseHp = _baseMaxHp;
    _score = 0;
    _coins = _startingCoins;
    _weaponLevel = _startingWeaponLevel;
    _barracksLevel = 0;
    _watchtowerBuilt = false;
    _allySlotCounter = 0;
    _playerFacingDirection.setValues(0, -1);
    _currentStageIndex = _selectedStartStageIndex;
    _currentPhaseIndex = 0;
    _stageElapsed = 0;
    _spawnBudget = 0;
    _stageBannerTimer = _stageBannerDuration;
    _isGameOver = false;
    _spawnEnabled = true;
    _isStageClear = false;
    _stageClearNotified = false;
    _stageClearTimer = 0;
    _stageClearStars = 0;
    _hellBossSpawned = false;

    _player.position = _base.position + Vector2(0, -_playerToBaseDistance);
    _barracks.setLevel(_barracksLevel);
    _weaponPad.resetProgress();
    _barracksPad.resetProgress();
    _watchtowerPad.resetProgress();
    _arena.setStage(_currentStageIndex);
    camera.follow(_player, snap: true);

    overlays.remove(gameOverOverlayId);
    resumeEngine();
    _publishHud(force: true);
  }

  void _updateStage(double dt) {
    if (!_spawnEnabled) {
      return;
    }

    final phase = currentPhase;
    if (phase.duration <= 0) {
      return;
    }

    _stageElapsed += dt;
    if (_stageElapsed < phase.duration) {
      return;
    }

    _stageElapsed = 0;
    if (!isLastPhase) {
      _currentPhaseIndex += 1;
      if (currentStage.difficulty == StageDifficulty.hell &&
          isLastPhase &&
          !_hellBossSpawned) {
        _spawnHellBoss();
      }
      _stageBannerTimer = _stageBannerDuration;
      _publishHud(force: true);
      return;
    }

    _spawnEnabled = false;
    _spawnBudget = 0;
    _publishHud(force: true);
  }

  void _spawnFromStage(double dt) {
    if (!_spawnEnabled) {
      return;
    }
    _spawnBudget +=
        currentPhase.spawnPerSecond * currentStage.spawnRateMultiplier * dt;
    while (_spawnBudget >= 1) {
      _spawnBudget -= 1;
      _spawnEnemy(currentPhase.pickEnemy(_random));
    }
  }

  void _checkStageClearCondition() {
    if (_isStageClear || _isGameOver || _spawnEnabled || enemies.isNotEmpty) {
      return;
    }
    _onStageClear();
  }

  void _spawnEnemy(EnemyType type) {
    final spawnPosition = _randomSpawnPosition();
    final baseSpec = enemySpecs[type]!;
    world.add(
      EnemyComponent(
        position: spawnPosition,
        type: type,
        spec: _scaledSpecForStage(baseSpec),
      ),
    );
  }

  void _spawnHellBoss() {
    if (_hellBossSpawned) {
      return;
    }
    _hellBossSpawned = true;
    _spawnEnemy(EnemyType.boss);
  }

  EnemySpec _scaledSpecForStage(EnemySpec base) {
    final stage = currentStage;
    return EnemySpec(
      label: base.label,
      radius: base.radius,
      maxHp: base.maxHp * stage.enemyHpMultiplier,
      speed: base.speed,
      baseDamagePerSecond:
          base.baseDamagePerSecond * stage.enemyDamageMultiplier,
      color: base.color,
      score: math.max(1, (base.score * stage.rewardMultiplier).round()),
      coinDrop: math.max(1, (base.coinDrop * stage.rewardMultiplier).round()),
    );
  }

  Vector2 _randomSpawnPosition() {
    const margin = 40.0;
    final side = _random.nextInt(4);
    final x = _random.nextDouble() * arenaSize.x;
    final y = _random.nextDouble() * arenaSize.y;
    switch (side) {
      case 0:
        return Vector2(x, -margin);
      case 1:
        return Vector2(arenaSize.x + margin, y);
      case 2:
        return Vector2(x, arenaSize.y + margin);
      default:
        return Vector2(-margin, y);
    }
  }

  EnemyComponent? _activeBoss() {
    for (final enemy in enemies) {
      if (enemy.type == EnemyType.boss && !enemy.isRemoving) {
        return enemy;
      }
    }
    return null;
  }

  void _publishHud({bool force = false}) {
    final stage = currentStage;
    final phase = currentPhase;
    final boss = _activeBoss();
    final nextStageSeconds = !_spawnEnabled
        ? null
        : (phase.duration - _stageElapsed).clamp(0, phase.duration).toDouble();
    final stageBanner = _isStageClear
        ? 'STAGE CLEAR'
        : (_stageBannerTimer > 0 ? '${stage.name}  ${phase.name}' : null);

    if (!force && _hudRefreshTimer > 0) {
      return;
    }

    hud.value = HudModel(
      baseHp: _baseHp,
      baseMaxHp: _baseMaxHp,
      stageIndex: _currentStageIndex + 1,
      stageName: '${stage.name}  ${phase.name}',
      score: _score,
      coins: _coins,
      weaponLevel: _weaponLevel,
      weaponUpgradeCost: weaponUpgradeCost,
      barracksLevel: _barracksLevel,
      barracksUpgradeCost: barracksUpgradeCost,
      watchtowerCount: watchtowers.length,
      watchtowerBuildCost: watchtowerBuildCost,
      allyCount: allies.length,
      allyCap: allyCap,
      garrisonedAllyCount: garrisonedAllyCount,
      garrisonedAllyCap: garrisonedAllyCap,
      nearbyActionLabel: null,
      nearbyActionCost: null,
      nearbyActionAffordable: false,
      nextStageSeconds: nextStageSeconds,
      stageBanner: stageBanner,
      bossHp: boss?.hp,
      bossMaxHp: boss?.maxHp,
      isGameOver: _isGameOver,
    );
  }

  void _onGameOver() {
    _isGameOver = true;
    pauseEngine();
    overlays.add(gameOverOverlayId);
    _publishHud(force: true);
  }

  void _onStageClear() {
    _stageClearStars = _calculateClearStars();
    _isStageClear = true;
    _stageClearTimer = _stageClearDelay;
    _stageBannerTimer = _stageClearDelay;
    _publishHud(force: true);
  }

  int _calculateClearStars() {
    final hpRatio = (_baseHp / _baseMaxHp).clamp(0.0, 1.0);
    if (hpRatio >= 0.7) {
      return 3;
    }
    if (hpRatio >= 0.35) {
      return 2;
    }
    return 1;
  }
}

class ArenaComponent extends PositionComponent {
  ArenaComponent({required super.size});

  static const _groundColors = [
    Color(0xFF80A96D),
    Color(0xFF7FAA79),
    Color(0xFF7AA38A),
    Color(0xFF76929D),
  ];

  int _stageIndex = 0;

  void setStage(int stageIndex) {
    _stageIndex = stageIndex.clamp(0, _groundColors.length - 1).toInt();
  }

  @override
  void render(Canvas canvas) {
    final ground = Paint()..color = _groundColors[_stageIndex];
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), ground);

    final pathPaint = Paint()..color = const Color(0xFFCBDEB7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.08,
          size.y * 0.12,
          size.x * 0.84,
          size.y * 0.18,
        ),
        const Radius.circular(44),
      ),
      pathPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.12,
          size.y * 0.42,
          size.x * 0.76,
          size.y * 0.18,
        ),
        const Radius.circular(44),
      ),
      pathPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.09,
          size.y * 0.72,
          size.x * 0.82,
          size.y * 0.18,
        ),
        const Radius.circular(44),
      ),
      pathPaint,
    );
  }
}

class CoreBaseComponent extends RectangleComponent
    with HasGameReference<BaseDefenseGame> {
  static const double _collisionWidthScale = 0.82;
  static const double _collisionHeightScale = 0.72;

  CoreBaseComponent({required Vector2 position})
    : super(
        size: Vector2(126, 102),
        position: position,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF2E63D9),
      );

  Rect get collisionRect => Rect.fromCenter(
    center: Offset(position.x, position.y),
    width: size.x * _collisionWidthScale,
    height: size.y * _collisionHeightScale,
  );

  bool overlapsCircle(Vector2 circleCenter, double circleRadius) {
    final rect = collisionRect;
    final nearestX = circleCenter.x.clamp(rect.left, rect.right).toDouble();
    final nearestY = circleCenter.y.clamp(rect.top, rect.bottom).toDouble();
    final dx = circleCenter.x - nearestX;
    final dy = circleCenter.y - nearestY;
    return (dx * dx) + (dy * dy) <= circleRadius * circleRadius;
  }

  @override
  void render(Canvas canvas) {
    final baseRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final baseRRect = RRect.fromRectAndRadius(
      baseRect,
      const Radius.circular(20),
    );
    canvas.drawRRect(baseRRect, paint);

    final roofPaint = Paint()..color = const Color(0xFF1E4275);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.12,
          size.y * 0.12,
          size.x * 0.76,
          size.y * 0.28,
        ),
        const Radius.circular(11),
      ),
      roofPaint,
    );
    final corePaint = Paint()..color = const Color(0xFF7FD9FF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.38,
          size.y * 0.42,
          size.x * 0.24,
          size.y * 0.25,
        ),
        const Radius.circular(8),
      ),
      corePaint,
    );

    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = const Color(0xAA95C3FF);
    canvas.drawRRect(baseRRect, frame);

    final hpRatio = (game.baseHp / game.baseMaxHp).clamp(0.0, 1.0);
    final hpBg = Paint()..color = const Color(0x99421717);
    final hpFill = Paint()..color = const Color(0xFF35C86B);
    final barWidth = size.x - 16;
    const barHeight = 7.0;
    const barY = -14.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((size.x - barWidth) / 2, barY, barWidth, barHeight),
        const Radius.circular(99),
      ),
      hpBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (size.x - barWidth) / 2,
          barY,
          barWidth * hpRatio,
          barHeight,
        ),
        const Radius.circular(99),
      ),
      hpFill,
    );
  }
}

class DynamicJoystickComponent extends PositionComponent
    with
        HasGameReference<BaseDefenseGame>,
        DragCallbacks,
        TapCallbacks,
        HasVisibility {
  DynamicJoystickComponent({super.priority}) : super(anchor: Anchor.topLeft);

  static const double _radius = 54;
  static const double _knobRadius = 24;

  final Vector2 input = Vector2.zero();

  late final CircleComponent _background;
  late final CircleComponent _knob;

  int? _activePointerId;
  final Vector2 _center = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size.clone();
    isVisible = false;

    _background = CircleComponent(
      radius: _radius,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0x66495E6F),
    );
    _knob = CircleComponent(
      radius: _knobRadius,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xAAE6EDF2),
    );
    addAll([_background, _knob]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapDown(TapDownEvent event) {
    _activePointerId = event.pointerId;
    _center.setFrom(event.localPosition);
    _applyDragPosition(event.localPosition);
    isVisible = true;
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    if (_activePointerId == event.pointerId) {
      _applyDragPosition(event.localPosition);
      isVisible = true;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_activePointerId == event.pointerId) {
      _reset();
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (_activePointerId == event.pointerId) {
      _reset();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_activePointerId != null && _activePointerId != event.pointerId) {
      return;
    }
    _activePointerId = event.pointerId;
    if (!isVisible) {
      _center.setFrom(event.localPosition);
      isVisible = true;
    }
    _applyDragPosition(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_activePointerId != event.pointerId) {
      return;
    }
    _applyDragPosition(event.localStartPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (_activePointerId == event.pointerId) {
      _reset();
    }
    super.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (_activePointerId == event.pointerId) {
      _reset();
    }
    super.onDragCancel(event);
  }

  void _applyDragPosition(Vector2 localPosition) {
    final delta = localPosition - _center;
    if (delta.length2 > _radius * _radius) {
      delta.scaleTo(_radius);
    }

    input
      ..setFrom(delta)
      ..scale(1 / _radius);

    _background.position = _center;
    _knob.position = _center + delta;
  }

  void _reset() {
    _activePointerId = null;
    input.setZero();
    isVisible = false;
  }
}

class UpgradePadComponent extends RectangleComponent
    with HasGameReference<BaseDefenseGame> {
  UpgradePadComponent({required this.type, required Vector2 position})
    : super(
        position: position,
        size: Vector2.all(88),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xAA2A3948),
      );

  static final _titlePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFE7F1FF),
      fontSize: 12,
      fontWeight: FontWeight.w800,
    ),
  );
  static final _costAffordablePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFE79A),
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );
  static final _costBlockedPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFE4A7A7),
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );

  final UpgradePadType type;
  static const double _interactionRange = 96;
  double get interactionRange => _interactionRange;
  static const double _coinTickInterval = 0.05;

  late final TextComponent<TextPaint> _titleText;
  late final TextComponent<TextPaint> _costText;

  double _refreshTimer = 0;
  double _coinTickTimer = 0;
  int _targetCost = 1;
  int _paid = 0;
  bool _completed = false;

  double get _progress =>
      _completed ? 1 : (_targetCost <= 0 ? 0 : _paid / _targetCost);
  int get _remainingCost =>
      _completed ? 0 : (_targetCost - _paid).clamp(0, _targetCost);

  void resetProgress() {
    _targetCost = math.max(1, game.costForPad(type));
    _paid = 0;
    _completed = false;
    _coinTickTimer = 0;
  }

  void markCompleted() {
    _completed = true;
    _targetCost = 1;
    _paid = 1;
    _coinTickTimer = 0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    resetProgress();

    _titleText = TextComponent<TextPaint>(
      text: '',
      textRenderer: _titlePaint,
      position: Vector2(0, -16),
      anchor: Anchor.center,
    );
    _costText = TextComponent<TextPaint>(
      text: '',
      textRenderer: _costAffordablePaint,
      position: Vector2(0, 14),
      anchor: Anchor.center,
    );
    addAll([_titleText, _costText]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _handleCoinPayment(dt);

    _refreshTimer += dt;
    if (_refreshTimer < 0.08) {
      return;
    }
    _refreshTimer = 0;

    final level = game.levelForPad(type);
    final remainingCost = _remainingCost;
    final affordable = !_completed && game.coins > 0;
    final onPad = _isPlayerTouchingPad();

    _titleText.text = switch (type) {
      UpgradePadType.weapon => '${game.labelForPad(type)} Lv.$level',
      UpgradePadType.barracks => '${game.labelForPad(type)} Lv.$level',
      UpgradePadType.watchtower => _completed ? 'Watchtower' : 'Tower Site',
    };
    _costText
      ..text = _completed ? 'BUILT' : '$remainingCost C'
      ..textRenderer = affordable ? _costAffordablePaint : _costBlockedPaint;

    paint.color = _completed
        ? const Color(0xCC426C7F)
        : onPad
        ? (affordable ? const Color(0xCC3A8D66) : const Color(0xCC8B4F57))
        : const Color(0xAA2A3948);
  }

  @override
  void render(Canvas canvas) {
    final frameRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final frameRRect = RRect.fromRectAndRadius(
      frameRect,
      const Radius.circular(10),
    );
    canvas.drawRRect(frameRRect, paint);

    if (_progress > 0) {
      final fillHeight = size.y * _progress;
      final fillRect = Rect.fromLTWH(
        0,
        size.y - fillHeight,
        size.x,
        fillHeight,
      );
      final fillPaint = Paint()..color = const Color(0x663CB56F);
      canvas.save();
      canvas.clipRRect(frameRRect);
      canvas.drawRect(fillRect, fillPaint);
      canvas.restore();
    }

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xDDEAF5FF);
    canvas.drawRRect(frameRRect, framePaint);

    final barBg = Paint()..color = const Color(0x99374756);
    final barFill = Paint()..color = const Color(0xFF34C06C);
    final barY = size.y - 11;
    final barWidth = size.x - 12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, barY, barWidth, 6),
        const Radius.circular(99),
      ),
      barBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, barY, barWidth * _progress, 6),
        const Radius.circular(99),
      ),
      barFill,
    );
  }

  bool _isPlayerTouchingPad() {
    final player = game.playerPosition;
    final left = position.x - size.x / 2;
    final right = position.x + size.x / 2;
    final top = position.y - size.y / 2;
    final bottom = position.y + size.y / 2;

    final closestX = player.x.clamp(left, right).toDouble();
    final closestY = player.y.clamp(top, bottom).toDouble();
    final dx = player.x - closestX;
    final dy = player.y - closestY;
    return (dx * dx) + (dy * dy) <= game.playerRadius * game.playerRadius;
  }

  void _handleCoinPayment(double dt) {
    if (game.isGameOver ||
        _completed ||
        !_isPlayerTouchingPad() ||
        _remainingCost <= 0) {
      _coinTickTimer = 0;
      return;
    }

    _coinTickTimer += dt;
    while (_coinTickTimer >= _coinTickInterval && _remainingCost > 0) {
      _coinTickTimer -= _coinTickInterval;
      if (!game.spendCoins(1)) {
        break;
      }
      _paid += 1;

      if (_remainingCost <= 0) {
        final upgraded = switch (type) {
          UpgradePadType.weapon => game.upgradeWeapon(chargeCoins: false),
          UpgradePadType.barracks => game.upgradeBarracks(chargeCoins: false),
          UpgradePadType.watchtower => game.buildWatchtower(chargeCoins: false),
        };
        if (upgraded) {
          if (type == UpgradePadType.watchtower) {
            markCompleted();
          } else {
            resetProgress();
          }
        }
        break;
      }
    }
  }
}

class BarracksComponent extends RectangleComponent
    with HasGameReference<BaseDefenseGame> {
  BarracksComponent({required Vector2 position, required int level})
    : _level = level,
      super(
        position: position,
        size: Vector2(104, 78),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF6E5D4A),
      );

  static final _labelPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFF4ECDD),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );

  int _level;
  double _spawnTimer = 1.8;

  late final TextComponent<TextPaint> _label;

  double get _spawnInterval => math.max(1.2, 5.8 - _level * 0.85);

  void setLevel(int value) {
    final previous = _level;
    _level = value;
    if (previous == 0 && _level > 0) {
      _spawnTimer = 0.8;
    } else {
      _spawnTimer = math.min(_spawnTimer, _spawnInterval);
    }
    if (isMounted) {
      _syncLabel();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _label = TextComponent<TextPaint>(
      text: '',
      textRenderer: _labelPaint,
      position: Vector2(0, -56),
      anchor: Anchor.center,
    );
    add(_label);
    _syncLabel();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_level == 0 || game.isGameOver) {
      return;
    }

    _spawnTimer -= dt;
    if (_spawnTimer > 0) {
      return;
    }

    _spawnTimer += _spawnInterval;
    final spawnPosition =
        position +
        Vector2(
          (game._random.nextDouble() - 0.5) * 44,
          58 + game._random.nextDouble() * 18,
        );
    game.trySpawnAlly(spawnPosition);
  }

  void _syncLabel() {
    _label.text = _level == 0 ? 'Barracks Locked' : 'Barracks Lv.$_level';
    paint.color = _level == 0
        ? const Color(0xFF4F4A44)
        : const Color(0xFF6E5D4A);
  }
}

class WatchtowerComponent extends RectangleComponent
    with HasGameReference<BaseDefenseGame> {
  WatchtowerComponent({required Vector2 position})
    : _hp = _maxHp,
      super(
        position: position,
        size: Vector2(62, 74),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF7E5F42),
      );

  static const double _maxHp = 360;
  static const double _attackRange = 320;
  static const double _fireCooldown = 0.46;
  static const double _bulletSpeed = 710;
  static const double _bulletDamage = 36;
  static const int garrisonCapacity = 4;
  static const double _deployRange = 118;
  static const double _deploySearchRange = 240;
  static const double _deployInterval = 0.2;
  static const double _garrisonRadius = 58;
  static final Vector2 _rewardBoxOffset = Vector2(52, 30);

  double _hp;
  double _shotCooldown = 0;
  double _deployTimer = 0;
  final Map<AllyUnitComponent, int> _assignedSlots = {};
  WatchtowerRewardBoxComponent? _rewardBox;

  double get hitRadius => size.y * 0.35;
  int get garrisonCount => _assignedSlots.length;
  WatchtowerRewardBoxComponent? get rewardBox => _rewardBox;

  @override
  void onMount() {
    super.onMount();
    _rewardBox = WatchtowerRewardBoxComponent(
      position: position + _rewardBoxOffset,
    );
    game.world.add(_rewardBox!);
    game.registerWatchtower(this);
  }

  @override
  void onRemove() {
    final rewardBox = _rewardBox;
    if (rewardBox != null && rewardBox.isMounted && !rewardBox.isRemoving) {
      rewardBox.removeFromParent();
    }
    _releaseAllGarrisoned();
    game.unregisterWatchtower(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _pruneAssignments();
    _autoAssignNearbyAllies(dt);

    _shotCooldown -= dt;
    if (_shotCooldown > 0) {
      return;
    }

    final target = game.findNearestEnemy(position, _attackRange);
    if (target == null) {
      return;
    }

    final direction = target.position - position;
    if (direction.length2 == 0) {
      return;
    }
    direction.normalize();

    game.spawnBullet(
      from: position + direction * (hitRadius + 5),
      direction: direction,
      speed: _bulletSpeed,
      damage: _bulletDamage,
      rewardBox: _rewardBox,
    );
    _shotCooldown = _fireCooldown;
  }

  Vector2 garrisonPointForSlot(int slot) {
    final angle = (-math.pi / 2) + (slot * (2 * math.pi / garrisonCapacity));
    return position +
        Vector2(math.cos(angle), math.sin(angle)) * _garrisonRadius;
  }

  bool assignAlly(AllyUnitComponent ally) {
    if (isRemoving ||
        _assignedSlots.length >= garrisonCapacity ||
        _assignedSlots.containsKey(ally)) {
      return false;
    }
    final slot = _nextOpenSlot();
    if (slot == null) {
      return false;
    }
    _assignedSlots[ally] = slot;
    ally.assignToTower(this, slot);
    return true;
  }

  void unassignAlly(AllyUnitComponent ally, {bool notifyAlly = true}) {
    final removed = _assignedSlots.remove(ally);
    if (removed == null) {
      return;
    }
    if (notifyAlly) {
      ally.clearTowerAssignment(notifyTower: false);
    }
  }

  void receiveDamage(double amount) {
    if (isRemoving) {
      return;
    }
    _hp = (_hp - amount).clamp(0, _maxHp).toDouble();
    if (_hp <= 0) {
      game.onWatchtowerDestroyed(this);
    }
  }

  int? _nextOpenSlot() {
    for (var i = 0; i < garrisonCapacity; i += 1) {
      if (!_assignedSlots.values.contains(i)) {
        return i;
      }
    }
    return null;
  }

  void _pruneAssignments() {
    final stale = <AllyUnitComponent>[];
    _assignedSlots.forEach((ally, _) {
      if (!ally.isMounted || ally.isRemoving || ally.assignedTower != this) {
        stale.add(ally);
      }
    });
    for (final ally in stale) {
      _assignedSlots.remove(ally);
    }
  }

  void _autoAssignNearbyAllies(double dt) {
    if (game.isGameOver || _assignedSlots.length >= garrisonCapacity) {
      _deployTimer = 0;
      return;
    }

    final playerDistance2 = position.distanceToSquared(game.playerPosition);
    if (playerDistance2 > _deployRange * _deployRange) {
      _deployTimer = 0;
      return;
    }

    _deployTimer += dt;
    while (_deployTimer >= _deployInterval &&
        _assignedSlots.length < garrisonCapacity) {
      _deployTimer -= _deployInterval;
      final ally = game.findNearestFreeAlly(
        game.playerPosition,
        _deploySearchRange,
      );
      if (ally == null) {
        _deployTimer = 0;
        break;
      }
      assignAlly(ally);
    }
  }

  void _releaseAllGarrisoned() {
    final assigned = _assignedSlots.keys.toList(growable: false);
    _assignedSlots.clear();
    for (final ally in assigned) {
      if (!ally.isRemoving && ally.isMounted) {
        ally.clearTowerAssignment(notifyTower: false);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final deck = Paint()..color = const Color(0xFF5A432F);
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.23, size.y * 0.1, size.x * 0.54, size.y * 0.52),
      deck,
    );
    final turret = Paint()..color = const Color(0xFFB8CAD8);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.32), 11, turret);

    final hpRatio = (_hp / _maxHp).clamp(0.0, 1.0);
    final hpBg = Paint()..color = const Color(0x99421717);
    final hpFill = Paint()..color = const Color(0xFF35C86B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, -11, size.x - 12, 5),
        const Radius.circular(99),
      ),
      hpBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, -11, (size.x - 12) * hpRatio, 5),
        const Radius.circular(99),
      ),
      hpFill,
    );
  }
}

class WatchtowerRewardBoxComponent extends RectangleComponent
    with HasGameReference<BaseDefenseGame> {
  WatchtowerRewardBoxComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2.all(34),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xCC2C3A46),
      );

  static const double _collectRange = 70;
  static const double _collectTickInterval = 0.01;
  static final _amountPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFE08A),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
  );

  late final TextComponent<TextPaint> _amountText;
  int _storedCoins = 0;
  double _collectTickTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _amountText = TextComponent<TextPaint>(
      text: '',
      textRenderer: _amountPaint,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(_amountText);
    _syncLabel();
  }

  void addCoins(int amount) {
    if (amount <= 0 || isRemoving) {
      return;
    }
    _storedCoins += amount;
    _syncLabel();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_storedCoins <= 0 || game.isGameOver) {
      _collectTickTimer = 0;
      return;
    }
    final isInCollectRange =
        position.distanceToSquared(game.playerPosition) <=
        _collectRange * _collectRange;
    if (!isInCollectRange) {
      _collectTickTimer = 0;
      return;
    }

    _collectTickTimer += dt;
    final payoutCount = math.min(
      _storedCoins,
      (_collectTickTimer / _collectTickInterval).floor(),
    );
    if (payoutCount > 0) {
      _collectTickTimer -= payoutCount * _collectTickInterval;
      _storedCoins -= payoutCount;
      game.collectCoin(payoutCount);
      _syncLabel();
    }
  }

  void _syncLabel() {
    _amountText.text = _storedCoins > 0 ? '$_storedCoins' : '';
    paint.color = _storedCoins > 0
        ? const Color(0xCC3C4F5F)
        : const Color(0xAA26343F);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, paint);

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xE8ECF5FF);
    canvas.drawRRect(rrect, framePaint);

    if (_storedCoins > 0) {
      final coinPaint = Paint()..color = const Color(0xFFFFCA4A);
      canvas.drawCircle(Offset(size.x * 0.2, size.y * 0.5), 4.8, coinPaint);
    }
  }
}

class AllyUnitComponent extends CircleComponent
    with HasGameReference<BaseDefenseGame> {
  AllyUnitComponent({required Vector2 position})
    : super(
        radius: 12,
        position: position,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF79D3FF),
      );

  static const double _moveSpeed = 185;
  static const double _attackRange = 230;
  static const double _fireCooldown = 0.7;
  static const double _bulletSpeed = 540;
  static const double _bulletDamage = 18;
  static const double _maxChaseFromPlayer = 280;
  static const double _towerGuardRange = 250;
  static const double _towerGuardMoveSpeed = 205;
  static const int _rowSize = 3;
  static const double _rowSpacing = 26;
  static const double _colSpacing = 24;
  static const double _baseBehindDistance = 64;

  late final int _followSlot;
  double _shotCooldown = 0;
  WatchtowerComponent? _assignedTower;
  int? _towerSlot;

  bool get isAssignedToTower => _assignedTower != null;
  WatchtowerComponent? get assignedTower => _assignedTower;

  @override
  void onMount() {
    super.onMount();
    _followSlot = game.claimAllyFollowSlot();
    game.registerAlly(this);
  }

  @override
  void onRemove() {
    clearTowerAssignment();
    game.unregisterAlly(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_assignedTower != null) {
      _updateAsTowerGuard(dt);
      return;
    }
    _updateAsFollower(dt);
  }

  void assignToTower(WatchtowerComponent tower, int slot) {
    if (_assignedTower == tower && _towerSlot == slot) {
      return;
    }
    if (_assignedTower != null && _assignedTower != tower) {
      _assignedTower!.unassignAlly(this, notifyAlly: false);
    }
    _assignedTower = tower;
    _towerSlot = slot;
  }

  void clearTowerAssignment({bool notifyTower = true}) {
    final tower = _assignedTower;
    _assignedTower = null;
    _towerSlot = null;
    if (notifyTower && tower != null) {
      tower.unassignAlly(this, notifyAlly: false);
    }
  }

  void _updateAsFollower(double dt) {
    _shotCooldown -= dt;
    final target = game.findNearestEnemy(position, _attackRange);
    if (target == null) {
      _moveToFollowPoint(dt);
      return;
    }

    final playerDistance2 = position.distanceToSquared(game.playerPosition);
    if (playerDistance2 > _maxChaseFromPlayer * _maxChaseFromPlayer) {
      _moveToFollowPoint(dt);
      return;
    }

    final toEnemy = target.position - position;
    final distance = toEnemy.length;
    if (distance > 95) {
      toEnemy.normalize();
      position.add(toEnemy..scale(_moveSpeed * dt));
    }

    if (_shotCooldown <= 0) {
      final direction = target.position - position;
      if (direction.length2 > 0) {
        direction.normalize();
        game.spawnBullet(
          from: position + direction * (radius + 7),
          direction: direction,
          speed: _bulletSpeed,
          damage: _bulletDamage,
        );
        _shotCooldown = _fireCooldown;
      }
    }

    _clampToArena();
  }

  void _updateAsTowerGuard(double dt) {
    final tower = _assignedTower;
    final slot = _towerSlot;
    if (tower == null || slot == null || !tower.isMounted || tower.isRemoving) {
      clearTowerAssignment(notifyTower: false);
      _updateAsFollower(dt);
      return;
    }

    _shotCooldown -= dt;

    final guardPoint = tower.garrisonPointForSlot(slot);
    final toPoint = guardPoint - position;
    if (toPoint.length2 > 16) {
      final moveSpeed = toPoint.length > 55
          ? _towerGuardMoveSpeed
          : _moveSpeed * 0.72;
      toPoint.normalize();
      position.add(toPoint..scale(moveSpeed * dt));
    }

    if (_shotCooldown <= 0) {
      final target = game.findNearestEnemy(position, _towerGuardRange);
      if (target != null) {
        final direction = target.position - position;
        if (direction.length2 > 0) {
          direction.normalize();
          game.spawnBullet(
            from: position + direction * (radius + 7),
            direction: direction,
            speed: _bulletSpeed,
            damage: _bulletDamage,
            rewardBox: tower.rewardBox,
          );
          _shotCooldown = _fireCooldown;
        }
      }
    }

    _clampToArena();
  }

  void _moveToFollowPoint(double dt) {
    final facing = game.playerFacingDirection;
    final right = Vector2(-facing.y, facing.x);

    final row = _followSlot ~/ _rowSize;
    final col = _followSlot % _rowSize;
    final lateralOffset = (col - ((_rowSize - 1) / 2)) * _colSpacing;
    final backOffset = _baseBehindDistance + row * _rowSpacing;

    final followPoint =
        game.playerPosition - facing * backOffset + right * lateralOffset;
    final toFollow = followPoint - position;
    if (toFollow.length2 > 16) {
      final followSpeed = toFollow.length > 120
          ? _moveSpeed * 1.15
          : _moveSpeed * 0.8;
      toFollow.normalize();
      position.add(toFollow..scale(followSpeed * dt));
    }
    _clampToArena();
  }

  void _clampToArena() {
    game.resolveAgainstBuildings(position, radius);
    position.x = position.x.clamp(radius, game.arenaSize.x - radius).toDouble();
    position.y = position.y.clamp(radius, game.arenaSize.y - radius).toDouble();
    game.resolveAgainstBuildings(position, radius);
    position.x = position.x.clamp(radius, game.arenaSize.x - radius).toDouble();
    position.y = position.y.clamp(radius, game.arenaSize.y - radius).toDouble();
  }
}

class PlayerComponent extends CircleComponent
    with HasGameReference<BaseDefenseGame> {
  PlayerComponent({required Vector2 position})
    : super(
        radius: 18,
        position: position,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFF5B11F),
      );

  static const double _moveSpeed = 220;
  static const double _bulletSpeed = 600;

  double _shotCooldown = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _move(dt);
    _shoot(dt);
  }

  void _move(double dt) {
    final input = game.readMovementInput();
    if (input.length2 > 0) {
      game.setPlayerFacing(input);
      position.add(input * (_moveSpeed * dt));
    }

    game.resolveAgainstBuildings(position, radius);
    position.x = position.x.clamp(radius, game.arenaSize.x - radius).toDouble();
    position.y = position.y.clamp(radius, game.arenaSize.y - radius).toDouble();
  }

  void _shoot(double dt) {
    _shotCooldown -= dt;
    if (_shotCooldown > 0) {
      return;
    }

    final target = game.findNearestEnemy(position, game.playerAttackRange);
    if (target == null) {
      return;
    }

    final direction = target.position - position;
    if (direction.length2 == 0) {
      return;
    }
    direction.normalize();

    game.spawnBullet(
      from: position + direction * (radius + 8),
      direction: direction,
      speed: _bulletSpeed,
      damage: game.playerBulletDamage,
    );
    _shotCooldown = game.playerFireCooldown;
  }
}

class EnemyComponent extends CircleComponent
    with HasGameReference<BaseDefenseGame> {
  EnemyComponent({
    required Vector2 position,
    required this.type,
    required this.spec,
  }) : _hp = spec.maxHp,
       super(
         radius: spec.radius,
         position: position,
         anchor: Anchor.center,
         paint: Paint()..color = spec.color,
       );

  final EnemyType type;
  final EnemySpec spec;
  double _hp;
  double get hp => _hp;
  double get maxHp => spec.maxHp;
  bool get _showHpBar =>
      type == EnemyType.brute ||
      type == EnemyType.elite ||
      type == EnemyType.boss;

  @override
  void onMount() {
    super.onMount();
    game.registerEnemy(this);
  }

  @override
  void onRemove() {
    game.unregisterEnemy(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    var targetPosition = game._base.position;
    WatchtowerComponent? targetTower;

    final nearbyTower = game.findNearestWatchtower(position, 420);
    if (nearbyTower != null) {
      final towerDistance2 = position.distanceToSquared(nearbyTower.position);
      final baseDistance2 = position.distanceToSquared(game._base.position);
      if (towerDistance2 <= baseDistance2 * 1.08) {
        targetTower = nearbyTower;
        targetPosition = nearbyTower.position;
      }
    }

    final toTarget = targetPosition - position;
    if (toTarget.length2 > 0) {
      toTarget.normalize();
      position.add(toTarget..scale(spec.speed * dt));
    }
    game.resolveAgainstBuildings(position, radius);

    final canAttack = switch (targetTower) {
      WatchtowerComponent tower =>
        position.distanceToSquared(targetPosition) <=
            (radius + tower.hitRadius + 2) * (radius + tower.hitRadius + 2),
      null => game._base.overlapsCircle(position, radius + 2),
    };
    if (canAttack) {
      if (targetTower != null) {
        targetTower.receiveDamage(spec.baseDamagePerSecond * dt);
      } else {
        game.damageBase(spec.baseDamagePerSecond * dt);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_showHpBar) {
      return;
    }

    final hpRatio = (_hp / maxHp).clamp(0.0, 1.0);
    final barWidth = radius * 2;
    final barHeight = type == EnemyType.boss ? 7.0 : 5.0;
    final barY = -radius - (type == EnemyType.boss ? 18 : 12);

    final hpBg = Paint()..color = const Color(0x993B1414);
    final hpFill = Paint()
      ..color = type == EnemyType.boss
          ? const Color(0xFFE34877)
          : const Color(0xFF35C86B);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barY, barWidth, barHeight),
        const Radius.circular(99),
      ),
      hpBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barY, barWidth * hpRatio, barHeight),
        const Radius.circular(99),
      ),
      hpFill,
    );
  }

  void receiveDamage(double damage, {WatchtowerRewardBoxComponent? rewardBox}) {
    _hp -= damage;
    if (_hp > 0 || isRemoving) {
      return;
    }
    game.onEnemyKilled(spec, position.clone(), rewardBox: rewardBox);
    removeFromParent();
  }
}

class CoinComponent extends CircleComponent
    with HasGameReference<BaseDefenseGame> {
  CoinComponent({required Vector2 position, required this.value})
    : super(
        radius: 9,
        position: position,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFFFD44D),
      );

  static const double _magnetRange = 210;
  static const double _magnetSpeed = 340;
  static const double _pickupPadding = 7;

  final int value;
  double _lifeTime = 12;

  @override
  void onMount() {
    super.onMount();
    game.registerCoin(this);
  }

  @override
  void onRemove() {
    game.unregisterCoin(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifeTime -= dt;
    if (_lifeTime <= 0) {
      removeFromParent();
      return;
    }

    final toPlayer = game.playerPosition - position;
    final distance2 = toPlayer.length2;
    final pickupDistance = radius + game.playerRadius + _pickupPadding;
    if (distance2 <= pickupDistance * pickupDistance) {
      game.collectCoin(value);
      removeFromParent();
      return;
    }

    if (distance2 > 0 && distance2 <= _magnetRange * _magnetRange) {
      toPlayer.normalize();
      position.add(toPlayer..scale(_magnetSpeed * dt));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFB38309);
    canvas.drawCircle(Offset(radius, radius), radius - 1, rim);
  }
}

class BulletComponent extends CircleComponent
    with HasGameReference<BaseDefenseGame> {
  BulletComponent({
    required Vector2 position,
    required this.velocity,
    required this.damage,
    this.rewardBox,
  }) : super(
         radius: 5,
         position: position,
         anchor: Anchor.center,
         paint: Paint()..color = const Color(0xFFF0F4F8),
       );

  final Vector2 velocity;
  final double damage;
  final WatchtowerRewardBoxComponent? rewardBox;
  double _lifeTime = 1.6;

  @override
  void onMount() {
    super.onMount();
    game.registerBullet(this);
  }

  @override
  void onRemove() {
    game.unregisterBullet(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifeTime -= dt;
    if (_lifeTime <= 0) {
      removeFromParent();
      return;
    }

    position.add(velocity * dt);

    if (position.x < -30 ||
        position.y < -30 ||
        position.x > game.arenaSize.x + 30 ||
        position.y > game.arenaSize.y + 30) {
      removeFromParent();
      return;
    }

    for (final enemy in game.enemies.toList(growable: false)) {
      final hitRadius = radius + enemy.radius;
      if (position.distanceToSquared(enemy.position) <= hitRadius * hitRadius) {
        enemy.receiveDamage(damage, rewardBox: rewardBox);
        removeFromParent();
        return;
      }
    }
  }
}
