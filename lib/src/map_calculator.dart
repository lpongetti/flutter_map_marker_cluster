import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class MapCalculator {
  final FlutterMapState mapState;

  MapCalculator(this.mapState);

  CustomPoint<num> getPixelFromPoint(LatLng point) {
    final pos = mapState.project(point);
    return pos.multiplyBy(mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
        mapState.pixelOrigin;
  }

  CustomPoint project(LatLng latLng, {double? zoom}) =>
      mapState.project(latLng, zoom);

  LatLng unproject(CustomPoint point, {double? zoom}) =>
      mapState.unproject(point, zoom);
}
