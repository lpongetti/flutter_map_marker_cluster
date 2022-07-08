import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

@immutable
class Fade {
  final Tween<double> _tween;

  static final fadeIn = Fade._(Tween<double>(begin: 0, end: 1));
  static final fadeOut = Fade._(Tween<double>(begin: 1, end: 0));
  static final almostFadeOut = Fade._(Tween<double>(begin: 1, end: 0.3));

  const Fade._(this._tween);

  Animation<double> animation(AnimationController controller) =>
      _tween.animate(controller);
}
