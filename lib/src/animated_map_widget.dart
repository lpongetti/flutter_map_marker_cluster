import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map_marker_cluster/src/fade.dart';
import 'package:flutter_map_marker_cluster/src/translate.dart';

class AnimatedMapWidget extends StatelessWidget {
  final Widget child;
  final Size size;
  final AnimationController animationController;
  final Animation<Point<double>>? _translateAnimation;
  final Point<double>? _position;
  final Animation<double>? _fadeAnimation;

  AnimatedMapWidget({
    required this.child,
    required this.size,
    required this.animationController,
    required Translate translate,
    Fade? fade,
    Key? key,
  })  : _translateAnimation = translate.animation(animationController),
        _position = translate is StaticTranslate ? translate.position : null,
        _fadeAnimation = fade?.animation(animationController),
        assert(
          translate != StaticTranslate || fade != null,
          'Just use a plain Positioned widget if neither the translate nor the fade are animated',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
        return Positioned(
          width: size.width,
          height: size.height,
          left: _position?.x ?? _translateAnimation!.value.x,
          top: _position?.y ?? _translateAnimation!.value.y,
          child: _fadeAnimation == null
              ? child!
              : Opacity(
                  opacity: _fadeAnimation!.value,
                  child: child,
                ),
        );
      },
      child: child,
    );
  }
}
