import 'dart:math';

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
  Anchor? get anchor => marker.anchor;

  @override
  Bounds<double> pixelBounds(MapCamera map) {
    final pixelPoint = map.project(point);

    final ankr = anchor ??
        Anchor.fromPos(
          AnchorPos.defaultAnchorPos,
          width,
          height,
        );

    final rightPortion = width - ankr.left;
    final leftPortion = ankr.left;
    final bottomPortion = height - ankr.top;
    final topPortion = ankr.top;

    final ne = Point(pixelPoint.x - rightPortion, pixelPoint.y + topPortion);
    final sw = Point(pixelPoint.x + leftPortion, pixelPoint.y - bottomPortion);

    return Bounds(ne, sw);
  }
}
