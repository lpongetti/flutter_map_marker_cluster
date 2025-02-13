import 'dart:math';
import 'dart:ui';

class Spiderfy {
  static const pi2 = pi * 2;
  static const spiralFootSeparation = 28; //related to size of spiral (experiment!)
  static const spiralLengthStart = 11;
  static const spiralLengthFactor = 5;

  static const circleStartAngle = 0;

  static List<Offset?> spiral(int distanceMultiplier, int count, Offset center) {
    num legLength = distanceMultiplier * spiralLengthStart;
    final separation = distanceMultiplier * spiralFootSeparation;
    final lengthFactor = distanceMultiplier * spiralLengthFactor * pi2;
    num angle = 0;

    final result = List<Offset?>.filled(count, null, growable: false);

    // Higher index, closer position to cluster center.
    for (var i = count; i >= 0; i--) {
      // Skip the first position, so that we are already farther from center and we avoid
      // being under the default cluster icon (especially important for Circle Markers).
      if (i < count) {
        result[i] = Offset(center.dx + legLength * cos(angle), center.dy + legLength * sin(angle));
      }
      angle += separation / legLength + i * 0.0005;
      legLength += lengthFactor / angle;
    }
    return result;
  }

  static List<Offset?> circle(int radius, int count, Offset center) {
    final angleStep = pi2 / count;

    return List<Offset>.generate(count, (index) {
      final angle = circleStartAngle + index * angleStep;

      return Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
    });
  }
}
