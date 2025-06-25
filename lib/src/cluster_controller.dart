import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/src/cluster_controller_manager.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';

/// Controller for managing individual cluster interactions and state.
///
/// Provides methods to check cluster state, close clusters, and manage
/// expand/contract events. Each controller instance manages one cluster layer.
class ClusterController {
  // Internal reference to the layer state - managed by the layer itself
  MarkerClusterLayerState? _state;

  /// Optional manager for coordinating multiple cluster controllers
  final ClusterControllerManager? manager;

  /// Notifier that indicates whether this controller's cluster is expanded
  ///
  /// Listen to this to react to cluster expand/contract events:
  /// ```dart
  /// controller.onExpandCluster.addListener(() {
  ///   if (controller.onExpandCluster.value) {
  ///     print('Cluster expanded');
  ///   } else {
  ///     print('Cluster contracted');
  ///   }
  /// });
  /// ```
  final onExpandCluster = ValueNotifier(false);

  /// Creates a new cluster controller
  ///
  /// [manager] - Optional manager for coordinating with other controllers
  ClusterController({this.manager}) {
    manager?.addController(this);
  }

  /// Used internally to update the state from the cluster and call the methods.
  void $updateState(MarkerClusterLayerState? newState) {
    _state = newState;
  }

  /// Checks if a specific cluster is currently open (spiderfied)
  ///
  /// Returns true if [cluster] is the currently open cluster, false otherwise
  bool isClusterOpen(MarkerClusterNode? cluster) {
    return _state?.spiderfyCluster == cluster;
  }

  /// Whether any cluster managed by this controller is currently open
  bool get isOpen {
    return _state?.spiderfyCluster != null;
  }

  /// Closes any open cluster managed by this controller
  ///
  /// This will trigger the cluster collapse animation if a cluster is open.
  /// Safe to call even if no cluster is open.
  Future<void> close() async {
    if (_state?.mounted == true) {
      try {
        await _state?.closeCluster();
      } catch (e) {
        // Silently handle animation errors during close
      }
    }
  }

  /// Internal method called when cluster contracts - handles state updates
  void onClusterContract() {
    if (onExpandCluster.value == false) {
      return;
    }
    onExpandCluster.value = false;
    if (manager?.activeController.value == this) {
      manager?.setActive(null);
    }
  }

  /// Internal method called when cluster expands - handles state updates
  void onClusterExpand() {
    onExpandCluster.value = true;
    manager?.setActive(this);
  }

  /// Disposes of this controller and cleans up resources
  ///
  /// Call this when the controller is no longer needed to prevent memory leaks
  void dispose() {
    manager?.removeController(this);
    onExpandCluster.dispose();
  }
}
