import 'dart:math';

import 'package:flutter_map/flutter_map.dart';

class Spiderfy {
  static final pi2 = pi * 2;
  static const spiralFootSeparation =
      28; //related to size of spiral (experiment!)
  static const spiralLengthStart = 11;
  static const spiralLengthFactor = 5;

  static const circleStartAngle = 0;

  static List<Point> spiral(int distanceMultiplier, int count, Point center) {
    num legLength = distanceMultiplier * spiralLengthStart;
    final separation = distanceMultiplier * spiralFootSeparation;
    final lengthFactor = distanceMultiplier * spiralLengthFactor * pi2;
    num angle = 0;

    final result = List<Point>(count);
    // Higher index, closer position to cluster center.
    for (var i = count; i >= 0; i--) {
      // Skip the first position, so that we are already farther from center and we avoid
      // being under the default cluster icon (especially important for Circle Markers).
      if (i < count) {
        result[i] = Point(center.x + legLength * cos(angle),
            center.y + legLength * sin(angle));
      }
      angle += separation / legLength + i * 0.0005;
      legLength += lengthFactor / angle;
    }
    return result;
  }

  static List<Point> circle(int radius, int count, Point center) {
    double angleStep = pi2 / count;
    final result = List<Point>(count);

    for (var i = 0; i < count; i++) {
      double angle = circleStartAngle + i * angleStep;

      result[i] = CustomPoint<double>(
          center.x + radius * cos(angle), center.y + radius * sin(angle));
    }
    return result;
  }
}
