import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:latlong2/latlong.dart';

class MarkerClusterNode extends MarkerOrClusterNode {
  final int zoom;
  final AnchorPos? anchorPos;
  final Size predefinedSize;
  final Size Function(List<Marker>)? computeSize;
  final List<MarkerOrClusterNode> children;
  LatLngBounds bounds;
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
    required this.predefinedSize,
    this.computeSize,
  })  : bounds = LatLngBounds(),
        children = [],
        super(parent: null);

  void addChild(MarkerOrClusterNode child, LatLng childPoint) {
    children.add(child);
    child.parent = this;
    bounds.extend(childPoint);
  }

  void removeChild(MarkerOrClusterNode child) {
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
    int? zoomLevel,
    int disableClusteringAtZoom,
    Function(MarkerOrClusterNode node) fn,
  ) {
    if (zoom == zoomLevel && zoomLevel! <= disableClusteringAtZoom) {
      fn(this);
      return;
    }

    for (final child in children) {
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
}
