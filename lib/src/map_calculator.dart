import 'dart:math';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class MapCalculator {
  final MapCamera mapState;

  MapCalculator(this.mapState);

  Point<num> getPixelFromPoint(LatLng point) {
    final pos = mapState.project(point);
    return pos * mapState.getZoomScale(mapState.zoom, mapState.zoom) -
        mapState.pixelOrigin.toDoublePoint();
  }

  Point project(LatLng latLng, {double? zoom}) =>
      mapState.project(latLng, zoom);

  LatLng unproject(Point point, {double? zoom}) =>
      mapState.unproject(point, zoom);
}
