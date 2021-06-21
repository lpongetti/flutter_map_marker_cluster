import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer_options.dart';

class MarkerClusterPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    return MarkerClusterLayer(
        options as MarkerClusterLayerOptions, mapState, stream);
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MarkerClusterLayerOptions;
  }
}
