import 'dart:ui';

import 'package:flutter/src/painting/alignment.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:latlong2/latlong.dart';

class MarkerNode implements Marker {
  final Marker marker;
  MarkerClusterNode? parent;

  MarkerNode(this.marker);

  @override
  Anchor get anchor => marker.anchor;

  @override
  get builder => marker.builder;

  @override
  double get height => marker.height;

  @override
  LatLng get point => marker.point;

  @override
  double get width => marker.width;

  @override
  // TODO: implement rotate
  bool? get rotate => throw UnimplementedError();

  @override
  // TODO: implement rotateAlignment
  AlignmentGeometry? get rotateAlignment => throw UnimplementedError();

  @override
  // TODO: implement rotateOrigin
  Offset? get rotateOrigin => throw UnimplementedError();
}
