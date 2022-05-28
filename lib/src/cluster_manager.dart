import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/core/distance_grid.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong2/latlong.dart';

class ClusterManager {
  late final Map<int, DistanceGrid<MarkerClusterNode>> _gridClusters;
  late final Map<int, DistanceGrid<MarkerNode>> _gridUnclustered;
  late MarkerClusterNode _topClusterLevel;
  MarkerClusterNode? spiderfyCluster;

  final CustomPoint Function(LatLng latlng, [double? zoom]) project;
  final LatLng Function(CustomPoint point, [double? zoom]) unproject;

  ClusterManager._({
    required Map<int, DistanceGrid<MarkerClusterNode>> gridClusters,
    required Map<int, DistanceGrid<MarkerNode>> gridUnclustered,
    required MarkerClusterNode topClusterLevel,
    required this.project,
    required this.unproject,
  })  : _gridClusters = gridClusters,
        _gridUnclustered = gridUnclustered,
        _topClusterLevel = topClusterLevel;

  factory ClusterManager.initialize({
    required int minZoom,
    required int maxZoom,
    required int maxClusterRadius,
    required CustomPoint Function(LatLng latLng, [double? zoom]) project,
    required LatLng Function(CustomPoint point, [double? zoom]) unproject,
  }) {
    final gridClusters = <int, DistanceGrid<MarkerClusterNode>>{};
    final gridUnclustered = <int, DistanceGrid<MarkerNode>>{};

    for (var zoom = maxZoom; zoom >= minZoom; zoom--) {
      gridClusters[zoom] = DistanceGrid(maxClusterRadius);
      gridUnclustered[zoom] = DistanceGrid(maxClusterRadius);
    }

    final topClusterLevel = MarkerClusterNode(
      zoom: minZoom - 1,
      project: project,
      unproject: unproject,
    );

    return ClusterManager._(
      gridClusters: gridClusters,
      gridUnclustered: gridUnclustered,
      topClusterLevel: topClusterLevel,
      project: project,
      unproject: unproject,
    );
  }

  bool isSpiderfyCluster(MarkerClusterNode cluster) {
    return spiderfyCluster != null && spiderfyCluster!.point == cluster.point;
  }

  void addLayer(MarkerNode marker, int disableClusteringAtZoom, int maxZoom,
      int minZoom) {
    for (var zoom = maxZoom; zoom >= minZoom; zoom--) {
      var markerPoint = project(marker.point, zoom.toDouble());
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
              zoom: zoom, project: project, unproject: unproject)
            ..addChild(closest)
            ..addChild(marker);

          _gridClusters[zoom]!.addObject(
              newCluster, project(newCluster.point, zoom.toDouble()));

          //First create any new intermediate parent clusters that don't exist
          var lastParent = newCluster;
          for (var z = zoom - 1; z > parent.zoom; z--) {
            var newParent = MarkerClusterNode(
              zoom: z,
              project: project,
              unproject: unproject,
            );
            newParent.addChild(lastParent);
            lastParent = newParent;
            _gridClusters[z]!
                .addObject(lastParent, project(closest.point, z.toDouble()));
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
