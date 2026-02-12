part of '../../base_defense_game.dart';

class ArenaComponent extends PositionComponent
    with HasGameReference<BaseDefenseGame> {
  ArenaComponent({required super.size});

  static const _groundTints = [
    Color(0xFF80A96D),
    Color(0xFF7FAA79),
    Color(0xFF7AA38A),
    Color(0xFF76929D),
  ];
  static const _groundTileSize = 92.0;
  static const _pathTileWidth = 150.0;
  static const _pathTileHeight = 82.0;
  static const _pathOverlapRatio = 0.58;
  static const _pathRowGap = 28.0;

  int _stageIndex = 0;

  void setStage(int stageIndex) {
    _stageIndex = stageIndex.clamp(0, _groundTints.length - 1).toInt();
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final stageTint = _groundTints[_stageIndex];
    final groundSprite = game.art.terrainGroundTile;
    if (groundSprite != null) {
      _renderGroundTiles(canvas, rect, groundSprite, stageTint);
    } else {
      _renderFallbackGround(canvas, rect, stageTint);
    }

    final pathStraight = game.art.terrainPathStraight;
    final pathCorner = game.art.terrainPathCorner;
    for (final pathRect in _pathRects()) {
      if (pathStraight != null) {
        _renderPathTiles(
          canvas,
          pathRect,
          pathStraight: pathStraight,
          pathCorner: pathCorner,
        );
      } else {
        _drawPathFallback(canvas, pathRect);
      }
    }

    final bushPaint = Paint()..color = const Color(0xCC4A8D5A);
    final rockPaint = Paint()..color = const Color(0xBB7D8B91);
    for (var i = 0; i < 22; i += 1) {
      final x = ((i * 131) % size.x).toDouble();
      final y = ((i * 197 + 43) % size.y).toDouble();
      if (i.isEven) {
        canvas.drawCircle(Offset(x, y), 9 + (i % 4) * 1.6, bushPaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 15, height: 11),
            const Radius.circular(4),
          ),
          rockPaint,
        );
      }
    }
  }

  void _renderGroundTiles(
    Canvas canvas,
    Rect rect,
    Sprite tileSprite,
    Color stageTint,
  ) {
    final tintPaint = Paint()
      ..colorFilter = ColorFilter.mode(
        Color.lerp(Colors.white, stageTint, 0.32)!,
        BlendMode.modulate,
      );

    final columns = (size.x / _groundTileSize).ceil() + 2;
    final rows = (size.y / _groundTileSize).ceil() + 2;
    for (var row = 0; row < rows; row += 1) {
      for (var col = 0; col < columns; col += 1) {
        final x = (col - 1) * _groundTileSize;
        final y = (row - 1) * _groundTileSize;
        final jitter = (row + col).isEven ? 1.0 : 0.98;
        tileSprite.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2.all(_groundTileSize * jitter + 1.5),
          overridePaint: tintPaint,
        );
      }
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x11000000), Color(0x00000000), Color(0x18000000)],
        ).createShader(rect),
    );
  }

  List<Rect> _pathRects() {
    return [
      Rect.fromLTWH(size.x * 0.08, size.y * 0.12, size.x * 0.84, size.y * 0.18),
      Rect.fromLTWH(size.x * 0.12, size.y * 0.42, size.x * 0.76, size.y * 0.18),
      Rect.fromLTWH(size.x * 0.09, size.y * 0.72, size.x * 0.82, size.y * 0.18),
    ];
  }

  void _renderPathTiles(
    Canvas canvas,
    Rect rect, {
    required Sprite pathStraight,
    Sprite? pathCorner,
  }) {
    final spacingX = _pathTileWidth * _pathOverlapRatio;
    final rowCount = math.max(2, (rect.height / _pathRowGap).round());
    final rowTop = rect.center.dy - ((rowCount - 1) * _pathRowGap) * 0.5;
    for (var row = 0; row < rowCount; row += 1) {
      final y = rowTop + (row * _pathRowGap);
      final rowShift = row.isEven ? 0.0 : spacingX * 0.5;
      for (
        var x = rect.left - _pathTileWidth * 0.5 + rowShift;
        x < rect.right + _pathTileWidth * 0.4;
        x += spacingX
      ) {
        final wobble = ((row * 7 + (x / spacingX).floor()) % 2 == 0)
            ? 1.0
            : 0.97;
        pathStraight.render(
          canvas,
          position: Vector2(x, y - _pathTileHeight * 0.5),
          size: Vector2(_pathTileWidth * wobble, _pathTileHeight * wobble),
        );
      }
    }

    if (pathCorner != null) {
      final cornerSize = Vector2(_pathTileWidth * 0.78, _pathTileHeight * 0.82);
      pathCorner.render(
        canvas,
        position: Vector2(
          rect.left - cornerSize.x * 0.48,
          rect.center.dy - cornerSize.y * 0.52,
        ),
        size: cornerSize,
      );
      pathCorner.render(
        canvas,
        position: Vector2(
          rect.right - cornerSize.x * 0.52,
          rect.center.dy - cornerSize.y * 0.44,
        ),
        size: cornerSize,
      );
    }
  }

  void _renderFallbackGround(Canvas canvas, Rect rect, Color stageTint) {
    final top = Color.lerp(stageTint, Colors.white, 0.08)!;
    final bottom = Color.lerp(stageTint, Colors.black, 0.12)!;
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [top, stageTint, bottom],
      ).createShader(rect);
    canvas.drawRect(rect, groundPaint);
  }

  void _drawPathFallback(Canvas canvas, Rect rect) {
    final pathRRect = RRect.fromRectAndRadius(rect, const Radius.circular(44));
    final pathPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFE8D9B6), Color(0xFFD8C59A), Color(0xFFCAB487)],
      ).createShader(rect);
    canvas.drawRRect(pathRRect, pathPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x667E6A4A);
    canvas.drawRRect(pathRRect, borderPaint);

    final highlightPaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + 14,
          rect.top + 8,
          rect.width - 28,
          rect.height * 0.28,
        ),
        const Radius.circular(24),
      ),
      highlightPaint,
    );
  }
}
