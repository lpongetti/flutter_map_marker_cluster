import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/src/cluster_controller.dart';

/// Manager for coordinating multiple cluster controllers
/// 
/// Ensures only one cluster is active at a time across all managed controllers.
/// This prevents multiple clusters from being open simultaneously, providing
/// a better user experience.
/// 
/// Example usage:
/// ```dart
/// final manager = ClusterControllerManager();
/// final controller1 = ClusterController(manager: manager);
/// final controller2 = ClusterController(manager: manager);
/// 
/// // Only one cluster can be active at a time
/// // Opening a cluster on controller1 will close any on controller2
/// ```
class ClusterControllerManager {
  final List<ClusterController> _controllers = [];
  
  /// Notifier that tracks which controller is currently active
  /// 
  /// Value will be null when no controller has an active cluster.
  /// Listen to this to react to active controller changes:
  /// ```dart
  /// manager.activeController.addListener(() {
  ///   final active = manager.activeController.value;
  ///   if (active != null) {
  ///     print('Controller ${active.hashCode} is now active');
  ///   } else {
  ///     print('No active controller');
  ///   }
  /// });
  /// ```
  final ValueNotifier<ClusterController?> activeController =
      ValueNotifier(null);

  /// Adds a controller to be managed by this manager
  /// 
  /// Controllers are automatically added when created with this manager,
  /// but this method can be used to add controllers after creation.
  void addController(ClusterController controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  /// Removes a controller from management
  /// 
  /// Controllers are automatically removed when disposed, but this method
  /// can be used to remove controllers without disposing them.
  void removeController(ClusterController controller) {
    _controllers.remove(controller);
    if (activeController.value == controller) {
      activeController.value = null;
    }
  }

  /// Closes all clusters managed by all controllers
  /// 
  /// This will trigger close animations for any open clusters and set
  /// the active controller to null.
  void closeAll() {
    setActive(null);
  }

  /// Checks if any managed controller has an open cluster
  /// 
  /// Returns true if any controller managed by this manager has an active cluster
  bool hasAnyOpen() {
    return activeController.value != null;
  }

  /// Sets the active controller, closing clusters on all other controllers
  /// 
  /// [controller] - The controller to make active, or null to close all clusters
  /// 
  /// This ensures only one cluster is open at a time across all managed controllers.
  void setActive(ClusterController? controller) {
    scheduleMicrotask(() {
      activeController.value = controller;
    });
    for (final c in _controllers) {
      if (c != controller) {
        // Handle potential close errors gracefully
        try {
          c.close();
        } catch (e) {
          // Continue closing other controllers even if one fails
        }
      }
    }
  }
}