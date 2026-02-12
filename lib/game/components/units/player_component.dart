part of '../../base_defense_game.dart';

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
  static const double _spriteScale = 2.65;
  static const double _spriteFootAnchor = 0.68;

  double _shotCooldown = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _move(dt);
    _shoot(dt);
  }

  @override
  void render(Canvas canvas) {
    final playerSprite = game.art.player;
    if (playerSprite != null) {
      _renderSpritePlayer(canvas, playerSprite);
      return;
    }

    final center = Offset(radius, radius);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius + 2),
        width: radius * 2.0,
        height: radius * 0.8,
      ),
      Paint()..color = const Color(0x44291407),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFDD6A), Color(0xFFF5B11F), Color(0xFFDE8E10)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center.translate(0, -radius * 0.22),
      radius * 0.56,
      Paint()..color = const Color(0xFF2B5AC6),
    );
    canvas.drawCircle(
      center.translate(0, -radius * 0.18),
      radius * 0.3,
      Paint()..color = const Color(0xFFFFCF3B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx - radius * 0.16,
          center.dy + radius * 0.18,
          radius * 0.32,
          radius * 0.44,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF4A301B),
    );

    final dir = game.playerFacingDirection;
    final weaponTip =
        center + Offset(dir.x * (radius + 9), dir.y * (radius + 9));
    canvas.drawLine(
      center + Offset(dir.x * (radius * 0.3), dir.y * (radius * 0.3)),
      weaponTip,
      Paint()
        ..color = const Color(0xFFCBD8E4)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _renderSpritePlayer(Canvas canvas, Sprite sprite) {
    final center = Offset(radius, radius);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius + 3),
        width: radius * 2.0,
        height: radius * 0.72,
      ),
      Paint()..color = const Color(0x44291407),
    );

    final spriteSize = Vector2.all(radius * _spriteScale);
    final spritePosition = Vector2(
      radius - spriteSize.x * 0.5,
      radius - spriteSize.y * _spriteFootAnchor,
    );
    sprite.render(canvas, position: spritePosition, size: spriteSize);
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
