part of '../../base_defense_game.dart';

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

  @override
  void render(Canvas canvas) {
    final barracksSprite = game.art.barracks;
    if (barracksSprite != null) {
      _renderSpriteBarracks(canvas, barracksSprite);
      return;
    }

    final active = _level > 0;
    final wallTop = active ? const Color(0xFFB78A5F) : const Color(0xFF6B6258);
    final wallBottom = active
        ? const Color(0xFF85613F)
        : const Color(0xFF4E4A44);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, size.y + 4),
        width: size.x * 0.9,
        height: 16,
      ),
      Paint()..color = const Color(0x4420120B),
    );

    final wallRect = Rect.fromLTWH(0, 6, size.x, size.y - 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(wallRect, const Radius.circular(12)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [wallTop, wallBottom],
        ).createShader(wallRect),
    );

    final roofRect = Rect.fromLTWH(
      size.x * 0.06,
      0,
      size.x * 0.88,
      size.y * 0.34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roofRect, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7D5140), Color(0xFF583729)],
        ).createShader(roofRect),
    );

    final doorRect = Rect.fromLTWH(
      size.x * 0.42,
      size.y * 0.4,
      size.x * 0.16,
      size.y * 0.42,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(doorRect, const Radius.circular(5)),
      Paint()..color = const Color(0x993B271A),
    );
    canvas.drawCircle(
      Offset(doorRect.right - 5, doorRect.center.dy),
      1.6,
      Paint()..color = const Color(0xFFE8C46E),
    );

    final windowPaint = Paint()..color = const Color(0xAAE9F0F8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.2, size.y * 0.44, 12, 10),
        const Radius.circular(3),
      ),
      windowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.68, size.y * 0.44, 12, 10),
        const Radius.circular(3),
      ),
      windowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 6, size.x, size.y - 6),
        const Radius.circular(12),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xB83A2A1D),
    );
  }

  void _renderSpriteBarracks(Canvas canvas, Sprite sprite) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, size.y + 4),
        width: size.x * 0.88,
        height: 15,
      ),
      Paint()..color = const Color(0x4420120B),
    );

    final spriteSize = Vector2(size.x * 2.1, size.y * 2.1);
    final spritePosition = Vector2(
      (size.x - spriteSize.x) * 0.5,
      size.y - spriteSize.y * 0.79,
    );
    sprite.render(canvas, position: spritePosition, size: spriteSize);
  }

  void _syncLabel() {
    _label.text = _level == 0 ? 'Barracks Locked' : 'Barracks Lv.$_level';
    paint.color = _level == 0
        ? const Color(0xFF4F4A44)
        : const Color(0xFF6E5D4A);
  }
}
