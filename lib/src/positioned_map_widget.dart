import 'dart:math';

import 'package:flutter/widgets.dart';

class PositionedMapWidget extends StatelessWidget {
  final Size size;
  final Widget child;
  final Point<double> position;

  PositionedMapWidget({
    required this.child,
    required this.size,
    required this.position,
    required ObjectKey key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: size.width,
      height: size.height,
      left: position.x,
      top: position.y,
      child: child,
    );
  }
}
