import 'dart:math';

import 'package:flutter/material.dart';

Offset removeAlignment(Offset pos, double width, double height, Alignment alignment) {
  final left = 0.5 * width * (alignment.x + 1);
  final top = 0.5 * height * (alignment.y + 1);
  final x = pos.dx - (width - left);
  final y = pos.dy - (height - top);
  return Offset(x, y);
}
