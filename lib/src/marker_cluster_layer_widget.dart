import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class MarkerClusterLayerWidget extends StatelessWidget {
  final MarkerClusterLayerOptions options;

  const MarkerClusterLayerWidget({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    final mapController = MapController.of(context);
    final mapCamera = MapCamera.of(context);

    return MarkerClusterLayer(
      mapController: mapController,
      mapCamera: mapCamera,
      options: options,
    );
  }
}
