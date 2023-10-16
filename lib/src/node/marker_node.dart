import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:latlong2/latlong.dart';

// ignore: must_be_immutable
class MarkerNode extends MarkerOrClusterNode implements Marker {
  final Marker marker;

  MarkerNode(this.marker) : super(parent: null);

  @override
  Key? get key => marker.key;

  @override
  Widget get child => marker.child;

  @override
  double get height => marker.height;

  @override
  LatLng get point => marker.point;

  @override
  double get width => marker.width;

  @override
  bool? get rotate => marker.rotate;

  @override
  Alignment? get alignment => marker.alignment;

  @override
  Bounds<double> pixelBounds(MapCamera map) {
    final pixelPoint = map.project(point);

    final left = 0.5 * width * ((alignment ?? Alignment.center).x + 1);
    final top = 0.5 * height * ((alignment ?? Alignment.center).y + 1);
    final right = width - left;
    final bottom = height - top;

    return Bounds(
      Point(pixelPoint.x + left, pixelPoint.y - bottom),
      Point(pixelPoint.x - right, pixelPoint.y + top),
    );
  }
}
