part of '../../base_defense_game.dart';

class DynamicJoystickComponent extends PositionComponent
    with
        HasGameReference<BaseDefenseGame>,
        DragCallbacks,
        TapCallbacks,
        HasVisibility {
  DynamicJoystickComponent({super.priority}) : super(anchor: Anchor.topLeft);

  static const double _radius = 54;
  static const double _knobRadius = 24;

  final Vector2 input = Vector2.zero();

  late final CircleComponent _background;
  late final CircleComponent _knob;

  int? _activePointerId;
  final Vector2 _center = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size.clone();
    isVisible = false;

    _background = CircleComponent(
      radius: _radius,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0x66495E6F),
    );
    _knob = CircleComponent(
      radius: _knobRadius,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xAAE6EDF2),
    );
    addAll([_background, _knob]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapDown(TapDownEvent event) {
    _activePointerId = event.pointerId;
    _center.setFrom(event.localPosition);
    _applyDragPosition(event.localPosition);
    isVisible = true;
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    if (_activePointerId == event.pointerId) {
      _applyDragPosition(event.localPosition);
      isVisible = true;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_activePointerId == event.pointerId) {
      _reset();
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (_activePointerId == event.pointerId) {
      _reset();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_activePointerId != null && _activePointerId != event.pointerId) {
      return;
    }
    _activePointerId = event.pointerId;
    if (!isVisible) {
      _center.setFrom(event.localPosition);
      isVisible = true;
    }
    _applyDragPosition(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_activePointerId != event.pointerId) {
      return;
    }
    _applyDragPosition(event.localStartPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (_activePointerId == event.pointerId) {
      _reset();
    }
    super.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (_activePointerId == event.pointerId) {
      _reset();
    }
    super.onDragCancel(event);
  }

  void _applyDragPosition(Vector2 localPosition) {
    final delta = localPosition - _center;
    if (delta.length2 > _radius * _radius) {
      delta.scaleTo(_radius);
    }

    input
      ..setFrom(delta)
      ..scale(1 / _radius);

    _background.position = _center;
    _knob.position = _center + delta;
  }

  void _reset() {
    _activePointerId = null;
    input.setZero();
    isVisible = false;
  }
}
