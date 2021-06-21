import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import '../flutter_map_marker_cluster.dart';

class MarkerClusterLayerWidget extends StatelessWidget {
  final MarkerClusterLayerOptions options;

  MarkerClusterLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return MarkerClusterLayer(options, mapState, mapState.onMoved);
  }
}
