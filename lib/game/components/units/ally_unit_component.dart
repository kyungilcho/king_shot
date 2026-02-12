part of '../../base_defense_game.dart';

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

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius - 1),
        width: radius * 1.8,
        height: radius * 0.72,
      ),
      Paint()..color = const Color(0x4425313E),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA6E4FF), Color(0xFF79D3FF), Color(0xFF4EB4E5)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(0, -radius * 0.2),
      radius * 0.6,
      Paint()..color = const Color(0xFF2A5AB7),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.2, -radius * 0.25),
      1.7,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center.translate(radius * 0.2, -radius * 0.25),
      1.7,
      Paint()..color = Colors.white,
    );

    if (_assignedTower != null) {
      canvas.drawCircle(
        center,
        radius + 2.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF7BD7FF),
      );
    }
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
