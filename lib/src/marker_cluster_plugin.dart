import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer_options.dart';

class MarkerClusterPlugin extends MapPlugin {
  MarkerClusterLayer _oldLayer;
  int _markersHashCode;

  /// Enable cluster recalculation on markers update. Default to false.
  final bool enableClusterRecalculationOnMarkersUpdate;

  MarkerClusterPlugin({
    this.enableClusterRecalculationOnMarkersUpdate = false,
  });

  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
    if (!enableClusterRecalculationOnMarkersUpdate) {
      return MarkerClusterLayer(options, mapState, stream);
    }

    MarkerClusterLayerOptions layerOptions = options;
    int hashCode;
    hashCode = layerOptions.markers.hashCode;

    if (hashCode == _markersHashCode) {
      if (_oldLayer != null) {
        return _oldLayer;
      } else {
        _oldLayer = MarkerClusterLayer(options, mapState, stream);
        return _oldLayer;
      }
    } else {
      _markersHashCode = hashCode;
      _oldLayer = MarkerClusterLayer(options, mapState, stream);
      return _oldLayer;
    }
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MarkerClusterLayerOptions;
  }
}
