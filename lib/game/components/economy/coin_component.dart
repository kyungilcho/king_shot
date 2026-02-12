part of '../../base_defense_game.dart';

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
    final center = Offset(radius, radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF2A5), Color(0xFFFFD44D), Color(0xFFE6A91B)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.2, -radius * 0.24),
      radius * 0.26,
      Paint()..color = const Color(0x66FFFFFF),
    );
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFB38309),
    );
    canvas.drawCircle(
      center,
      radius * 0.45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xAAFFC95B),
    );
  }
}
