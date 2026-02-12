import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/cache.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'models/game_models.dart';
part 'config/stage_balance.dart';
part 'art/game_sprite_catalog.dart';
part 'components/world/arena_component.dart';
part 'components/world/core_base_component.dart';
part 'components/world/scenery_prop_component.dart';
part 'components/input/dynamic_joystick_component.dart';
part 'components/input/upgrade_pad_component.dart';
part 'components/structures/barracks_component.dart';
part 'components/structures/watchtower_component.dart';
part 'components/structures/watchtower_reward_box_component.dart';
part 'components/units/player_component.dart';
part 'components/units/ally_unit_component.dart';
part 'components/units/enemy_component.dart';
part 'components/combat/bullet_component.dart';
part 'components/economy/coin_component.dart';

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

  static final List<StageDefinition> _stages = _buildStageDefinitions();

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
  final sceneryProps = <SceneryPropComponent>{};
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
  static const Anchor _cameraAnchor = Anchor(0.615, 0.785);
  static const double _cameraZoom = 0.94;
  static const int _layerPriorityGround = 0;
  static const int _layerPriorityGameplay = 100;
  static const int _layerPriorityVfx = 200;
  static const int _depthBiasPad = -1400;
  static const int _depthBiasWorldObject = 0;
  static const int _depthBiasCoin = 260;

  late final PositionComponent _groundLayer;
  late final PositionComponent _gameplayLayer;
  late final PositionComponent _vfxLayer;
  late final ArenaComponent _arena;
  late final CoreBaseComponent _base;
  late final BarracksComponent _barracks;
  late final PlayerComponent _player;
  late final UpgradePadComponent _weaponPad;
  late final UpgradePadComponent _barracksPad;
  late final UpgradePadComponent _watchtowerPad;
  late final DynamicJoystickComponent _dynamicJoystick;
  late final GameSpriteCatalog art;
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

    _addToGameplayLayer(
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
    _addToVfxLayer(bullet);
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
      _addToGameplayLayer(
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
    _addToGameplayLayer(AllyUnitComponent(position: spawnPosition));
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
    images.prefix = 'assets/';
    art = await GameSpriteCatalog.load(images);

    _groundLayer = PositionComponent(priority: _layerPriorityGround);
    _gameplayLayer = PositionComponent(priority: _layerPriorityGameplay);
    _vfxLayer = PositionComponent(priority: _layerPriorityVfx);
    world.addAll([_groundLayer, _gameplayLayer, _vfxLayer]);

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

    _groundLayer.add(_arena);
    _gameplayLayer.addAll([
      _base,
      _barracks,
      _weaponPad,
      _barracksPad,
      _watchtowerPad,
      _player,
    ]);
    _spawnSceneryProps();

    _arena.setStage(_currentStageIndex);
    _syncSceneDepth();
    _applyCameraFraming();
    camera.follow(_player, snap: true);

    _dynamicJoystick = DynamicJoystickComponent(priority: 1000);
    camera.viewport.add(_dynamicJoystick);

    _publishHud(force: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncSceneDepth();
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

  void registerScenery(SceneryPropComponent prop) {
    sceneryProps.add(prop);
  }

  void unregisterScenery(SceneryPropComponent prop) {
    sceneryProps.remove(prop);
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
    _syncSceneDepth();
    _applyCameraFraming();
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
    _addToGameplayLayer(
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

  void _spawnSceneryProps() {
    final treeSprite = art.sceneryTree;
    final rockSprite = art.sceneryRock;
    if (treeSprite == null && rockSprite == null) {
      return;
    }

    final treePositions = <Vector2>[
      Vector2(180, 170),
      Vector2(420, 260),
      Vector2(700, 160),
      Vector2(980, 250),
      Vector2(1280, 190),
      Vector2(1580, 290),
      Vector2(1870, 210),
      Vector2(2060, 430),
      Vector2(1970, 670),
      Vector2(1740, 880),
      Vector2(1450, 1080),
      Vector2(1110, 1240),
      Vector2(760, 1170),
      Vector2(420, 1020),
      Vector2(200, 810),
      Vector2(250, 560),
    ];
    final rockPositions = <Vector2>[
      Vector2(300, 340),
      Vector2(560, 190),
      Vector2(840, 330),
      Vector2(1170, 300),
      Vector2(1480, 170),
      Vector2(1710, 520),
      Vector2(1990, 540),
      Vector2(1880, 890),
      Vector2(1600, 1080),
      Vector2(1280, 1220),
      Vector2(900, 1290),
      Vector2(540, 1110),
      Vector2(270, 960),
    ];

    if (treeSprite != null) {
      for (final position in treePositions) {
        _addToGameplayLayer(
          SceneryPropComponent(
            sprite: treeSprite,
            position: position,
            footprintSize: Vector2(48, 30),
            spriteSize: Vector2(136, 136),
          ),
        );
      }
    }

    if (rockSprite != null) {
      for (final position in rockPositions) {
        _addToGameplayLayer(
          SceneryPropComponent(
            sprite: rockSprite,
            position: position,
            footprintSize: Vector2(34, 22),
            spriteSize: Vector2(72, 72),
          ),
        );
      }
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

  void _addToGameplayLayer(Component component) {
    _gameplayLayer.add(component);
  }

  void _addToVfxLayer(Component component) {
    _vfxLayer.add(component);
  }

  int _depthFor(Vector2 position, {int bias = 0}) {
    return bias + position.y.round();
  }

  void _syncSceneDepth() {
    if (!_base.isMounted || !_player.isMounted) {
      return;
    }

    _base.priority = _depthFor(_base.position, bias: _depthBiasWorldObject);
    _barracks.priority = _depthFor(
      _barracks.position,
      bias: _depthBiasWorldObject,
    );

    _weaponPad.priority = _depthFor(_weaponPad.position, bias: _depthBiasPad);
    _barracksPad.priority = _depthFor(
      _barracksPad.position,
      bias: _depthBiasPad,
    );
    _watchtowerPad.priority = _depthFor(
      _watchtowerPad.position,
      bias: _depthBiasPad,
    );

    for (final tower in watchtowers) {
      tower.priority = _depthFor(tower.position, bias: _depthBiasWorldObject);
      final rewardBox = tower.rewardBox;
      if (rewardBox != null && rewardBox.isMounted && !rewardBox.isRemoving) {
        rewardBox.priority = _depthFor(
          rewardBox.position,
          bias: _depthBiasCoin,
        );
      }
    }
    for (final prop in sceneryProps) {
      prop.priority = _depthFor(prop.position, bias: _depthBiasWorldObject);
    }

    _player.priority = _depthFor(_player.position, bias: _depthBiasWorldObject);
    for (final ally in allies) {
      ally.priority = _depthFor(ally.position, bias: _depthBiasWorldObject);
    }
    for (final enemy in enemies) {
      enemy.priority = _depthFor(enemy.position, bias: _depthBiasWorldObject);
    }

    for (final coin in droppedCoins) {
      coin.priority = _depthFor(coin.position, bias: _depthBiasCoin);
    }
    for (final bullet in bullets) {
      bullet.priority = _depthFor(bullet.position);
    }
  }

  void _applyCameraFraming() {
    camera.viewfinder
      ..anchor = _cameraAnchor
      ..zoom = _cameraZoom;
  }
}
