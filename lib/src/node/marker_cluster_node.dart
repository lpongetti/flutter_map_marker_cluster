import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/core/util.dart' as util;
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong2/latlong.dart';

class MarkerClusterNode {
  final int zoom;
  final AnchorPos? anchorPos;
  final Size predefinedSize;
  final Size Function(List<Marker>)? computeSize;
  final MapCalculator mapCalculator;
  final List<dynamic> children;
  LatLngBounds bounds;
  MarkerClusterNode? parent;
  int? addCount;
  int? removeCount;

  List<MarkerNode> get markers {
    var markers = <MarkerNode>[];

    markers.addAll(children.whereType<MarkerNode>());

    for (final child in children) {
      if (child is MarkerClusterNode) {
        markers.addAll(child.markers);
      }
    }
    return markers;
  }

  MarkerClusterNode({
    required this.zoom,
    required this.anchorPos,
    required this.mapCalculator,
    required this.predefinedSize,
    this.computeSize,
  })  : bounds = LatLngBounds(),
        children = [],
        parent = null;

  LatLng get point {
    // Not sure if this is ideal to do ?? LatLng(0, 0)
    var swPoint = mapCalculator.project(bounds.southWest ?? LatLng(0, 0));
    var nePoint = mapCalculator.project(bounds.northEast ?? LatLng(0, 0));
    return mapCalculator.unproject((swPoint + nePoint) / 2);
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

    for (final marker in markers) {
      bounds.extend(marker.point);
    }

    for (final child in children) {
      if (child is MarkerClusterNode) {
        child.recalculateBounds();
      }
    }
  }

  void recursively(
      int? zoomLevel, int disableClusteringAtZoom, Function(dynamic) fn) {
    if (zoom == zoomLevel && zoomLevel! <= disableClusteringAtZoom) {
      fn(this);
      return;
    }

    for (var child in children) {
      if (child is MarkerNode) {
        fn(child);
      }
      if (child is MarkerClusterNode) {
        child.recursively(zoomLevel, disableClusteringAtZoom, fn);
      }
    }
  }

  List<Marker> get mapMarkers => markers.map((node) => node.marker).toList();

  Size size() => computeSize?.call(mapMarkers) ?? predefinedSize;

  Point<double> getPixel({LatLng? customPoint}) {
    final pos = mapCalculator.getPixelFromPoint(customPoint ?? point);

    var calculatedSize = size();
    var anchor =
        Anchor.forPos(anchorPos, calculatedSize.width, calculatedSize.height);

    return util.removeAnchor(
        pos, calculatedSize.width, calculatedSize.height, anchor);
  }
}
