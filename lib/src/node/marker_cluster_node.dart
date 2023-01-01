import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:latlong2/latlong.dart';

class _Derived {
  final markerNodes = <MarkerNode>[];
  final bounds = LatLngBounds();
  late final List<Marker> markers;
  late final Size? size;

  _Derived(List<MarkerOrClusterNode> children,
      Size Function(List<Marker>)? computeSize) {
    markerNodes.addAll(children.whereType<MarkerNode>());
    for (final child in children) {
      if (child is MarkerClusterNode) {
        markerNodes.addAll(child.markers);
      }
    }

    for (final marker in markerNodes) {
      bounds.extend(marker.point);
    }

    markers = markerNodes.map((m) => m.marker).toList();
    size = (computeSize != null) ? computeSize(markers) : null;
  }
}

class MarkerClusterNode extends MarkerOrClusterNode {
  final int zoom;
  final AnchorPos? anchorPos;
  final Size predefinedSize;
  final Size Function(List<Marker>)? computeSize;
  final children = <MarkerOrClusterNode>[];

  late _Derived _derived;

  List<MarkerNode> get markers => _derived.markerNodes;
  LatLngBounds get bounds => _derived.bounds;
  List<Marker> get mapMarkers => _derived.markers;
  Size size() => _derived.size ?? predefinedSize;

  MarkerClusterNode({
    required this.zoom,
    required this.anchorPos,
    required this.predefinedSize,
    this.computeSize,
  }) : super(parent: null) {
    _derived = _Derived(children, computeSize);
  }

  void addChild(MarkerOrClusterNode child, LatLng childPoint) {
    children.add(child);
    child.parent = this;
    recalculateBounds();
  }

  void removeChild(MarkerOrClusterNode child) {
    children.remove(child);
    recalculateBounds();
  }

  void recalculateBounds() {
    _derived = _Derived(children, computeSize);
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
      } else if (child is MarkerClusterNode) {
        child.recursively(zoomLevel, disableClusteringAtZoom, fn);
      }
    }
  }

  @override
  Bounds pixelBounds(FlutterMapState map) {
    final width = size().width;
    final height = size().height;
    final anchor = Anchor.forPos(anchorPos, width, height);

    final rightPortion = width - anchor.left;
    final leftPortion = anchor.left;
    final bottomPortion = height - anchor.top;
    final topPortion = anchor.top;

    final ne =
        map.project(bounds.northEast!) + CustomPoint(rightPortion, -topPortion);
    final sw = map.project(bounds.southWest!) +
        CustomPoint(-leftPortion, bottomPortion);

    return Bounds(ne, sw);
  }
}
