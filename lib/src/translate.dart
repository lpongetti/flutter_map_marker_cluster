import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/src/core/util.dart' as util;
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:latlong2/latlong.dart';

@immutable
abstract class Translate {
  const Translate();

  Animation<Offset>? animation(AnimationController animationController);

  Offset get position;

  static Offset _getNodePixel(
    MapCalculator mapCalculator,
    MarkerOrClusterNode node, {
    LatLng? customPoint,
  }) {
    if (node is MarkerNode) {
      return _getMarkerPixel(mapCalculator, node, customPoint: customPoint);
    } else if (node is MarkerClusterNode) {
      return _getClusterPixel(mapCalculator, node, customPoint: customPoint);
    } else {
      throw ArgumentError(
        'Unknown node type when calculating pixel: ${node.runtimeType}',
      );
    }
  }

  static Offset _getMarkerPixel(
    MapCalculator mapCalculator,
    MarkerNode marker, {
    LatLng? customPoint,
  }) {
    final pos = mapCalculator.getPixelFromPoint(customPoint ?? marker.point);
    return util.removeAlignment(pos, marker.width, marker.height, marker.alignment ?? Alignment.center);
  }

  static Offset _getClusterPixel(
    MapCalculator mapCalculator,
    MarkerClusterNode clusterNode, {
    LatLng? customPoint,
  }) {
    final pos = mapCalculator.getPixelFromPoint(customPoint ?? clusterNode.bounds.center);

    final calculatedSize = clusterNode.size();

    return util.removeAlignment(
      pos,
      calculatedSize.width,
      calculatedSize.height,
      clusterNode.alignment ?? Alignment.center,
    );
  }
}

class StaticTranslate extends Translate {
  @override
  final Offset position;

  StaticTranslate(MapCalculator mapCalculator, MarkerOrClusterNode node) : position = Translate._getNodePixel(mapCalculator, node);

  @override
  Animation<Offset>? animation(AnimationController animationController) => null;
}

class AnimatedTranslate extends Translate {
  @override
  final Offset position;
  final Offset newPosition;
  late final Tween<Offset> _tween;
  final Curve curve;
  AnimatedTranslate.fromMyPosToNewPos({
    required MapCalculator mapCalculator,
    required MarkerOrClusterNode from,
    required MarkerClusterNode to,
    required this.curve,
  })  : position = Translate._getNodePixel(mapCalculator, from),
        newPosition = Translate._getNodePixel(
          mapCalculator,
          from,
          customPoint: to.bounds.center,
        ) {
    _tween = Tween<Offset>(
      begin: Offset(position.dx, position.dy),
      end: Offset(newPosition.dx, newPosition.dy),
    );
  }

  AnimatedTranslate.fromNewPosToMyPos({
    required MapCalculator mapCalculator,
    required MarkerOrClusterNode from,
    required MarkerClusterNode to,
    required this.curve,
  })  : position = Translate._getNodePixel(mapCalculator, from),
        newPosition = Translate._getNodePixel(
          mapCalculator,
          from,
          customPoint: to.bounds.center,
        ) {
    _tween = Tween<Offset>(
      begin: Offset(newPosition.dx, newPosition.dy),
      end: Offset(position.dx, position.dy),
    );
  }

  AnimatedTranslate.spiderfy({
    required MapCalculator mapCalculator,
    required MarkerClusterNode cluster,
    required MarkerNode marker,
    required Offset point,
    required this.curve,
  })  : position = Translate._getMarkerPixel(
          mapCalculator,
          marker,
          customPoint: cluster.bounds.center,
        ),
        newPosition = util.removeAlignment(
          point,
          marker.width,
          marker.height,
          marker.alignment ?? Alignment.center,
        ) {
    _tween = Tween<Offset>(
      begin: Offset(position.dx, position.dy),
      end: Offset(newPosition.dx, newPosition.dy),
    );
  }

  @override
  Animation<Offset> animation(AnimationController animationController) => _tween.chain(CurveTween(curve: curve)).animate(animationController);
}
