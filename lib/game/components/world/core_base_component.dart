part of '../../base_defense_game.dart';

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
    final baseSprite = game.art.base;
    if (baseSprite != null) {
      _renderSpriteBase(canvas, baseSprite);
    } else {
      _renderFallbackBase(canvas);
    }
    _renderHpBar(canvas);
  }

  void _renderSpriteBase(Canvas canvas, Sprite sprite) {
    final shadowPaint = Paint()..color = const Color(0x55223344);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, size.y + 8),
        width: size.x * 0.98,
        height: 24,
      ),
      shadowPaint,
    );

    final spriteSize = Vector2(size.x * 1.85, size.y * 2.1);
    final spritePosition = Vector2(
      (size.x - spriteSize.x) * 0.5,
      size.y - spriteSize.y * 0.72,
    );
    sprite.render(canvas, position: spritePosition, size: spriteSize);
  }

  void _renderFallbackBase(Canvas canvas) {
    final shadowPaint = Paint()..color = const Color(0x55223344);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, size.y + 6),
        width: size.x * 0.9,
        height: 22,
      ),
      shadowPaint,
    );

    final baseRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final baseRRect = RRect.fromRectAndRadius(
      baseRect,
      const Radius.circular(20),
    );
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4E8DFF), Color(0xFF2E63D9), Color(0xFF254FAD)],
      ).createShader(baseRect);
    canvas.drawRRect(baseRRect, wallPaint);

    final roofRect = Rect.fromLTWH(
      size.x * 0.08,
      size.y * 0.08,
      size.x * 0.84,
      size.y * 0.28,
    );
    final roofPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E5D9D), Color(0xFF1B3E6C)],
      ).createShader(roofRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(roofRect, const Radius.circular(12)),
      roofPaint,
    );

    final corePaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB9F3FF), Color(0xFF7FD9FF), Color(0xFF55BDE8)],
          ).createShader(
            Rect.fromLTWH(
              size.x * 0.34,
              size.y * 0.36,
              size.x * 0.32,
              size.y * 0.34,
            ),
          );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.34,
          size.y * 0.36,
          size.x * 0.32,
          size.y * 0.34,
        ),
        const Radius.circular(10),
      ),
      corePaint,
    );

    final doorPaint = Paint()..color = const Color(0x994A8CFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.46,
          size.y * 0.52,
          size.x * 0.08,
          size.y * 0.24,
        ),
        const Radius.circular(4),
      ),
      doorPaint,
    );

    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = const Color(0xAA95C3FF);
    canvas.drawRRect(baseRRect, frame);
  }

  void _renderHpBar(Canvas canvas) {
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
