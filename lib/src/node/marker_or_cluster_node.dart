import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';

/// Just a base class which MarkerNode and MarkerClusterNode both extend which
/// allows us to restrict arguments to one of those two classes without having
/// to resort to 'dynamic' which can hide bugs.
abstract class MarkerOrClusterNode {
  MarkerClusterNode? parent;

  MarkerOrClusterNode({required this.parent});

  Bounds<double> pixelBounds(FlutterMapState map);
}
