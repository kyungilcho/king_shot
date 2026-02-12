part of '../../base_defense_game.dart';

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
    game._addToGameplayLayer(_rewardBox!);
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
    final watchtowerSprite = game.art.watchtower;
    if (watchtowerSprite != null) {
      _renderSpriteWatchtower(canvas, watchtowerSprite);
    } else {
      final shadowPaint = Paint()..color = const Color(0x5524150C);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.x * 0.5, size.y + 4),
          width: size.x * 0.82,
          height: 14,
        ),
        shadowPaint,
      );

      final legPaint = Paint()..color = const Color(0xFF63452E);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x * 0.2, size.y * 0.44, 7, size.y * 0.5),
          const Radius.circular(5),
        ),
        legPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x * 0.72, size.y * 0.44, 7, size.y * 0.5),
          const Radius.circular(5),
        ),
        legPaint,
      );

      final deckRect = Rect.fromLTWH(
        size.x * 0.14,
        size.y * 0.06,
        size.x * 0.72,
        size.y * 0.42,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(deckRect, const Radius.circular(8)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B6547), Color(0xFF694B35)],
          ).createShader(deckRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(deckRect, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xB83E281A),
      );

      final turretCenter = Offset(size.x * 0.5, size.y * 0.26);
      canvas.drawCircle(
        turretCenter,
        11.5,
        Paint()..color = const Color(0xFFC7D4DE),
      );
      canvas.drawCircle(
        turretCenter,
        7.5,
        Paint()..color = const Color(0xFF95A8B6),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: turretCenter.translate(0, -10),
          width: 3,
          height: 10,
        ),
        Paint()..color = const Color(0xFF2D3C48),
      );
    }

    if (garrisonCount > 0) {
      final badgeRect = Rect.fromLTWH(size.x * 0.66, -9, 18, 13);
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)),
        Paint()..color = const Color(0xDD2E5FD8),
      );
      final badgeBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFEAF2FF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)),
        badgeBorder,
      );
    }

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

  void _renderSpriteWatchtower(Canvas canvas, Sprite sprite) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, size.y + 4),
        width: size.x * 0.84,
        height: 14,
      ),
      Paint()..color = const Color(0x5524150C),
    );

    final spriteSize = Vector2(size.x * 2.2, size.y * 2.4);
    final spritePosition = Vector2(
      (size.x - spriteSize.x) * 0.5,
      size.y - spriteSize.y * 0.8,
    );
    sprite.render(canvas, position: spritePosition, size: spriteSize);
  }
}
