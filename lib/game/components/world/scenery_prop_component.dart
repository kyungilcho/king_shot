part of '../../base_defense_game.dart';

class SceneryPropComponent extends RectangleComponent
    with HasGameReference<BaseDefenseGame> {
  SceneryPropComponent({
    required this.sprite,
    required Vector2 position,
    required Vector2 footprintSize,
    required this.spriteSize,
  }) : super(
         position: position,
         size: footprintSize,
         anchor: Anchor.center,
         paint: Paint(),
       );

  final Sprite sprite;
  final Vector2 spriteSize;

  @override
  void onMount() {
    super.onMount();
    game.registerScenery(this);
  }

  @override
  void onRemove() {
    game.unregisterScenery(this);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, size.y * 0.72),
        width: size.x * 0.9,
        height: size.y * 0.46,
      ),
      Paint()..color = const Color(0x33211207),
    );

    final spritePosition = Vector2(
      (size.x - spriteSize.x) * 0.5,
      size.y - (spriteSize.y * 0.8),
    );
    sprite.render(canvas, position: spritePosition, size: spriteSize);
  }
}
