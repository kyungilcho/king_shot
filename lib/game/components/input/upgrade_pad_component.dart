part of '../../base_defense_game.dart';

class UpgradePadComponent extends RectangleComponent
    with HasGameReference<BaseDefenseGame> {
  UpgradePadComponent({required this.type, required Vector2 position})
    : super(
        position: position,
        size: Vector2.all(88),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xAA2A3948),
      );

  static final _titlePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFE7F1FF),
      fontSize: 12,
      fontWeight: FontWeight.w800,
    ),
  );
  static final _costAffordablePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFE79A),
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );
  static final _costBlockedPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFE4A7A7),
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );

  final UpgradePadType type;
  static const double _interactionRange = 96;
  double get interactionRange => _interactionRange;
  static const double _coinTickInterval = 0.05;

  late final TextComponent<TextPaint> _titleText;
  late final TextComponent<TextPaint> _costText;

  double _refreshTimer = 0;
  double _coinTickTimer = 0;
  int _targetCost = 1;
  int _paid = 0;
  bool _completed = false;

  double get _progress =>
      _completed ? 1 : (_targetCost <= 0 ? 0 : _paid / _targetCost);
  int get _remainingCost =>
      _completed ? 0 : (_targetCost - _paid).clamp(0, _targetCost);

  void resetProgress() {
    _targetCost = math.max(1, game.costForPad(type));
    _paid = 0;
    _completed = false;
    _coinTickTimer = 0;
  }

  void markCompleted() {
    _completed = true;
    _targetCost = 1;
    _paid = 1;
    _coinTickTimer = 0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    resetProgress();

    _titleText = TextComponent<TextPaint>(
      text: '',
      textRenderer: _titlePaint,
      position: Vector2(0, -16),
      anchor: Anchor.center,
    );
    _costText = TextComponent<TextPaint>(
      text: '',
      textRenderer: _costAffordablePaint,
      position: Vector2(0, 14),
      anchor: Anchor.center,
    );
    addAll([_titleText, _costText]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _handleCoinPayment(dt);

    _refreshTimer += dt;
    if (_refreshTimer < 0.08) {
      return;
    }
    _refreshTimer = 0;

    final level = game.levelForPad(type);
    final remainingCost = _remainingCost;
    final affordable = !_completed && game.coins > 0;
    final onPad = _isPlayerTouchingPad();

    _titleText.text = switch (type) {
      UpgradePadType.weapon => '${game.labelForPad(type)} Lv.$level',
      UpgradePadType.barracks => '${game.labelForPad(type)} Lv.$level',
      UpgradePadType.watchtower => _completed ? 'Watchtower' : 'Tower Site',
    };
    _costText
      ..text = _completed ? 'BUILT' : '$remainingCost C'
      ..textRenderer = affordable ? _costAffordablePaint : _costBlockedPaint;

    paint.color = _completed
        ? const Color(0xCC426C7F)
        : onPad
        ? (affordable ? const Color(0xCC3A8D66) : const Color(0xCC8B4F57))
        : const Color(0xAA2A3948);
  }

  @override
  void render(Canvas canvas) {
    final frameRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final frameRRect = RRect.fromRectAndRadius(
      frameRect,
      const Radius.circular(10),
    );
    canvas.drawRRect(frameRRect, paint);

    if (_progress > 0) {
      final fillHeight = size.y * _progress;
      final fillRect = Rect.fromLTWH(
        0,
        size.y - fillHeight,
        size.x,
        fillHeight,
      );
      final fillPaint = Paint()..color = const Color(0x663CB56F);
      canvas.save();
      canvas.clipRRect(frameRRect);
      canvas.drawRect(fillRect, fillPaint);
      canvas.restore();
    }

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xDDEAF5FF);
    canvas.drawRRect(frameRRect, framePaint);

    final barBg = Paint()..color = const Color(0x99374756);
    final barFill = Paint()..color = const Color(0xFF34C06C);
    final barY = size.y - 11;
    final barWidth = size.x - 12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, barY, barWidth, 6),
        const Radius.circular(99),
      ),
      barBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, barY, barWidth * _progress, 6),
        const Radius.circular(99),
      ),
      barFill,
    );
  }

  bool _isPlayerTouchingPad() {
    final player = game.playerPosition;
    final left = position.x - size.x / 2;
    final right = position.x + size.x / 2;
    final top = position.y - size.y / 2;
    final bottom = position.y + size.y / 2;

    final closestX = player.x.clamp(left, right).toDouble();
    final closestY = player.y.clamp(top, bottom).toDouble();
    final dx = player.x - closestX;
    final dy = player.y - closestY;
    return (dx * dx) + (dy * dy) <= game.playerRadius * game.playerRadius;
  }

  void _handleCoinPayment(double dt) {
    if (game.isGameOver ||
        _completed ||
        !_isPlayerTouchingPad() ||
        _remainingCost <= 0) {
      _coinTickTimer = 0;
      return;
    }

    _coinTickTimer += dt;
    while (_coinTickTimer >= _coinTickInterval && _remainingCost > 0) {
      _coinTickTimer -= _coinTickInterval;
      if (!game.spendCoins(1)) {
        break;
      }
      _paid += 1;

      if (_remainingCost <= 0) {
        final upgraded = switch (type) {
          UpgradePadType.weapon => game.upgradeWeapon(chargeCoins: false),
          UpgradePadType.barracks => game.upgradeBarracks(chargeCoins: false),
          UpgradePadType.watchtower => game.buildWatchtower(chargeCoins: false),
        };
        if (upgraded) {
          if (type == UpgradePadType.watchtower) {
            markCompleted();
          } else {
            resetProgress();
          }
        }
        break;
      }
    }
  }
}
