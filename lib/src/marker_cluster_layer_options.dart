import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

class PolygonOptions {
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool isDotted;

  const PolygonOptions({
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.isDotted = false,
  });
}

typedef ClusterWidgetBuilder = Widget Function(
    BuildContext context, List<Marker> markers);

class MarkerClusterLayerOptions extends LayerOptions {
  /// Cluster builder
  final ClusterWidgetBuilder builder;

  /// List of markers
  final List<Marker> markers;

  /// Cluster size
  final Size size;

  /// Cluster compute size
  final Size Function(List<Marker>) computeSize;

  /// Cluster anchor
  final AnchorPos anchor;

  /// A cluster will cover at most this many pixels from its center
  final int maxClusterRadius;

  /// Options for fit bounds
  final FitBoundsOptions fitBoundsOptions;

  /// Zoom buonds with animation on click cluster
  final bool zoomToBoundsOnClick;

  /// Duration for all animations
  final Duration animationDuration;

  /// When click marker, center it with animation
  final bool centerMarkerOnClick;

  /// Increase to increase the distance away that circle spiderfied markers appear from the center
  final int spiderfyCircleRadius;

  /// Increase to increase the distance away that spiral spiderfied markers appear from the center
  final int spiderfySpiralDistanceMultiplier;

  /// Show spiral instead of circle from this marker count upwards.
  /// 0 -> always spiral; Infinity -> always circle
  final int circleSpiralSwitchover;

  /// Make it possible to provide custom function to calculate spiderfy shape positions
  final List<Point> Function(int, Point) spiderfyShapePositions;

  /// If true show polygon then tap on cluster
  final bool showPolygon;

  /// Polygon's options that shown when tap cluster.
  final PolygonOptions polygonOptions;

  MarkerClusterLayerOptions({
    @required this.builder,
    this.markers = const [],
    this.size = const Size(30, 30),
    this.computeSize,
    this.anchor,
    this.maxClusterRadius = 80,
    this.animationDuration = const Duration(milliseconds: 500),
    this.fitBoundsOptions =
        const FitBoundsOptions(padding: EdgeInsets.all(12.0)),
    this.zoomToBoundsOnClick = true,
    this.centerMarkerOnClick = true,
    this.spiderfyCircleRadius = 40,
    this.spiderfySpiralDistanceMultiplier = 1,
    this.circleSpiralSwitchover = 9,
    this.spiderfyShapePositions,
    this.polygonOptions = const PolygonOptions(),
    this.showPolygon = true,
  }) : assert(builder != null);
}
