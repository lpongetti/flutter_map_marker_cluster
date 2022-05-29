import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class Translate {
  const Translate();

  Animation<Point<double>>? animation(AnimationController animationController);

  Point<double> get position;
}

class StaticTranslate extends Translate {
  @override
  final Point<double> position;

  const StaticTranslate(this.position);

  @override
  Animation<Point<double>>? animation(
          AnimationController animationController) =>
      null;
}

class AnimatedTranslate extends Translate {
  @override
  final Point<double> position;
  final Point<double> newPosition;
  final Tween<Point<double>> _tween;

  AnimatedTranslate.fromMyPosToNewPos({
    required this.position,
    required this.newPosition,
  }) : _tween = Tween<Point<double>>(
          begin: Point(position.x, position.y),
          end: Point(newPosition.x, newPosition.y),
        );

  AnimatedTranslate.fromNewPosToMyPos({
    required this.position,
    required this.newPosition,
  }) : _tween = Tween<Point<double>>(
          begin: Point(newPosition.x, newPosition.y),
          end: Point(position.x, position.y),
        );

  @override
  Animation<Point<double>> animation(AnimationController animationController) =>
      _tween.animate(animationController);
}
