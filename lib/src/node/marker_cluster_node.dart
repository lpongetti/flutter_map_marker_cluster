import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong/latlong.dart';

class MarkerClusterNode {
  final int zoom;
  final MapState map;
  final List<dynamic> children;
  LatLngBounds bounds;
  MarkerClusterNode parent;
  int addCount;
  int removeCount;

  List<MarkerNode> get markers {
    List<MarkerNode> markers = [];

    markers.addAll(children.whereType<MarkerNode>());

    children.forEach((child) {
      if (child is MarkerClusterNode) {
        markers.addAll(child.markers);
      }
    });
    return markers;
  }

  MarkerClusterNode({
    @required this.zoom,
    @required this.map,
  })  : bounds = LatLngBounds(),
        children = [],
        parent = null;

  LatLng get point {
    var swPoint = map.project(bounds.southWest);
    var nePoint = map.project(bounds.northEast);
    return map.unproject((swPoint + nePoint) / 2);
  }

  addChild(dynamic child) {
    assert(child is MarkerNode || child is MarkerClusterNode);
    children.add(child);
    child.parent = this;
    bounds.extend(child.point);
  }

  removeChild(dynamic child) {
    children.remove(child);
    recalculateBounds();
  }

  recalculateBounds() {
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

  recursively(int zoomLevel, Function(dynamic) fn) {
    if (zoom == zoomLevel) {
      fn(this);
      return;
    }

    children.forEach((child) {
      if (child is MarkerNode) {
        fn(child);
      }
      if (child is MarkerClusterNode) {
        child.recursively(zoomLevel, fn);
      }
    });
  }
}
