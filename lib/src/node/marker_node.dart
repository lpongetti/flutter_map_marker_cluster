import 'dart:ui';

import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/painting/alignment.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:latlong2/latlong.dart';

class MarkerNode implements Marker {
  final Marker marker;
  MarkerClusterNode? parent;

  MarkerNode(this.marker);

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
}
