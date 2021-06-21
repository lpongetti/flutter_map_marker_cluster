import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong2/latlong.dart';

class MarkerClusterNode {
  final int zoom;
  final MapState map;
  final List<dynamic> children;
  LatLngBounds bounds;
  MarkerClusterNode? parent;
  int? addCount;
  int? removeCount;

  List<MarkerNode> get markers {
    var markers = <MarkerNode>[];

    markers.addAll(children.whereType<MarkerNode>());

    children.forEach((child) {
      if (child is MarkerClusterNode) {
        markers.addAll(child.markers);
      }
    });
    return markers;
  }

  MarkerClusterNode({
    required this.zoom,
    required this.map,
  })  : bounds = LatLngBounds(),
        children = [],
        parent = null;

  LatLng get point {
    // Not sure if this is ideal to do ?? LatLng(0, 0)
    var swPoint = map.project(bounds.southWest ?? LatLng(0, 0));
    var nePoint = map.project(bounds.northEast ?? LatLng(0, 0));
    return map.unproject((swPoint + nePoint) / 2);
  }

  void addChild(dynamic child) {
    assert(child is MarkerNode || child is MarkerClusterNode);
    children.add(child);
    child.parent = this;
    bounds.extend(child.point);
  }

  void removeChild(dynamic child) {
    children.remove(child);
    recalculateBounds();
  }

  void recalculateBounds() {
    bounds = LatLngBounds();

    markers.forEach((marker) {
      bounds.extend(marker.point);
    });

    children.forEach((child) {
      if (child is MarkerClusterNode) {
        child.recalculateBounds();
      }
    });
  }

  void recursively(
      int? zoomLevel, int disableClusteringAtZoom, Function(dynamic) fn) {
    if (zoom == zoomLevel && zoomLevel! <= disableClusteringAtZoom) {
      fn(this);
      return;
    }

    children.forEach((child) {
      if (child is MarkerNode) {
        fn(child);
      }
      if (child is MarkerClusterNode) {
        child.recursively(zoomLevel, disableClusteringAtZoom, fn);
      }
    });
  }
}
