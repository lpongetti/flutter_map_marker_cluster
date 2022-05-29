import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_marker_cluster/src/anim_type.dart';

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

  Animation<Point<double>>? animation(
          AnimationController animationController) =>
      null;
}

class AnimatedTranslate extends Translate {
  final TranslateType type;
  @override
  final Point<double> position;
  final Point<double> newPosition;

  const AnimatedTranslate({
    required this.type,
    required this.position,
    required this.newPosition,
  });

  @override
  Animation<Point<double>>? animation(AnimationController animationController) {
    switch (type) {
      case TranslateType.fromMyPosToNewPos:
        return Tween<Point<double>>(
          begin: Point(position.x, position.y),
          end: Point(newPosition.x, newPosition.y),
        ).animate(animationController);
      case TranslateType.fromNewPosToMyPos:
        return Tween<Point<double>>(
          begin: Point(newPosition.x, newPosition.y),
          end: Point(position.x, position.y),
        ).animate(animationController);
    }
  }
}
