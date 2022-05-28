import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:latlong2/latlong.dart';

class SpiderfyClusterWidget extends StatelessWidget {
  final MarkerClusterNode cluster;

  final ClusterWidgetBuilder builder;
  final MapCalculator mapCalculator;

  final VoidCallback onTap;
  final Size Function(MarkerClusterNode cluster) getClusterSize;
  final AnimationController spiderfyController;
  final Point Function(MarkerClusterNode cluster, {LatLng? customPoint})
      getPixelFromCluster;

  final int? zoom;

  SpiderfyClusterWidget({
    required this.cluster,
    required this.builder,
    required this.mapCalculator,
    required this.onTap,
    required this.getClusterSize,
    required this.spiderfyController,
    required this.getPixelFromCluster,
    this.zoom,
  });

  @override
  Widget build(BuildContext context) {
    final pos = getPixelFromCluster(cluster);

    final fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.3).animate(spiderfyController);

    var size = getClusterSize(cluster);

    return AnimatedBuilder(
      animation: spiderfyController,
      builder: (BuildContext context, Widget? child) {
        return Positioned(
          width: size.width,
          height: size.height,
          left: pos.x as double?,
          top: pos.y as double?,
          child: Opacity(
            opacity: fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: builder(
          context,
          cluster.markers.map((node) => node.marker).toList(),
        ),
      ),
    );
  }
}
