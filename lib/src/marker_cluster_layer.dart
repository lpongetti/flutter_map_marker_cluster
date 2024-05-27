import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster/src/cluster_manager.dart';
import 'package:flutter_map_marker_cluster/src/cluster_widget.dart';
import 'package:flutter_map_marker_cluster/src/core/quick_hull.dart';
import 'package:flutter_map_marker_cluster/src/core/spiderfy.dart';
import 'package:flutter_map_marker_cluster/src/fade.dart';
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/map_widget.dart';
import 'package:flutter_map_marker_cluster/src/marker_widget.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/rotate.dart';
import 'package:flutter_map_marker_cluster/src/translate.dart';
import 'package:latlong2/latlong.dart';

class MarkerClusterLayer extends StatefulWidget {
  final MarkerClusterLayerOptions options;
  final MapController mapController;
  final MapCamera mapCamera;

  const MarkerClusterLayer({
    required this.mapController,
    required this.mapCamera,
    required this.options,
    super.key,
  });

  @override
  State<MarkerClusterLayer> createState() => _MarkerClusterLayerState();
}

class _MarkerClusterLayerState extends State<MarkerClusterLayer>
    with TickerProviderStateMixin {
  late MapCalculator _mapCalculator;
  late ClusterManager _clusterManager;
  late int _maxZoom;
  late int _minZoom;
  late int _currentZoom;
  late int _previousZoom;
  late double _previousZoomDouble;
  late AnimationController _zoomController;
  late AnimationController _fitBoundController;
  late AnimationController _centerMarkerController;
  late AnimationController _spiderfyController;

  PolygonLayer? _polygon;
  MarkerClusterNode? spiderfyCluster;

  _MarkerClusterLayerState();

  bool _isSpiderfyCluster(MarkerClusterNode cluster) {
    return spiderfyCluster != null &&
        spiderfyCluster!.bounds.center == cluster.bounds.center;
  }

  bool get _animating =>
      _zoomController.isAnimating ||
      _fitBoundController.isAnimating ||
      _centerMarkerController.isAnimating ||
      _spiderfyController.isAnimating;

  bool get _zoomingIn =>
      _zoomController.isAnimating && _currentZoom > _previousZoom;

  bool get _zoomingOut =>
      _zoomController.isAnimating && _currentZoom < _previousZoom;

  @override
  void initState() {
    _mapCalculator = MapCalculator(widget.mapCamera);

    _currentZoom = _previousZoom = widget.mapCamera.zoom.ceil();
    _previousZoomDouble = widget.mapCamera.zoom;
    _minZoom = widget.mapCamera.minZoom?.ceil() ?? 1;
    _maxZoom = widget.mapCamera.maxZoom?.floor() ?? 20;
    _previousZoomDouble = widget.mapCamera.zoom;
    _initializeAnimationControllers();
    _initializeClusterManager();
    _addLayers();

    _zoomController.forward();

    super.initState();
  }

  void _initializeAnimationControllers() {
    _zoomController = AnimationController(
      vsync: this,
      duration: widget.options.animationsOptions.zoom,
    );

    _fitBoundController = AnimationController(
      vsync: this,
      duration: widget.options.animationsOptions.fitBound,
    );

    _centerMarkerController = AnimationController(
      vsync: this,
      duration: widget.options.animationsOptions.centerMarker,
    );

    _spiderfyController = AnimationController(
      vsync: this,
      duration: widget.options.animationsOptions.spiderfy,
    );
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _fitBoundController.dispose();
    _centerMarkerController.dispose();
    _spiderfyController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MarkerClusterLayer oldWidget) {
    if (oldWidget.options.markers != widget.options.markers) {
      _initializeClusterManager();
      _addLayers();
    }
    if (oldWidget.mapCamera.pixelOrigin != widget.mapCamera.pixelOrigin) {
      _mapCalculator = MapCalculator(widget.mapCamera);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _initializeClusterManager() {
    _clusterManager = ClusterManager.initialize(
      alignment: widget.options.alignment,
      mapCalculator: _mapCalculator,
      predefinedSize: widget.options.size,
      computeSize: widget.options.computeSize,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      maxClusterRadius: widget.options.maxClusterRadius,
    );
  }

  void _addLayers() {
    for (final marker in widget.options.markers) {
      _clusterManager.addLayer(
        MarkerNode(marker),
        widget.options.disableClusteringAtZoom,
        _maxZoom,
        _minZoom,
      );
    }

    _clusterManager.recalculateTopClusterLevelProperties();
  }

  @override
  Widget build(BuildContext context) {
    final popupOptions = widget.options.popupOptions;
    return Stack(
      children: [
        // Keep the layers in a MobileTransformStack
        MobileLayerTransformer(
          child: Stack(
            children: _buildMobileTransformStack(),
          ),
        ),
        // Move the PopupLayer outside the MobileLayerTransformer since it has its own
        if (popupOptions != null)
          PopupLayer(
            popupDisplayOptions: PopupDisplayOptions(
              builder: popupOptions.popupBuilder,
              animation: popupOptions.popupAnimation,
              snap: popupOptions.popupSnap,
            ),
          )
      ],
    );
  }

  Widget _buildMarker({
    required MarkerNode marker,
    required AnimationController controller,
    required Translate translate,
    Fade? fade,
  }) {
    return MapWidget(
      size: Size(marker.width, marker.height),
      animationController: controller,
      translate: translate,
      fade: fade,
      rotate: marker.rotate != true && widget.options.rotate != true
          ? null
          : Rotate(
              angle: -widget.mapCamera.rotationRad,
              alignment: marker.alignment,
            ),
      key: marker.key ?? ObjectKey(marker.marker),
      child: MarkerWidget(
        marker: marker,
        markerChildBehavior: widget.options.markerChildBehavior,
        onTap: _onMarkerTap(marker),
        onDoubleTap: _onMarkerDoubleTap(marker),
        onHover: (bool value) => _onMarkerHover(marker, value),
        buildOnHover: widget.options.popupOptions?.buildPopupOnHover ?? false,
      ),
    );
  }

  /// Function that is called when the marker is hover (if popup building on hover is selected).
  /// if enter == true then it's onHoverEnter, if enter == false it's onHoverExit
  void _onMarkerHover(MarkerNode marker, bool enter) {
    if (_zoomController.isAnimating ||
        _centerMarkerController.isAnimating ||
        _fitBoundController.isAnimating) return;

    if (widget.options.popupOptions != null) {
      final popupOptions = widget.options.popupOptions!;
      enter
          ? Future.delayed(
              Duration(
                  milliseconds: popupOptions.timeToShowPopupOnHover >= 0
                      ? popupOptions.timeToShowPopupOnHover
                      : 0), () {
              popupOptions.markerTapBehavior.apply(
                PopupSpec.wrap(marker.marker),
                PopupState.maybeOf(context, listen: false)!,
                popupOptions.popupController,
              );
            })
          : popupOptions.popupController.hideAllPopups();
    }

    if (widget.options.onMarkerTap != null) {
      enter
          ? widget.options.onMarkerHoverEnter?.call(marker.marker)
          : widget.options.onMarkerHoverExit?.call(marker.marker);
    }
  }

  void _spiderfy(MarkerClusterNode cluster) {
    setState(() {
      spiderfyCluster = cluster;
    });
    _spiderfyController.forward();
  }

  Future<void> _unspiderfy() async {
    switch (_spiderfyController.status) {
      case AnimationStatus.completed:
        final markersGettingClustered = spiderfyCluster?.markers
            .map((markerNode) => markerNode.marker)
            .toList();

        if (widget.options.popupOptions != null &&
            markersGettingClustered != null) {
          widget.options.popupOptions!.popupController.hidePopupsOnlyFor(
            markersGettingClustered,
          );
        }
        if (widget.options.onMarkersClustered != null &&
            markersGettingClustered != null) {
          widget.options.onMarkersClustered!(markersGettingClustered);
        }

        await _spiderfyController.reverse().then(
              (_) => setState(() {
                spiderfyCluster = null;
              }),
            );
        break;
      case AnimationStatus.forward:
        final markersGettingClustered = spiderfyCluster?.markers
            .map((markerNode) => markerNode.marker)
            .toList();

        if (markersGettingClustered != null) {
          widget.options.popupOptions?.popupController
              .hidePopupsOnlyFor(markersGettingClustered);
          widget.options.onMarkersClustered?.call(markersGettingClustered);
        }

        _spiderfyController.stop();
        await _spiderfyController.reverse().then(
              (_) => setState(() {
                spiderfyCluster = null;
              }),
            );
        break;
      default:
        break;
    }
  }

  void _addMarkerLayer(MarkerNode markerNode, List<Widget> layers) {
    if (_zoomingIn && markerNode.parent!.zoom == _previousZoom) {
      _addZoomingInMarkerLayer(markerNode, layers);
    } else {
      layers.add(_buildMarker(
        marker: markerNode,
        controller: _zoomController,
        translate: StaticTranslate(_mapCalculator, markerNode),
      ));
    }
  }

  void _addZoomingInMarkerLayer(MarkerNode markerNode, List<Widget> layers) {
    layers.add(
      _buildMarker(
        marker: markerNode,
        controller: _zoomController,
        fade: Fade.fadeIn(curve: widget.options.animationsOptions.fadeInCurve),
        translate: AnimatedTranslate.fromNewPosToMyPos(
          mapCalculator: _mapCalculator,
          from: markerNode,
          to: markerNode.parent!,
          curve: widget.options.animationsOptions.clusterExpandCurve,
        ),
      ),
    );

    // parent
    layers.add(
      MapWidget(
        size: markerNode.parent!.size(),
        animationController: _zoomController,
        translate: StaticTranslate(_mapCalculator, markerNode.parent!),
        rotate: widget.options.rotate != true
            ? null
            : Rotate(
                angle: -widget.mapCamera.rotationRad,
                alignment: widget.options.alignment,
              ),
        fade:
            Fade.fadeOut(curve: widget.options.animationsOptions.fadeOutCurve),
        child: ClusterWidget(
          cluster: markerNode.parent!,
          builder: widget.options.builder,
          onTap: _onClusterTap(markerNode.parent!),
        ),
      ),
    );
  }

  void _addMarkerClusterLayer(MarkerClusterNode clusterNode,
      List<Widget> layers, List<Widget> spiderfyLayers) {
    if (_zoomingOut && clusterNode.children.length > 1) {
      _addClusterClosingLayer(clusterNode, layers);
    } else if (_zoomingIn &&
        clusterNode.parent!.bounds.center != clusterNode.bounds.center) {
      _addClusterOpeningLayer(clusterNode, layers);
    } else if (_isSpiderfyCluster(clusterNode)) {
      spiderfyLayers.addAll(_buildSpiderfyCluster(clusterNode, _currentZoom));
    } else {
      layers.add(
        MapWidget.static(
          key: ObjectKey(clusterNode),
          size: clusterNode.size(),
          translate: StaticTranslate(_mapCalculator, clusterNode),
          rotate: widget.options.rotate != true
              ? null
              : Rotate(
                  angle: -widget.mapCamera.rotationRad,
                  alignment: widget.options.alignment,
                ),
          child: ClusterWidget(
            cluster: clusterNode,
            builder: widget.options.builder,
            onTap: _onClusterTap(clusterNode),
          ),
        ),
      );
    }
  }

  void _addClusterClosingLayer(
      MarkerClusterNode clusterNode, List<Widget> layers) {
    // cluster
    layers.add(
      MapWidget(
        size: clusterNode.size(),
        animationController: _zoomController,
        translate: StaticTranslate(_mapCalculator, clusterNode),
        fade: Fade.fadeIn(curve: widget.options.animationsOptions.fadeInCurve),
        rotate: widget.options.rotate != true
            ? null
            : Rotate(
                angle: -widget.mapCamera.rotationRad,
                alignment: widget.options.alignment,
              ),
        child: ClusterWidget(
          cluster: clusterNode,
          builder: widget.options.builder,
          onTap: _onClusterTap(clusterNode),
        ),
      ),
    );

    // children
    final markersGettingClustered = <Marker>[];
    for (final child in clusterNode.children) {
      if (child is MarkerNode) {
        markersGettingClustered.add(child.marker);

        layers.add(
          _buildMarker(
            marker: child,
            controller: _zoomController,
            fade: Fade.fadeOut(
                curve: widget.options.animationsOptions.fadeOutCurve),
            translate: AnimatedTranslate.fromMyPosToNewPos(
              mapCalculator: _mapCalculator,
              from: child,
              to: clusterNode,
              curve: widget.options.animationsOptions.clusterCollapseCurve,
            ),
          ),
        );
      } else {
        child as MarkerClusterNode;
        layers.add(
          MapWidget(
            size: child.size(),
            animationController: _zoomController,
            translate: AnimatedTranslate.fromMyPosToNewPos(
              mapCalculator: _mapCalculator,
              from: child,
              to: clusterNode,
              curve: widget.options.animationsOptions.clusterCollapseCurve,
            ),
            rotate: widget.options.rotate != true
                ? null
                : Rotate(
                    angle: -widget.mapCamera.rotationRad,
                    alignment: widget.options.alignment,
                  ),
            fade: Fade.fadeOut(
                curve: widget.options.animationsOptions.fadeOutCurve),
            child: ClusterWidget(
              cluster: child,
              builder: widget.options.builder,
              onTap: _onClusterTap(child),
            ),
          ),
        );
      }
    }

    widget.options.popupOptions?.popupController.hidePopupsOnlyFor(
      markersGettingClustered,
    );
    widget.options.onMarkersClustered?.call(markersGettingClustered);
  }

  void _addClusterOpeningLayer(
      MarkerClusterNode clusterNode, List<Widget> layers) {
    // cluster
    layers.add(MapWidget(
      size: clusterNode.size(),
      animationController: _zoomController,
      translate: AnimatedTranslate.fromNewPosToMyPos(
        mapCalculator: _mapCalculator,
        from: clusterNode,
        to: clusterNode.parent!,
        curve: widget.options.animationsOptions.clusterCollapseCurve,
      ),
      rotate: widget.options.rotate != true
          ? null
          : Rotate(
              angle: -widget.mapCamera.rotationRad,
              alignment: widget.options.alignment,
            ),
      fade: Fade.fadeIn(curve: widget.options.animationsOptions.fadeInCurve),
      child: ClusterWidget(
        cluster: clusterNode,
        builder: widget.options.builder,
        onTap: _onClusterTap(clusterNode),
      ),
    ));
    //parent
    layers.add(MapWidget(
      size: clusterNode.parent!.size(),
      animationController: _zoomController,
      translate: StaticTranslate(_mapCalculator, clusterNode.parent!),
      rotate: widget.options.rotate != true
          ? null
          : Rotate(
              angle: -widget.mapCamera.rotationRad,
              alignment: widget.options.alignment,
            ),
      fade: Fade.fadeOut(curve: widget.options.animationsOptions.fadeOutCurve),
      child: ClusterWidget(
        cluster: clusterNode.parent!,
        builder: widget.options.builder,
        onTap: _onClusterTap(clusterNode.parent!),
      ),
    ));
  }

  List<Widget> _buildSpiderfyCluster(
    MarkerClusterNode cluster,
    int currentZoom,
  ) {
    final results = <Widget>[];
    results.add(
      MapWidget(
        size: cluster.size(),
        animationController: _spiderfyController,
        translate: StaticTranslate(_mapCalculator, cluster),
        rotate: widget.options.rotate != true
            ? null
            : Rotate(
                angle: -widget.mapCamera.rotationRad,
                alignment: widget.options.alignment,
              ),
        fade: Fade.almostFadeOut(
            curve: widget.options.animationsOptions.fadeOutCurve),
        child: ClusterWidget(
          cluster: cluster,
          builder: widget.options.builder,
          onTap: _onClusterTap(cluster),
        ),
      ),
    );
    final points = _generatePointSpiderfy(
      cluster.markers.length,
      _mapCalculator.getPixelFromPoint(cluster.bounds.center),
    );

    for (var i = 0; i < cluster.markers.length; i++) {
      final marker = cluster.markers[i];

      results.add(
        _buildMarker(
          marker: marker,
          controller: _spiderfyController,
          fade:
              Fade.fadeIn(curve: widget.options.animationsOptions.fadeInCurve),
          translate: AnimatedTranslate.spiderfy(
            mapCalculator: _mapCalculator,
            cluster: cluster,
            marker: marker,
            point: points[i]!,
            curve: widget.options.animationsOptions.sipderifyCurve,
          ),
        ),
      );
    }
    return results;
  }

  List<Widget> _buildMobileTransformStack() {
    if (widget.mapCamera.zoom != _previousZoomDouble) {
      _previousZoomDouble = widget.mapCamera.zoom;
      _unspiderfy();
    }

    final zoom = widget.mapCamera.zoom.ceil();
    final layers = <Widget>[];
    final spiderfyLayers = <Widget>[];

    if (_polygon != null) layers.add(_polygon!);

    if (zoom < _currentZoom || zoom > _currentZoom) {
      _previousZoom = _currentZoom;
      _currentZoom = zoom;

      _zoomController
        ..reset()
        ..forward().then(
          (_) {
            if (mounted) {
              setState(() {
                _hidePolygon();
              });
            }
          },
        );
    }

    // We bounds so that we only recurse into clusters that stick into a
    // bounding box that is 4x the size of what's on screen (i.e. stick on
    // factor of 0.5 for the lack of a better name). Note that this could lead
    // to visual glitches if someone had markers that are larger than the map
    // viewport itself. Doing that however would be very silly, i.e. you
    // wouldn't see the map anymore because it's entirely covered by the
    // marker.
    final recursionBounds = _extendBounds(
      widget.mapCamera.visibleBounds,
      0.5,
    );

    _clusterManager.recursivelyFromTopClusterLevel(
        _currentZoom, widget.options.disableClusteringAtZoom, recursionBounds,
        (MarkerOrClusterNode layer) {
      // This is the performance critical hot path recursed on every map event!

      // Cull markers/clusters that are not on screen.
      if (!widget.mapCamera.pixelBounds.containsPartialBounds(
        layer.pixelBounds(widget.mapCamera),
      )) {
        return;
      }

      if (layer is MarkerNode) {
        _addMarkerLayer(layer, layers);
      } else if (layer is MarkerClusterNode) {
        _addMarkerClusterLayer(layer, layers, spiderfyLayers);
      } else {
        throw 'Unexpected layer type: ${layer.runtimeType}';
      }
    });

    // ensures the spiderfy layers markers are on top of other markers and clusters
    layers.addAll(spiderfyLayers);
    return layers;
  }

  VoidCallback _onClusterTap(MarkerClusterNode cluster) {
    return () async {
      if (_animating) return;

      widget.options.onClusterTap?.call(cluster);

      if (!widget.options.zoomToBoundsOnClick) {
        if (widget.options.spiderfyCluster) {
          if (spiderfyCluster != null) {
            if (spiderfyCluster == cluster) {
              _unspiderfy();
              return;
            } else {
              await _unspiderfy();
            }
          }
          _spiderfy(cluster);
        }
        return;
      }

      final center = widget.mapCamera.center;
      // CenterZoom dest = widget.mapController.centerZoomFitBounds(
      //   cluster.bounds,
      //   options: widget.options.fitBoundsOptions,
      // );
      final opt = widget.options;
      MapCamera dest = CameraFit.bounds(
        bounds: cluster.bounds,
        padding: opt.padding,
        maxZoom: opt.maxZoom,
        forceIntegerZoomLevel: opt.forceIntegerZoomLevel,
      ).fit(widget.mapCamera);

      // check if children can un-cluster
      final cannotDivide = cluster.markers.every((marker) =>
              marker.parent!.zoom == _maxZoom &&
              marker.parent == cluster.markers.first.parent) ||
          (dest.zoom == _currentZoom && _currentZoom == opt.maxZoom);

      if (cannotDivide) {
        //dest = CenterZoom(center: dest.center, zoom: _currentZoom.toDouble());
        dest = MapCamera(
            crs: dest.crs,
            center: dest.center,
            zoom: _currentZoom.toDouble(),
            rotation: dest.rotation,
            nonRotatedSize: dest.nonRotatedSize);

        if (spiderfyCluster != null) {
          if (spiderfyCluster == cluster) {
            _unspiderfy();
            return;
          } else {
            await _unspiderfy();
          }
        }
      }

      if (dest.zoom > _currentZoom && !cannotDivide) {
        _showPolygon(cluster.markers.map((m) => m.point).toList());
      }

      final latTween =
          Tween<double>(begin: center.latitude, end: dest.center.latitude);
      final lonTween =
          Tween<double>(begin: center.longitude, end: dest.center.longitude);
      final zoomTween =
          Tween<double>(begin: widget.mapCamera.zoom, end: dest.zoom);

      final isAlreadyFit = latTween.begin == latTween.end &&
          lonTween.begin == lonTween.end &&
          zoomTween.begin == zoomTween.end;

      if (isAlreadyFit) {
        if (cannotDivide && widget.options.spiderfyCluster) {
          _spiderfy(cluster);
        }
        return;
      }

      final animation = CurvedAnimation(
          parent: _fitBoundController,
          curve: widget.options.animationsOptions.fitBoundCurves);

      final listener = _centerMarkerListener(animation, latTween, lonTween,
          zoomTween: zoomTween);

      _fitBoundController.addListener(listener);

      _fitBoundController.forward().then((_) {
        _fitBoundController
          ..removeListener(listener)
          ..reset();

        if (cannotDivide && widget.options.spiderfyCluster) {
          _spiderfy(cluster);
        }
      });
    };
  }

  VoidCallback _onMarkerTap(MarkerNode marker) {
    return () {
      if (_animating) return;

      if (widget.options.popupOptions != null) {
        final popupOptions = widget.options.popupOptions!;
        popupOptions.markerTapBehavior.apply(
          PopupSpec.wrap(marker.marker),
          PopupState.maybeOf(context, listen: false)!,
          popupOptions.popupController,
        );
      }

      widget.options.onMarkerTap?.call(marker.marker);

      if (!widget.options.centerMarkerOnClick) return;

      final center = widget.mapCamera.center;
      final latTween =
          Tween<double>(begin: center.latitude, end: marker.point.latitude);
      final lonTween =
          Tween<double>(begin: center.longitude, end: marker.point.longitude);

      final Animation<double> animation = CurvedAnimation(
        parent: _centerMarkerController,
        curve: widget.options.animationsOptions.centerMarkerCurves,
      );

      final listener = _centerMarkerListener(animation, latTween, lonTween);
      _centerMarkerController.addListener(listener);
      _centerMarkerController.forward().then((_) {
        _centerMarkerController
          ..removeListener(listener)
          ..reset();
      });
    };
  }

  VoidCallback _onMarkerDoubleTap(MarkerNode marker) {
    return () {
      if (_animating) return;

      widget.options.onMarkerDoubleTap?.call(marker.marker);
    };
  }

  VoidCallback _centerMarkerListener(
    Animation<double> animation,
    Tween<double> latTween,
    Tween<double> lonTween, {
    Tween<double>? zoomTween,
  }) {
    return () {
      widget.mapController.move(
        LatLng(latTween.evaluate(animation), lonTween.evaluate(animation)),
        zoomTween?.evaluate(animation) ?? widget.mapCamera.zoom,
      );
    };
  }

  void _showPolygon(List<LatLng> points) {
    if (widget.options.showPolygon) {
      setState(() {
        _polygon = PolygonLayer(polygons: [
          Polygon(
            points: QuickHull.getConvexHull(points),
            borderStrokeWidth: widget.options.polygonOptions.borderStrokeWidth,
            color: widget.options.polygonOptions.color,
            borderColor: widget.options.polygonOptions.borderColor,
            pattern: widget.options.polygonOptions.pattern,
          ),
        ]);
      });
    }
  }

  void _hidePolygon() {
    if (widget.options.showPolygon) {
      setState(() {
        _polygon = null;
      });
    }
  }

  List<Point?> _generatePointSpiderfy(int count, Point center) {
    if (widget.options.spiderfyShapePositions != null) {
      return widget.options.spiderfyShapePositions!(count, center);
    }
    if (count >= widget.options.circleSpiralSwitchover) {
      return Spiderfy.spiral(
        widget.options.spiderfySpiralDistanceMultiplier,
        count,
        center,
      );
    }

    return Spiderfy.circle(widget.options.spiderfyCircleRadius, count, center);
  }
}

// Builds LatLngBounds that extended upon the given bounds by a given "factor".
LatLngBounds _extendBounds(LatLngBounds bounds, double stickonFactor) {
  final sw = bounds.southWest;
  final ne = bounds.northEast;
  final height = (sw.latitude - ne.latitude).abs() * stickonFactor;
  final width = (sw.longitude - ne.longitude).abs() * stickonFactor;

  // Clamp rather than wrap around. This function is used in the context of
  // drawing things onto a map. Since the map renderer does't wrap maps itself,
  // we also shouldn't wrap around the bounding boxes.
  final point1 = LatLng((bounds.south - height).clamp(-90, 90),
      (bounds.west - width).clamp(-180, 180));
  final point2 = LatLng((bounds.north + height).clamp(-90, 90),
      (bounds.east + width).clamp(-180, 180));

  return LatLngBounds(point1, point2);
}
