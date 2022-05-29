import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong2/latlong.dart';

class MapCalculator {
  final MapState mapState;

  MapCalculator(this.mapState);

  CustomPoint<num> getPixelFromPoint(LatLng point) {
    var pos = mapState.project(point);
    return pos.multiplyBy(mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
        mapState.getPixelOrigin();
  }

  bool boundsContainsMarker(MarkerNode marker) {
    return _boundsContains(
      mapState.project(marker.point),
      marker.width,
      marker.height,
      marker.anchor,
    );
  }

  bool boundsContainsCluster(MarkerClusterNode cluster) {
    final pixelPoint = mapState.project(cluster.point);
    var size = cluster.size();
    var anchor = Anchor.forPos(cluster.anchorPos, size.width, size.height);

    return _boundsContains(pixelPoint, size.width, size.height, anchor);
  }

  bool _boundsContains(
    CustomPoint pixelPoint,
    double width,
    double height,
    Anchor anchor,
  ) {
    width = width - anchor.left;
    height = height - anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return mapState.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  CustomPoint project(LatLng latLng, {double? zoom}) =>
      mapState.project(latLng, zoom);

  LatLng unproject(CustomPoint point, {double? zoom}) =>
      mapState.unproject(point, zoom);
}
