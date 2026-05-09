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
  Rect pixelBounds(MapCamera map) {
    final center = map.projectAtZoom(point);
    final alignment = this.alignment ?? Alignment.center;

    // Calculate offset from center based on alignment
    final offsetX = width * (alignment.x - 1) * 0.5; // -1 to 0 range
    final offsetY = height * (alignment.y - 1) * 0.5; // -1 to 0 range

    final topLeft = Offset(center.dx + offsetX, center.dy + offsetY);
    final bottomRight = Offset(topLeft.dx + width, topLeft.dy + height);

    return Rect.fromPoints(topLeft, bottomRight);
  }
}
