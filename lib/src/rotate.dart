import 'package:flutter/widgets.dart';

@immutable
class Rotate {
  final double angle;
  final Alignment? alignment;

  const Rotate({
    required this.angle,
    this.alignment,
  });
}
