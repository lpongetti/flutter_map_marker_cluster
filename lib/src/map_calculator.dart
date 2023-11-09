import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapCalculator {
  final MapCamera mapState;

  MapCalculator(this.mapState);

  Point<double> getPixelFromPoint(LatLng point) {
    return mapState
        .project(point)
        .subtract(mapState.pixelOrigin)
        .toDoublePoint();
  }

  Point<double> project(LatLng latLng, {double? zoom}) =>
      mapState.project(latLng, zoom);

  LatLng unproject(Point point, {double? zoom}) =>
      mapState.unproject(point, zoom);
}
