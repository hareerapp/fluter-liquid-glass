import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

void animateGlassSpring(
  AnimationController controller,
  double target,
  SpringDescription spring,
) {
  controller.animateWith(
    _CappedSimulation(
      SpringSimulation(spring, controller.value, target, controller.velocity),
    ),
  );
}

const double _maxStep = 1 / 30;

class _CappedSimulation extends Simulation {
  _CappedSimulation(this._inner);

  final Simulation _inner;
  double _lastTime = 0;
  double _virtualTime = 0;

  double _advance(double time) {
    if (time > _lastTime) {
      _virtualTime += math.min(time - _lastTime, _maxStep);
      _lastTime = time;
    }
    return _virtualTime;
  }

  @override
  double x(double time) => _inner.x(_advance(time));

  @override
  double dx(double time) => _inner.dx(_advance(time));

  @override
  bool isDone(double time) => _inner.isDone(_advance(time));
}
