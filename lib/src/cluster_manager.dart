import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/core/distance_grid.dart';
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';

class ClusterManager {
  final MapCalculator mapCalculator;
  final Size predefinedSize;
  final Size Function(List<Marker>)? computeSize;

  late final Map<int, DistanceGrid<MarkerClusterNode>> _gridClusters;
  late final Map<int, DistanceGrid<MarkerNode>> _gridUnclustered;
  late MarkerClusterNode _topClusterLevel;

  MarkerClusterNode? spiderfyCluster;

  ClusterManager._({
    required this.mapCalculator,
    required this.predefinedSize,
    required this.computeSize,
    required Map<int, DistanceGrid<MarkerClusterNode>> gridClusters,
    required Map<int, DistanceGrid<MarkerNode>> gridUnclustered,
    required MarkerClusterNode topClusterLevel,
  })  : _gridClusters = gridClusters,
        _gridUnclustered = gridUnclustered,
        _topClusterLevel = topClusterLevel;

  factory ClusterManager.initialize({
    required MapCalculator mapCalculator,
    required Size predefinedSize,
    required Size Function(List<Marker>)? computeSize,
    required int minZoom,
    required int maxZoom,
    required int maxClusterRadius,
  }) {
    final gridClusters = <int, DistanceGrid<MarkerClusterNode>>{};
    final gridUnclustered = <int, DistanceGrid<MarkerNode>>{};

    for (var zoom = maxZoom; zoom >= minZoom; zoom--) {
      gridClusters[zoom] = DistanceGrid(maxClusterRadius);
      gridUnclustered[zoom] = DistanceGrid(maxClusterRadius);
    }

    final topClusterLevel = MarkerClusterNode(
      zoom: minZoom - 1,
      mapCalculator: mapCalculator,
      predefinedSize: predefinedSize,
      computeSize: computeSize,
    );

    return ClusterManager._(
      mapCalculator: mapCalculator,
      predefinedSize: predefinedSize,
      computeSize: computeSize,
      gridClusters: gridClusters,
      gridUnclustered: gridUnclustered,
      topClusterLevel: topClusterLevel,
    );
  }

  bool isSpiderfyCluster(MarkerClusterNode cluster) {
    return spiderfyCluster != null && spiderfyCluster!.point == cluster.point;
  }

  void addLayer(MarkerNode marker, int disableClusteringAtZoom, int maxZoom,
      int minZoom) {
    for (var zoom = maxZoom; zoom >= minZoom; zoom--) {
      var markerPoint =
          mapCalculator.project(marker.point, zoom: zoom.toDouble());
      if (zoom <= disableClusteringAtZoom) {
        // try find a cluster close by
        var cluster = _gridClusters[zoom]!.getNearObject(markerPoint);
        if (cluster != null) {
          cluster.addChild(marker);
          return;
        }

        var closest = _gridUnclustered[zoom]!.getNearObject(markerPoint);
        if (closest != null) {
          var parent = closest.parent!;
          parent.removeChild(closest);

          var newCluster = MarkerClusterNode(
            zoom: zoom,
            mapCalculator: mapCalculator,
            predefinedSize: predefinedSize,
            computeSize: computeSize,
          )
            ..addChild(closest)
            ..addChild(marker);

          _gridClusters[zoom]!.addObject(newCluster,
              mapCalculator.project(newCluster.point, zoom: zoom.toDouble()));

          //First create any new intermediate parent clusters that don't exist
          var lastParent = newCluster;
          for (var z = zoom - 1; z > parent.zoom; z--) {
            var newParent = MarkerClusterNode(
              zoom: z,
              mapCalculator: mapCalculator,
              predefinedSize: predefinedSize,
              computeSize: computeSize,
            );
            newParent.addChild(lastParent);
            lastParent = newParent;
            _gridClusters[z]!.addObject(
              lastParent,
              mapCalculator.project(
                closest.point,
                zoom: z.toDouble(),
              ),
            );
          }
          parent.addChild(lastParent);

          _removeFromNewPosToMyPosGridUnclustered(closest, zoom, minZoom);
          return;
        }
      }

      _gridUnclustered[zoom]!.addObject(marker, markerPoint);
    }

    //Didn't get in anything, add us to the top
    _topClusterLevel.addChild(marker);
  }

  void _removeFromNewPosToMyPosGridUnclustered(
      MarkerNode marker, int zoom, minZoom) {
    for (; zoom >= minZoom; zoom--) {
      if (!_gridUnclustered[zoom]!.removeObject(marker)) {
        break;
      }
    }
  }

  void recalculateTopClusterLevelBounds() =>
      _topClusterLevel.recalculateBounds();

  void recursivelyFromTopClusterLevel(
          int? zoomLevel, int disableClusteringAtZoom, Function(dynamic) fn) =>
      _topClusterLevel.recursively(zoomLevel, disableClusteringAtZoom, fn);
}
