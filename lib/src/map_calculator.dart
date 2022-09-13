import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong2/latlong.dart';

class MapCalculator {
  final FlutterMapState mapState;

  MapCalculator(this.mapState);

  CustomPoint<num> getPixelFromPoint(LatLng point) {
    final pos = mapState.project(point);
    return pos.multiplyBy(mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
        mapState.pixelOrigin;
  }

  bool boundsContainsMarker(MarkerNode marker) {
    return _boundsContains(
      mapState.project(marker.point),
      marker.width,
      marker.height,
      marker.anchor,
    );
  }

  LatLng clusterPoint(MarkerClusterNode cluster) {
    final swPoint = project(cluster.bounds.southWest!);
    final nePoint = project(cluster.bounds.northEast!);
    return unproject((swPoint + nePoint) / 2);
  }

  bool boundsContainsCluster(MarkerClusterNode cluster) {
    final pixelPoint = mapState.project(clusterPoint(cluster));
    final size = cluster.size();
    final anchor = Anchor.forPos(cluster.anchorPos, size.width, size.height);

    return _boundsContains(pixelPoint, size.width, size.height, anchor);
  }

  bool _boundsContains(
    CustomPoint pixelPoint,
    double width,
    double height,
    Anchor anchor,
  ) {
    final rightPortion = width - anchor.left;
    final leftPortion = anchor.left;
    final bottomPortion = height - anchor.top;
    final topPortion = anchor.top;

    final sw =
        CustomPoint(pixelPoint.x + leftPortion, pixelPoint.y - bottomPortion);
    final ne =
        CustomPoint(pixelPoint.x - rightPortion, pixelPoint.y + topPortion);

    return mapState.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  CustomPoint project(LatLng latLng, {double? zoom}) =>
      mapState.project(latLng, zoom);

  LatLng unproject(CustomPoint point, {double? zoom}) =>
      mapState.unproject(point, zoom);
}
