part of '../../base_defense_game.dart';

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
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final trailDir = velocity.clone();
    if (trailDir.length2 > 0) {
      trailDir.normalize();
      final tail =
          center - Offset(trailDir.x * radius * 1.8, trailDir.y * radius * 1.8);
      canvas.drawLine(
        tail,
        center,
        Paint()
          ..color = const Color(0xAAEAF2FF)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFEAF1F8), Color(0x99B8C6D6)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
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
