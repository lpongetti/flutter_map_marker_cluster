import "package:flutter/animation.dart";
import "package:flutter/foundation.dart";

@immutable
class Fade {
  const Fade._(this._tween, this._curve);

  factory Fade.fadeIn({required Curve curve}) {
    return Fade._(Tween<double>(begin: 0, end: 1), curve);
  }
  factory Fade.fadeOut({required Curve curve}) {
    return Fade._(Tween<double>(begin: 1, end: 0), curve);
  }
  factory Fade.almostFadeOut({required Curve curve}) {
    return Fade._(Tween<double>(begin: 1, end: 0.3), curve);
  }
  final Curve _curve;
  final Tween<double> _tween;

  Animation<double> animation(AnimationController controller) =>
      _tween.chain(CurveTween(curve: _curve)).animate(controller);
}
