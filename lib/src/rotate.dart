import 'package:flutter/widgets.dart';

@immutable
class Rotate {
  final double angle;
  final Offset? origin;
  final AlignmentGeometry? alignment;

  const Rotate({
    required this.angle,
    this.origin,
    this.alignment,
  });
}
