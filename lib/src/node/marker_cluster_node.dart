import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:latlong2/latlong.dart';

class _Derived {
  final markerNodes = <MarkerNode>[];
  late final LatLngBounds? bounds;
  late final List<Marker> markers;
  late final Size? size;

  _Derived(
    List<MarkerOrClusterNode> children,
    Size Function(List<Marker>)? computeSize, {
    required bool recursively,
  }) {
    markerNodes.addAll(children.whereType<MarkerNode>());

    // Depth first traversal.
    void dfs(MarkerClusterNode child) {
      for (final c in child.children) {
        if (c is MarkerClusterNode) {
          dfs(c);
        }
      }
      child.recalculate(recursively: false);
    }

    for (final child in children.whereType<MarkerClusterNode>()) {
      // If `recursively` is true, update children first from the leafs up.
      if (recursively) {
        dfs(child);
      }

      markerNodes.addAll(child.markers);
    }

    bounds = markerNodes.isEmpty
        ? null
        : LatLngBounds.fromPoints(List<LatLng>.generate(
            markerNodes.length, (index) => markerNodes[index].point));

    markers = markerNodes.map((m) => m.marker).toList();
    size = computeSize?.call(markers);
  }
}

class MarkerClusterNode extends MarkerOrClusterNode {
  final int zoom;
  final Alignment? alignment;
  final Size predefinedSize;
  final Size Function(List<Marker>)? computeSize;
  final children = <MarkerOrClusterNode>[];

  late _Derived _derived;

  MarkerClusterNode({
    required this.zoom,
    required this.alignment,
    required this.predefinedSize,
    this.computeSize,
  }) : super(parent: null) {
    _derived = _Derived(children, computeSize, recursively: false);
  }

  /// A list of all marker nodex recursively, i.e including child layers.
  List<MarkerNode> get markers => _derived.markerNodes;

  /// A list of all Marker widgets recursively, i.e. including child layers.
  List<Marker> get mapMarkers => _derived.markers;

  /// LatLong bounds of the transitive markers covered by this cluster.
  /// Note, hacky way of dealing with now null-safe LatLngBounds. Ideally we'd
  // return null here for nodes that are empty and don't have bounds.
  LatLngBounds get bounds =>
      _derived.bounds ?? LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));

  Size size() => _derived.size ?? predefinedSize;

  void addChild(MarkerOrClusterNode child, LatLng childPoint) {
    children.add(child);
    child.parent = this;
    recalculate(recursively: false);
  }

  void removeChild(MarkerOrClusterNode child) {
    children.remove(child);
    recalculate(recursively: false);
  }

  void recalculate({required bool recursively}) {
    _derived = _Derived(children, computeSize, recursively: recursively);
  }

  void recursively(
    int zoomLevel,
    int disableClusteringAtZoom,
    LatLngBounds recursionBounds,
    Function(MarkerOrClusterNode node) fn,
  ) {
    if (zoom == zoomLevel && zoomLevel <= disableClusteringAtZoom) {
      fn(this);

      // Stop recursion. We've recursed to the point where we won't
      // draw any smaller levels
      return;
    }
    assert(zoom <= disableClusteringAtZoom,
        '$zoom $disableClusteringAtZoom $zoomLevel');

    for (final child in children) {
      if (child is MarkerNode) {
        fn(child);
      } else if (child is MarkerClusterNode) {
        // OPTIMIZATION: Skip clusters that don't overlap with given recursion
        // (map) bounds. Their markers would get culled later anyway.
        if (recursionBounds.isOverlapping(child.bounds)) {
          child.recursively(
              zoomLevel, disableClusteringAtZoom, recursionBounds, fn);
        }
      }
    }
  }

  @override
  Rect pixelBounds(MapCamera map) {
    final center = map.projectAtZoom(bounds.center);
    final alignment = this.alignment ?? Alignment.center;
    final size = this.size();

    // Calculate offset from center based on alignment
    final offsetX = size.width * (alignment.x - 1) * 0.5; // -1 to 0 range
    final offsetY = size.height * (alignment.y - 1) * 0.5; // -1 to 0 range

    // Calculate top-left corner
    final topLeft = Offset(
      center.dx + offsetX,
      center.dy + offsetY,
    );

    // Calculate bottom-right corner
    final bottomRight = Offset(
      topLeft.dx + size.width,
      topLeft.dy + size.height,
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }
}
