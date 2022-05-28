import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class MapCalculator {
  final MapState mapState;

  MapCalculator(this.mapState);

  CustomPoint<num> getPixelFromPoint(LatLng point) {
    var pos = mapState.project(point);
    return pos.multiplyBy(mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
        mapState.getPixelOrigin();
  }
}
