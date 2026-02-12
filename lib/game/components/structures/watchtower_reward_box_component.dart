part of '../../base_defense_game.dart';

class WatchtowerRewardBoxComponent extends RectangleComponent
    with HasGameReference<BaseDefenseGame> {
  WatchtowerRewardBoxComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2.all(34),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xCC2C3A46),
      );

  static const double _collectRange = 70;
  static const double _collectTickInterval = 0.01;
  static final _amountPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFE08A),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
  );

  late final TextComponent<TextPaint> _amountText;
  int _storedCoins = 0;
  double _collectTickTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _amountText = TextComponent<TextPaint>(
      text: '',
      textRenderer: _amountPaint,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(_amountText);
    _syncLabel();
  }

  void addCoins(int amount) {
    if (amount <= 0 || isRemoving) {
      return;
    }
    _storedCoins += amount;
    _syncLabel();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_storedCoins <= 0 || game.isGameOver) {
      _collectTickTimer = 0;
      return;
    }
    final isInCollectRange =
        position.distanceToSquared(game.playerPosition) <=
        _collectRange * _collectRange;
    if (!isInCollectRange) {
      _collectTickTimer = 0;
      return;
    }

    _collectTickTimer += dt;
    final payoutCount = math.min(
      _storedCoins,
      (_collectTickTimer / _collectTickInterval).floor(),
    );
    if (payoutCount > 0) {
      _collectTickTimer -= payoutCount * _collectTickInterval;
      _storedCoins -= payoutCount;
      game.collectCoin(payoutCount);
      _syncLabel();
    }
  }

  void _syncLabel() {
    _amountText.text = _storedCoins > 0 ? '$_storedCoins' : '';
    paint.color = _storedCoins > 0
        ? const Color(0xCC3C4F5F)
        : const Color(0xAA26343F);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _storedCoins > 0
              ? const [Color(0xCC4A5F73), Color(0xCC2B3A47)]
              : const [Color(0xAA344551), Color(0xAA24323D)],
        ).createShader(rect),
    );

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xE8ECF5FF);
    canvas.drawRRect(rrect, framePaint);

    if (_storedCoins > 0) {
      final coinCenter = Offset(size.x * 0.22, size.y * 0.5);
      canvas.drawCircle(
        coinCenter,
        4.8,
        Paint()..color = const Color(0xFFFFCA4A),
      );
      canvas.drawCircle(
        coinCenter.translate(-1.2, -1.0),
        1.4,
        Paint()..color = const Color(0x55FFFFFF),
      );
    }
  }
}
