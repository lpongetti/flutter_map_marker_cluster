import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster/src/cluster_manager.dart';
import 'package:flutter_map_marker_cluster/src/cluster_widget.dart';
import 'package:flutter_map_marker_cluster/src/core/quick_hull.dart';
import 'package:flutter_map_marker_cluster/src/core/spiderfy.dart';
import 'package:flutter_map_marker_cluster/src/fade.dart';
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/map_widget.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer_options.dart';
import 'package:flutter_map_marker_cluster/src/marker_widget.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_or_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/rotate.dart';
import 'package:flutter_map_marker_cluster/src/translate.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:latlong2/latlong.dart';

class MarkerClusterLayer extends StatefulWidget {
  final MarkerClusterLayerOptions options;
  final MapState map;
  final Stream<void> stream;

  const MarkerClusterLayer(this.options, this.map, this.stream, {Key? key})
      : super(key: key);

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

  _MarkerClusterLayerState();

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
    _mapCalculator = MapCalculator(widget.map);

    _currentZoom = _previousZoom = widget.map.zoom.ceil();
    _previousZoomDouble = widget.map.zoom;
    _minZoom = widget.map.options.minZoom?.ceil() ?? 1;
    _maxZoom = widget.map.options.maxZoom?.floor() ?? 20;
    _previousZoomDouble = widget.map.zoom;
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
    super.didUpdateWidget(oldWidget);
  }

  void _initializeClusterManager() {
    _clusterManager = ClusterManager.initialize(
      anchorPos: widget.options.anchor,
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

    _clusterManager.recalculateTopClusterLevelBounds();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        return Stack(
          children: _buildLayers(),
        );
      },
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
              angle: -widget.map.rotationRad,
              origin: marker.rotateOrigin ?? widget.options.rotateOrigin,
              alignment:
                  marker.rotateAlignment ?? widget.options.rotateAlignment,
            ),
      key: marker.key ?? ObjectKey(marker.marker),
      child: MarkerWidget(
        marker: marker,
        onTap: _onMarkerTap(marker),
      ),
    );
  }

  void _spiderfy(MarkerClusterNode cluster) {
    if (_clusterManager.spiderfyCluster != null) {
      _unspiderfy();
      return;
    }

    setState(() {
      _clusterManager.spiderfyCluster = cluster;
    });
    _spiderfyController.forward();
  }

  void _unspiderfy() {
    switch (_spiderfyController.status) {
      case AnimationStatus.completed:
        final markersGettingClustered = _clusterManager.spiderfyCluster!.markers
            .map((markerNode) => markerNode.marker)
            .toList();

        _spiderfyController.reverse().then(
              (_) => setState(() {
                _clusterManager.spiderfyCluster = null;
              }),
            );

        if (widget.options.popupOptions != null) {
          widget.options.popupOptions!.popupController.hidePopupsOnlyFor(
            markersGettingClustered,
          );
        }
        if (widget.options.onMarkersClustered != null) {
          widget.options.onMarkersClustered!(markersGettingClustered);
        }
        break;
      case AnimationStatus.forward:
        final markersGettingClustered = _clusterManager.spiderfyCluster!.markers
            .map((markerNode) => markerNode.marker)
            .toList();

        _spiderfyController
          ..stop()
          ..reverse().then(
            (_) => setState(() {
              _clusterManager.spiderfyCluster = null;
            }),
          );

        widget.options.popupOptions?.popupController
            .hidePopupsOnlyFor(markersGettingClustered);
        widget.options.onMarkersClustered?.call(markersGettingClustered);
        break;
      default:
        break;
    }
  }

  List<Widget> _buildLayer(MarkerOrClusterNode layer) {
    if (layer is MarkerNode) {
      return _buildMarkerLayer(layer);
    } else if (layer is MarkerClusterNode) {
      return _buildMarkerClusterLayer(layer);
    } else {
      throw 'Unexpected layer type: ${layer.runtimeType}';
    }
  }

  List<Widget> _buildMarkerLayer(MarkerNode markerNode) {
    if (!_mapCalculator.boundsContainsMarker(markerNode)) return <Widget>[];

    if (_zoomingIn && markerNode.parent!.zoom == _previousZoom) {
      return _buildZoomingInMarkerLayer(markerNode);
    } else {
      return [
        _buildMarker(
          marker: markerNode,
          controller: _zoomController,
          translate: StaticTranslate(_mapCalculator, markerNode),
        ),
      ];
    }
  }

  List<Widget> _buildZoomingInMarkerLayer(MarkerNode markerNode) {
    final layers = <Widget>[];

    layers.add(
      _buildMarker(
        marker: markerNode,
        controller: _zoomController,
        fade: Fade.fadeIn,
        translate: AnimatedTranslate.fromNewPosToMyPos(
          mapCalculator: _mapCalculator,
          from: markerNode,
          to: markerNode.parent!,
        ),
      ),
    );

    // parent
    layers.add(
      MapWidget(
        size: markerNode.parent!.size(),
        animationController: _zoomController,
        translate: StaticTranslate(_mapCalculator, markerNode.parent!),
        fade: Fade.fadeOut,
        child: ClusterWidget(
          cluster: markerNode.parent!,
          builder: widget.options.builder,
          onTap: _onClusterTap(markerNode.parent!),
        ),
      ),
    );

    return layers;
  }

  List<Widget> _buildMarkerClusterLayer(MarkerClusterNode clusterNode) {
    final layers = <Widget>[];
    if (!_mapCalculator.boundsContainsCluster(clusterNode)) return layers;

    if (_zoomingOut && clusterNode.children.length > 1) {
      return _buildClusterClosingLayer(clusterNode);
    } else if (_zoomingIn &&
        _mapCalculator.clusterPoint(clusterNode.parent!) !=
            _mapCalculator.clusterPoint(clusterNode)) {
      return _buildClusterOpeningLayer(clusterNode);
    } else if (_clusterManager.isSpiderfyCluster(clusterNode)) {
      layers.addAll(_buildSpiderfyCluster(clusterNode, _currentZoom));
    } else {
      layers.add(
        MapWidget.static(
          size: clusterNode.size(),
          translate: StaticTranslate(_mapCalculator, clusterNode),
          child: ClusterWidget(
            cluster: clusterNode,
            builder: widget.options.builder,
            onTap: _onClusterTap(clusterNode),
          ),
        ),
      );
    }

    return layers;
  }

  List<Widget> _buildClusterClosingLayer(MarkerClusterNode clusterNode) {
    final layers = <Widget>[];

    // cluster
    layers.add(
      MapWidget(
        size: clusterNode.size(),
        animationController: _zoomController,
        translate: StaticTranslate(_mapCalculator, clusterNode),
        fade: Fade.fadeIn,
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
            fade: Fade.fadeOut,
            translate: AnimatedTranslate.fromMyPosToNewPos(
              mapCalculator: _mapCalculator,
              from: child,
              to: clusterNode,
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
            ),
            fade: Fade.fadeOut,
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

    return layers;
  }

  List<Widget> _buildClusterOpeningLayer(MarkerClusterNode clusterNode) {
    return <Widget>[
      // cluster
      MapWidget(
        size: clusterNode.size(),
        animationController: _zoomController,
        translate: AnimatedTranslate.fromNewPosToMyPos(
          mapCalculator: _mapCalculator,
          from: clusterNode,
          to: clusterNode.parent!,
        ),
        fade: Fade.fadeIn,
        child: ClusterWidget(
          cluster: clusterNode,
          builder: widget.options.builder,
          onTap: _onClusterTap(clusterNode),
        ),
      ),
      //parent
      MapWidget(
        size: clusterNode.parent!.size(),
        animationController: _zoomController,
        translate: StaticTranslate(_mapCalculator, clusterNode.parent!),
        fade: Fade.fadeOut,
        child: ClusterWidget(
          cluster: clusterNode.parent!,
          builder: widget.options.builder,
          onTap: _onClusterTap(clusterNode.parent!),
        ),
      ),
    ];
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
        fade: Fade.almostFadeOut,
        child: ClusterWidget(
          cluster: cluster,
          builder: widget.options.builder,
          onTap: _onClusterTap(cluster),
        ),
      ),
    );
    final points = _generatePointSpiderfy(
      cluster.markers.length,
      _mapCalculator.getPixelFromPoint(
        _mapCalculator.clusterPoint(cluster),
      ),
    );

    for (var i = 0; i < cluster.markers.length; i++) {
      final marker = cluster.markers[i];

      results.add(
        _buildMarker(
          marker: marker,
          controller: _spiderfyController,
          fade: Fade.fadeIn,
          translate: AnimatedTranslate.spiderfy(
            mapCalculator: _mapCalculator,
            cluster: cluster,
            marker: marker,
            point: points[i]!,
          ),
        ),
      );
    }
    return results;
  }

  List<Widget> _buildLayers() {
    if (widget.map.zoom != _previousZoomDouble) {
      _previousZoomDouble = widget.map.zoom;
      _unspiderfy();
    }

    final zoom = widget.map.zoom.ceil();
    final layers = <Widget>[];

    if (_polygon != null) layers.add(_polygon!);

    if (zoom < _currentZoom || zoom > _currentZoom) {
      _previousZoom = _currentZoom;
      _currentZoom = zoom;

      _zoomController
        ..reset()
        ..forward().then(
          (_) => setState(() {
            _hidePolygon();
          }),
        );
    }

    _clusterManager.recursivelyFromTopClusterLevel(
        _currentZoom, widget.options.disableClusteringAtZoom,
        (MarkerOrClusterNode layer) {
      layers.addAll(_buildLayer(layer));
    });

    final popupOptions = widget.options.popupOptions;
    if (popupOptions != null) {
      layers.add(PopupLayer(
        popupBuilder: popupOptions.popupBuilder,
        popupSnap: popupOptions.popupSnap,
        popupController: popupOptions.popupController,
        popupAnimation: popupOptions.popupAnimation,
        markerRotate: popupOptions.markerRotate,
        mapState: widget.map,
      ));
    }

    return layers;
  }

  VoidCallback _onClusterTap(MarkerClusterNode cluster) {
    return () {
      if (_animating) return;

      widget.options.onClusterTap?.call(cluster);

      if (!widget.options.zoomToBoundsOnClick) {
        _spiderfy(cluster);
        return;
      }

      final center = widget.map.center;
      var dest = widget.map.getBoundsCenterZoom(
        cluster.bounds,
        widget.options.fitBoundsOptions,
      );

      // check if children can un-cluster
      final cannotDivide = cluster.markers.every((marker) =>
              marker.parent!.zoom == _maxZoom &&
              marker.parent == cluster.markers[0].parent) ||
          (dest.zoom == _currentZoom &&
              _currentZoom == widget.options.fitBoundsOptions.maxZoom);

      if (cannotDivide) {
        dest = CenterZoom(center: dest.center, zoom: _currentZoom.toDouble());
      }

      if (dest.zoom > _currentZoom && !cannotDivide) {
        _showPolygon(
          cluster.markers.fold<List<LatLng>>(
            [],
            (result, marker) => result..add(marker.point),
          ),
        );
      }

      final latTween =
          Tween<double>(begin: center.latitude, end: dest.center.latitude);
      final lonTween =
          Tween<double>(begin: center.longitude, end: dest.center.longitude);
      final zoomTween = Tween<double>(begin: widget.map.zoom, end: dest.zoom);

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

        if (cannotDivide) {
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
          marker.marker,
          popupOptions.popupController,
        );
      }

      widget.options.onMarkerTap?.call(marker.marker);

      if (!widget.options.centerMarkerOnClick) return;

      final center = widget.map.center;
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

  VoidCallback _centerMarkerListener(
    Animation<double> animation,
    Tween<double> latTween,
    Tween<double> lonTween, {
    Tween<double>? zoomTween,
  }) {
    return () {
      widget.map.move(
        LatLng(latTween.evaluate(animation), lonTween.evaluate(animation)),
        zoomTween?.evaluate(animation) ?? widget.map.zoom,
        source: MapEventSource.custom,
      );
    };
  }

  void _showPolygon(List<LatLng> points) {
    if (widget.options.showPolygon) {
      setState(() {
        _polygon = PolygonLayer(
          PolygonLayerOptions(polygons: [
            Polygon(
              points: QuickHull.getConvexHull(points),
              borderStrokeWidth:
                  widget.options.polygonOptions.borderStrokeWidth,
              color: widget.options.polygonOptions.color,
              borderColor: widget.options.polygonOptions.borderColor,
              isDotted: widget.options.polygonOptions.isDotted,
            ),
          ]),
          widget.map,
          widget.stream,
        );
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
