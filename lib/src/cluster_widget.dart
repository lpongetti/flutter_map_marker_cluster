import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster/src/anim_type.dart';
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:latlong2/latlong.dart';

class ClusterWidget extends StatelessWidget {
  final MarkerClusterNode cluster;
  final ClusterWidgetBuilder builder;
  final MapCalculator mapCalculator;
  final AnimationController zoomController;
  final VoidCallback onTap;
  final Point Function(MarkerClusterNode cluster, {LatLng? customPoint})
      getPixelFromCluster;
  final Animation<double>? Function(
      AnimationController? controller, FadeType fadeType) fadeAnimation;
  final Animation<Point>? Function(AnimationController? controller,
      TranslateType translate, Point pos, Point? newPos) translateAnimation;

  final FadeType fadeType;
  final TranslateType translateType;
  final Point? newPos;

  ClusterWidget({
    required this.cluster,
    required this.builder,
    required this.mapCalculator,
    required this.zoomController,
    required this.onTap,
    required this.getPixelFromCluster,
    required this.fadeAnimation,
    required this.translateAnimation,
    this.fadeType = FadeType.none,
    this.translateType = TranslateType.none,
    this.newPos,
  }) : assert((translateType == TranslateType.none && newPos == null) ||
            (translateType != TranslateType.none && newPos != null));

  @override
  Widget build(BuildContext context) {
    final pos = getPixelFromCluster(cluster);

    final fadeAnimationCalculated = fadeAnimation(zoomController, fadeType);
    final translateAnimationCalculated =
        translateAnimation(zoomController, translateType, pos, newPos);

    final size = cluster.size();

    return AnimatedBuilder(
      animation: zoomController,
      builder: (BuildContext context, Widget? child) {
        return Positioned(
          width: size.width,
          height: size.height,
          left: translateType == TranslateType.none
              ? pos.x as double?
              : translateAnimationCalculated!.value.x as double?,
          top: translateType == TranslateType.none
              ? pos.y as double?
              : translateAnimationCalculated!.value.y as double?,
          child: Opacity(
            opacity:
                fadeType == FadeType.none ? 1 : fadeAnimationCalculated!.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: builder(
          context,
          cluster.mapMarkers,
        ),
      ),
    );
  }
}
