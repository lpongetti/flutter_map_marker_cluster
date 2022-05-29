import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map_marker_cluster/src/fade.dart';
import 'package:flutter_map_marker_cluster/src/map_widget.dart';
import 'package:flutter_map_marker_cluster/src/rotate.dart';
import 'package:flutter_map_marker_cluster/src/translate.dart';

class AnimatedMapWidget extends MapWidget {
  final Widget child;
  final Size size;
  final AnimationController animationController;
  final Animation<Point<double>>? _translateAnimation;
  final Rotate? rotate;
  final Point<double>? _position;
  final Animation<double>? _fadeAnimation;

  AnimatedMapWidget({
    required this.child,
    required this.size,
    required this.animationController,
    required Translate translate,
    this.rotate,
    Fade? fade,
    Key? key,
  })  : _translateAnimation = translate.animation(animationController),
        _position = translate is StaticTranslate ? translate.position : null,
        _fadeAnimation = fade?.animation(animationController),
        super.withKey(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
        final childWithRotation = rotate == null
            ? child
            : Transform.rotate(
                angle: rotate!.angle,
                origin: rotate!.origin,
                alignment: rotate!.alignment,
                child: child,
              );

        return Positioned(
          width: size.width,
          height: size.height,
          left: _position?.x ?? _translateAnimation!.value.x,
          top: _position?.y ?? _translateAnimation!.value.y,
          child: _fadeAnimation == null
              ? childWithRotation!
              : Opacity(
                  opacity: _fadeAnimation!.value,
                  child: childWithRotation,
                ),
        );
      },
      child: child,
    );
  }
}
