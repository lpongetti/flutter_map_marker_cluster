import 'dart:math';

import 'package:flutter/material.dart';

Point<double> removeAlignment(
    Point pos, double width, double height, Alignment alignment) {
  final left = 0.5 * width * (alignment.x + 1);
  final top = 0.5 * height * (alignment.y + 1);
  final x = pos.x - (width - left);
  final y = pos.y - (height - top);
  return Point(x, y);
}
