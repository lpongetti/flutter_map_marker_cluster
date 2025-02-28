import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapCalculator {
  final MapCamera mapState;

  MapCalculator(this.mapState);

  Offset getPixelFromPoint(LatLng point) {
    final Offset pxPoint = mapState.projectAtZoom(point);
    return Offset(pxPoint.dx - mapState.pixelOrigin.dx, pxPoint.dy - mapState.pixelOrigin.dy);
  }

  Offset project(LatLng latLng, {double? zoom}) => mapState.projectAtZoom(latLng, zoom);

  LatLng unproject(Offset point, {double? zoom}) => mapState.unprojectAtZoom(point, zoom);
}
