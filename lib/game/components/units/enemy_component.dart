part of '../../base_defense_game.dart';

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
    final enemySprite = game.art.enemyFor(type);
    if (enemySprite != null) {
      _renderSpriteEnemy(canvas, enemySprite);
    } else {
      final center = Offset(radius, radius);
      final baseRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, radius + 1),
          width: radius * 1.9,
          height: radius * 0.74,
        ),
        Paint()..color = const Color(0x44160908),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(spec.color, Colors.white, 0.16)!,
              spec.color,
              Color.lerp(spec.color, Colors.black, 0.24)!,
            ],
          ).createShader(baseRect),
      );

      final helmetColor = switch (type) {
        EnemyType.grunt => const Color(0xFF6F2B22),
        EnemyType.brute => const Color(0xFF4F1A14),
        EnemyType.elite => const Color(0xFF3D1110),
        EnemyType.boss => const Color(0xFF251126),
      };
      canvas.drawArc(
        Rect.fromCircle(
          center: center.translate(0, -radius * 0.15),
          radius: radius * 0.72,
        ),
        math.pi,
        math.pi,
        true,
        Paint()..color = helmetColor,
      );

      final eyeColor = type == EnemyType.boss
          ? const Color(0xFFFF7CA0)
          : const Color(0xFFFFE6C9);
      canvas.drawCircle(
        center.translate(-radius * 0.28, -radius * 0.05),
        2.3,
        Paint()..color = eyeColor,
      );
      canvas.drawCircle(
        center.translate(radius * 0.28, -radius * 0.05),
        2.3,
        Paint()..color = eyeColor,
      );

      if (type == EnemyType.elite || type == EnemyType.boss) {
        final spikePaint = Paint()..color = const Color(0xFF2A0F0F);
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - radius * 0.58, center.dy - radius * 0.52)
            ..lineTo(center.dx - radius * 0.22, center.dy - radius * 0.88)
            ..lineTo(center.dx - radius * 0.1, center.dy - radius * 0.42)
            ..close(),
          spikePaint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(center.dx + radius * 0.58, center.dy - radius * 0.52)
            ..lineTo(center.dx + radius * 0.22, center.dy - radius * 0.88)
            ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.42)
            ..close(),
          spikePaint,
        );
      }

      if (type == EnemyType.boss) {
        canvas.drawCircle(
          center,
          radius + 2.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xAAE25C84),
        );
      }
    }

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

  void _renderSpriteEnemy(Canvas canvas, Sprite sprite) {
    final center = Offset(radius, radius);
    final shadowWidth = type == EnemyType.boss ? radius * 2.25 : radius * 1.8;
    final shadowHeight = type == EnemyType.boss ? radius * 0.84 : radius * 0.62;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius + 2),
        width: shadowWidth,
        height: shadowHeight,
      ),
      Paint()..color = const Color(0x44160908),
    );

    final scale = switch (type) {
      EnemyType.grunt => 2.1,
      EnemyType.brute => 2.24,
      EnemyType.elite => 2.35,
      EnemyType.boss => 2.64,
    };
    final footAnchor = switch (type) {
      EnemyType.grunt => 0.66,
      EnemyType.brute => 0.67,
      EnemyType.elite => 0.67,
      EnemyType.boss => 0.69,
    };
    final spriteSize = Vector2.all(radius * scale);
    final spritePosition = Vector2(
      radius - spriteSize.x * 0.5,
      radius - spriteSize.y * footAnchor,
    );
    sprite.render(canvas, position: spritePosition, size: spriteSize);
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
