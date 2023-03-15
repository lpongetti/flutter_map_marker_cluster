import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/core/util.dart' as util;
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:latlong2/latlong.dart';

@immutable
abstract class Translate {
  const Translate();

  Animation<Point<double>>? animation(AnimationController animationController);

  Point<double> get position;

  static Point<double> _getNodePixel(
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

  static Point<double> _getMarkerPixel(
    MapCalculator mapCalculator,
    MarkerNode marker, {
    LatLng? customPoint,
  }) {
    final pos = mapCalculator.getPixelFromPoint(customPoint ?? marker.point);
    return util.removeAnchor(pos, marker.width, marker.height, marker.anchor);
  }

  static Point<double> _getClusterPixel(
    MapCalculator mapCalculator,
    MarkerClusterNode clusterNode, {
    LatLng? customPoint,
  }) {
    final pos = mapCalculator
        .getPixelFromPoint(customPoint ?? clusterNode.bounds.center);

    final calculatedSize = clusterNode.size();
    final anchor = Anchor.forPos(
      clusterNode.anchorPos,
      calculatedSize.width,
      calculatedSize.height,
    );

    return util.removeAnchor(
      pos,
      calculatedSize.width,
      calculatedSize.height,
      anchor,
    );
  }
}

class StaticTranslate extends Translate {
  @override
  final Point<double> position;

  StaticTranslate(MapCalculator mapCalculator, MarkerOrClusterNode node)
      : position = Translate._getNodePixel(mapCalculator, node);

  @override
  Animation<Point<double>>? animation(
          AnimationController animationController) =>
      null;
}

class AnimatedTranslate extends Translate {
  @override
  final Point<double> position;
  final Point<double> newPosition;
  late final Tween<Point<double>> _tween;

  AnimatedTranslate.fromMyPosToNewPos({
    required MapCalculator mapCalculator,
    required MarkerOrClusterNode from,
    required MarkerClusterNode to,
  })  : position = Translate._getNodePixel(mapCalculator, from),
        newPosition = Translate._getNodePixel(
          mapCalculator,
          from,
          customPoint: to.bounds.center,
        ) {
    _tween = Tween<Point<double>>(
      begin: Point(position.x, position.y),
      end: Point(newPosition.x, newPosition.y),
    );
  }

  AnimatedTranslate.fromNewPosToMyPos({
    required MapCalculator mapCalculator,
    required MarkerOrClusterNode from,
    required MarkerClusterNode to,
  })  : position = Translate._getNodePixel(mapCalculator, from),
        newPosition = Translate._getNodePixel(
          mapCalculator,
          from,
          customPoint: to.bounds.center,
        ) {
    _tween = Tween<Point<double>>(
      begin: Point(newPosition.x, newPosition.y),
      end: Point(position.x, position.y),
    );
  }

  AnimatedTranslate.spiderfy({
    required MapCalculator mapCalculator,
    required MarkerClusterNode cluster,
    required MarkerNode marker,
    required Point point,
  })  : position = Translate._getMarkerPixel(
          mapCalculator,
          marker,
          customPoint: cluster.bounds.center,
        ),
        newPosition = util.removeAnchor(
          point,
          marker.width,
          marker.height,
          marker.anchor,
        ) {
    _tween = Tween<Point<double>>(
      begin: Point(position.x, position.y),
      end: Point(newPosition.x, newPosition.y),
    );
  }

  @override
  Animation<Point<double>> animation(AnimationController animationController) =>
      _tween.animate(animationController);
}
