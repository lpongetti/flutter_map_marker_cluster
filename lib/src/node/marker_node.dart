import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:latlong2/latlong.dart';

class MarkerNode extends MarkerOrClusterNode implements Marker {
  final Marker marker;

  MarkerNode(this.marker) : super(parent: null);

  @override
  Key? get key => marker.key;

  @override
  Anchor get anchor => marker.anchor;

  @override
  WidgetBuilder get builder => marker.builder;

  @override
  double get height => marker.height;

  @override
  LatLng get point => marker.point;

  @override
  double get width => marker.width;

  @override
  bool? get rotate => marker.rotate;

  @override
  AlignmentGeometry? get rotateAlignment => marker.rotateAlignment;

  @override
  Offset? get rotateOrigin => marker.rotateOrigin;

  @override
  Bounds<double> pixelBounds(FlutterMapState map) {
    final pixelPoint = map.project(point);

    final rightPortion = width - anchor.left;
    final leftPortion = anchor.left;
    final bottomPortion = height - anchor.top;
    final topPortion = anchor.top;

    final ne =
        CustomPoint(pixelPoint.x - rightPortion, pixelPoint.y + topPortion);
    final sw =
        CustomPoint(pixelPoint.x + leftPortion, pixelPoint.y - bottomPortion);

    return Bounds(ne, sw);
  }
}
