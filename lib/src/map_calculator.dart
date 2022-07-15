import 'dart:math';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong2/latlong.dart';

class MapCalculator {
  final MapState mapState;

  MapCalculator(this.mapState);

  CustomPoint<num> getPixelFromPoint(LatLng point) {
    final pos = mapState.project(point);
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

  LatLng clusterPoint(MarkerClusterNode cluster) {
    final swPoint = project(cluster.bounds.southWest!);
    final nePoint = project(cluster.bounds.northEast!);
    return unproject((swPoint + nePoint) / 2);
  }

  bool boundsContainsCluster(
      MarkerClusterNode cluster, List<Point<num>?>? points) {
    final pixelPoint = mapState.project(clusterPoint(cluster));

    final size = cluster.size();

    final anchor = Anchor.forPos(cluster.anchorPos, size.width, size.height);
    if (points != null) {
      //assumin all markers of the cluster are same size. Normally more caluclations are needed to find the exact size on screen
      return _boundsSpiderContains(
          pixelPoint,
          size.width,
          size.height,
          anchor,
          points,
          cluster.markers.first.marker.width,
          cluster.markers.first.marker.height);
    } else {
      return _boundsContains(pixelPoint, size.width, size.height, anchor);
    }
  }

  bool _boundsSpiderContains(
      CustomPoint pixelPoint,
      double width,
      double height,
      Anchor anchor,
      List<Point<num>?> points,
      double markerWidth,
      double markerHeigth) {
    final leftMost = points.reduce((a, b) {
          if (a!.x < b!.x) {
            return a;
          } else {
            return b;
          }
        })!.x -
        markerWidth / 2.0;
    final rigthMost = points.reduce((a, b) {
          if (a!.x > b!.x) {
            return a;
          } else {
            return b;
          }
        })!.x +
        markerWidth / 2.0;
    final topMost = points.reduce((a, b) {
          if (a!.y < b!.y) {
            return a;
          } else {
            return b;
          }
        })!.y -
        markerHeigth / 2.0;
    final bottomMost = points.reduce((a, b) {
          if (a!.y > b!.y) {
            return a;
          } else {
            return b;
          }
        })!.x +
        markerHeigth / 2.0;
    final rightPortion = width - anchor.left;
    final leftPortion = anchor.left;
    final bottomPortion = height - anchor.top;
    final topPortion = anchor.top;

    final sw = CustomPoint(
        pixelPoint.x + 2 * leftPortion, pixelPoint.y - 2 * bottomPortion);
    final ne = CustomPoint(
        pixelPoint.x - 2 * rightPortion, pixelPoint.y + 2 * topPortion);

    return mapState.pixelBounds.containsPartialBounds(Bounds(sw, ne));
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
