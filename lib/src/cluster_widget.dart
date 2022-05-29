import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster/src/anim_type.dart';
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';

class ClusterWidget extends StatelessWidget {
  final MarkerClusterNode cluster;
  final ClusterWidgetBuilder builder;
  final MapCalculator mapCalculator;
  final AnimationController movementController;
  final VoidCallback onTap;
  final Animation<double>? fadeAnimation;
  final Animation<Point>? Function(AnimationController? controller,
      TranslateType translate, Point pos, Point? newPos) translateAnimation;

  final TranslateType translateType;
  final Point? newPos;

  ClusterWidget.spiderfy({
    required this.cluster,
    required this.builder,
    required this.mapCalculator,
    required AnimationController spiderfyController,
    required this.onTap,
  })  : movementController = spiderfyController,
        fadeAnimation =
            Tween<double>(begin: 1.0, end: 0.3).animate(spiderfyController),
        translateAnimation = ((_, __, ___, ____) => null),
        translateType = TranslateType.none,
        newPos = null;

  ClusterWidget({
    required this.cluster,
    required this.builder,
    required this.mapCalculator,
    required this.movementController,
    required this.onTap,
    required this.translateAnimation,
    this.fadeAnimation,
    this.translateType = TranslateType.none,
    this.newPos,
  }) : assert((translateType == TranslateType.none && newPos == null) ||
            (translateType != TranslateType.none && newPos != null));

  @override
  Widget build(BuildContext context) {
    final pos = cluster.getPixel();

    final translateAnimationCalculated =
        translateAnimation.call(movementController, translateType, pos, newPos);

    final size = cluster.size();

    return AnimatedBuilder(
      animation: movementController,
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
            opacity: fadeAnimation?.value ?? 1,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: builder(context, cluster.mapMarkers),
      ),
    );
  }
}
