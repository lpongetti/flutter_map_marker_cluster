import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class PolygonOptions {
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final StrokePattern pattern;

  const PolygonOptions({
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.pattern = const StrokePattern.solid(),
  });
}

class AnimationsOptions {
  final Curve fadeInCurve;
  final Curve fadeOutCurve;
  final Curve clusterExpandCurve;
  final Curve clusterCollapseCurve;
  final Curve sipderifyCurve;
  final Duration zoom;
  final Duration fitBound;
  final Curve fitBoundCurves;
  final Duration centerMarker;
  final Curve centerMarkerCurves;
  final Duration spiderfy;

  const AnimationsOptions({
    this.zoom = const Duration(milliseconds: 500),
    this.fitBound = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeInCubic,
    this.fadeOutCurve = Curves.easeInCubic,
    this.clusterExpandCurve = Curves.easeInCubic,
    this.clusterCollapseCurve = Curves.easeInCubic,
    this.sipderifyCurve = Curves.fastOutSlowIn,
    this.centerMarker = const Duration(milliseconds: 500),
    this.spiderfy = const Duration(milliseconds: 500),
    this.fitBoundCurves = Curves.fastOutSlowIn,
    this.centerMarkerCurves = Curves.fastOutSlowIn,
  });
}

typedef ClusterWidgetBuilder = Widget Function(
    BuildContext context, List<Marker> markers);

class MarkerClusterLayerOptions {
  /// Cluster builder
  final ClusterWidgetBuilder builder;

  /// List of markers
  final List<Marker> markers;

  /// If true markers will be counter rotated to the map rotation
  final bool? rotate;

  /// Cluster size
  final Size size;

  /// Cluster compute size
  final Size Function(List<Marker>)? computeSize;

  /// Cluster anchor
  final Alignment? alignment;

  /// A cluster will cover at most this many pixels from its center
  final int maxClusterRadius;

  /// Zoom bounds with animation on click cluster
  final bool zoomToBoundsOnClick;

  /// animations options
  final AnimationsOptions animationsOptions;

  /// When click marker, center it with animation
  final bool centerMarkerOnClick;

  /// If false remove spiderfy effect on tap
  final bool spiderfyCluster;

  /// Increase to increase the distance away that circle spiderfied markers appear from the center
  final int spiderfyCircleRadius;

  /// If set, at this zoom level and below, markers will not be clustered. This defaults to 20 (max zoom)
  final int disableClusteringAtZoom;

  /// Increase to increase the distance away that spiral spiderfied markers appear from the center
  final int spiderfySpiralDistanceMultiplier;

  /// Show spiral instead of circle from this marker count upwards.
  /// 0 -> always spiral; Infinity -> always circle
  final int circleSpiralSwitchover;

  /// Make it possible to provide custom function to calculate spiderfy shape positions
  final List<Offset> Function(int, Offset)? spiderfyShapePositions;

  /// If true show polygon then tap on cluster
  final bool showPolygon;

  /// Polygon's options that shown when tap cluster.
  final PolygonOptions polygonOptions;

  /// Function to call when a Marker is tapped
  final void Function(Marker)? onMarkerTap;

  /// Function to call when a Marker is double tapped
  final void Function(Marker)? onMarkerDoubleTap;

  /// Function to call when a Marker starts to be hovered
  final void Function(Marker)? onMarkerHoverEnter;

  /// Function to call when a Marker stops to be hovered
  final void Function(Marker)? onMarkerHoverExit;

  /// Function to call when markers are clustered
  final void Function(List<Marker>)? onMarkersClustered;

  /// Function to call when a cluster Marker is tapped
  final void Function(MarkerClusterNode)? onClusterTap;

  ///If set to [true] the marker will have only gesture behavior that is provided by the marker child.
  ///Can be used in cases where the marker child is a widget that already has gesture behavior and [GestureDetector] from the [MarkerClusterLayer] is interfering with it.
  ///If set to [true] [onMarkerTap] [onMarkerHoverEnter] [onMarkerHoverExit] [centerMarkerOnClick] will not work.
  ///
  ///Defaults to [false].
  final bool markerChildBehavior;

  final bool autoCenterAndExpand;

  final EdgeInsets padding;
  final double maxZoom;
  final bool inside;

  /// By default calculations will return fractional zoom levels.
  /// If this parameter is set to [true] fractional zoom levels will be round
  /// to the next suitable integer.
  final bool forceIntegerZoomLevel;

  MarkerClusterLayerOptions({
    required this.builder,
    this.rotate,
    this.markers = const [],
    this.size = const Size(30, 30),
    this.autoCenterAndExpand = true,
    this.computeSize,
    this.alignment,
    this.maxClusterRadius = 80,
    this.disableClusteringAtZoom = 20,
    this.animationsOptions = const AnimationsOptions(),
    this.padding = EdgeInsets.zero,
    this.maxZoom = 17.0,
    this.inside = false,
    this.forceIntegerZoomLevel = false,
    this.zoomToBoundsOnClick = true,
    this.centerMarkerOnClick = true,
    this.spiderfyCircleRadius = 40,
    this.spiderfySpiralDistanceMultiplier = 1,
    this.circleSpiralSwitchover = 9,
    this.spiderfyShapePositions,
    this.spiderfyCluster = true,
    this.polygonOptions = const PolygonOptions(),
    this.showPolygon = true,
    this.onMarkerTap,
    this.onMarkerDoubleTap,
    this.onMarkerHoverEnter,
    this.onMarkerHoverExit,
    this.onClusterTap,
    this.onMarkersClustered,
    this.markerChildBehavior = false,
  });
}
