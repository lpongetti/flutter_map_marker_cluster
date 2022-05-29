import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster/src/cluster_manager.dart';
import 'package:flutter_map_marker_cluster/src/cluster_widget.dart';
import 'package:flutter_map_marker_cluster/src/core/quick_hull.dart';
import 'package:flutter_map_marker_cluster/src/core/spiderfy.dart';
import 'package:flutter_map_marker_cluster/src/core/util.dart' as util;
import 'package:flutter_map_marker_cluster/src/fade.dart';
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/map_widget.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer_options.dart';
import 'package:flutter_map_marker_cluster/src/marker_widget.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
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
  _MarkerClusterLayerState createState() => _MarkerClusterLayerState();
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
    for (var marker in widget.options.markers) {
      _clusterManager.addLayer(
        MarkerNode(marker, mapCalculator: _mapCalculator),
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
      child: MarkerWidget(
        marker: marker,
        onTap: () => _onMarkerTap(marker),
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
        var markersGettingClustered = _clusterManager.spiderfyCluster!.markers
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
        var markersGettingClustered = _clusterManager.spiderfyCluster!.markers
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

  List<Widget> _buildLayer(layer) {
    var layers = <Widget>[];

    if (layer is MarkerNode) {
      if (!_mapCalculator.boundsContainsMarker(layer)) return <Widget>[];

      // fade in if
      // animating and
      // zoom in and parent has the previous zoom
      if (_zoomController.isAnimating &&
          (_currentZoom > _previousZoom &&
              layer.parent!.zoom == _previousZoom)) {
        // marker
        layers.add(
          _buildMarker(
            marker: layer,
            controller: _zoomController,
            fade: Fade.fadeIn,
            translate: AnimatedTranslate.fromNewPosToMyPos(
              position: layer.getPixel(),
              newPosition: layer.getPixel(customPoint: layer.parent!.point),
            ),
          ),
        );
        //parent
        layers.add(
          MapWidget(
            size: layer.parent!.size(),
            animationController: _zoomController,
            translate: StaticTranslate(layer.parent!.getPixel()),
            fade: Fade.fadeOut,
            child: ClusterWidget(
              cluster: layer.parent!,
              builder: widget.options.builder,
              onTap: _onClusterTap(layer.parent!),
            ),
          ),
        );
      } else {
        layers.add(
          _buildMarker(
            marker: layer,
            controller: _zoomController,
            translate: StaticTranslate(layer.getPixel()),
          ),
        );
      }
    }
    if (layer is MarkerClusterNode) {
      if (!_mapCalculator.boundsContainsCluster(layer)) {
        return <Widget>[];
      }

      // fade in if
      // animating and
      // zoom out and children is more than one or zoom in and father has same point
      if (_zoomController.isAnimating &&
          (_currentZoom < _previousZoom && layer.children.length > 1)) {
        // cluster
        layers.add(
          MapWidget(
            size: layer.size(),
            animationController: _zoomController,
            translate: StaticTranslate(layer.getPixel()),
            fade: Fade.fadeIn,
            child: ClusterWidget(
              cluster: layer,
              builder: widget.options.builder,
              onTap: _onClusterTap(layer),
            ),
          ),
        );
        // children
        final markersGettingClustered = <Marker>[];
        for (final child in layer.children) {
          if (child is MarkerNode) {
            markersGettingClustered.add(child.marker);

            layers.add(
              _buildMarker(
                marker: child,
                controller: _zoomController,
                fade: Fade.fadeOut,
                translate: AnimatedTranslate.fromMyPosToNewPos(
                  position: child.getPixel(),
                  newPosition: child.getPixel(customPoint: layer.point),
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
                  position: child.getPixel(),
                  newPosition: child.getPixel(customPoint: layer.point),
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

        if (widget.options.popupOptions != null) {
          widget.options.popupOptions!.popupController
              .hidePopupsOnlyFor(markersGettingClustered);
        }
        if (widget.options.onMarkersClustered != null) {
          widget.options.onMarkersClustered!(markersGettingClustered);
        }
      } else if (_zoomController.isAnimating &&
          (_currentZoom > _previousZoom &&
              layer.parent!.point != layer.point)) {
        // cluster
        layers.add(
          MapWidget(
            size: layer.size(),
            animationController: _zoomController,
            translate: AnimatedTranslate.fromNewPosToMyPos(
                position: layer.getPixel(),
                newPosition: layer.getPixel(customPoint: layer.parent!.point)),
            fade: Fade.fadeIn,
            child: ClusterWidget(
              cluster: layer,
              builder: widget.options.builder,
              onTap: _onClusterTap(layer),
            ),
          ),
        );
        //parent
        layers.add(
          MapWidget(
            size: layer.parent!.size(),
            animationController: _zoomController,
            translate: StaticTranslate(layer.parent!.getPixel()),
            fade: Fade.fadeOut,
            child: ClusterWidget(
              cluster: layer.parent!,
              builder: widget.options.builder,
              onTap: _onClusterTap(layer.parent!),
            ),
          ),
        );
      } else {
        if (_clusterManager.isSpiderfyCluster(layer)) {
          layers.addAll(_buildSpiderfyCluster(layer, _currentZoom));
        } else {
          layers.add(
            MapWidget.static(
              size: layer.size(),
              translate: StaticTranslate(layer.getPixel()),
              child: ClusterWidget(
                cluster: layer,
                builder: widget.options.builder,
                onTap: _onClusterTap(layer),
              ),
            ),
          );
        }
      }
    }

    return layers;
  }

  List<Widget> _buildSpiderfyCluster(
      MarkerClusterNode cluster, int currentZoom) {
    final results = <Widget>[];
    results.add(
      MapWidget(
        size: cluster.size(),
        animationController: _spiderfyController,
        translate: StaticTranslate(cluster.getPixel()),
        fade: Fade.almostFadeOut,
        child: ClusterWidget(
          cluster: cluster,
          builder: widget.options.builder,
          onTap: _onClusterTap(cluster),
        ),
      ),
    );
    final points = _generatePointSpiderfy(cluster.markers.length,
        _mapCalculator.getPixelFromPoint(cluster.point));

    for (var i = 0; i < cluster.markers.length; i++) {
      final marker = cluster.markers[i];

      results.add(
        _buildMarker(
          marker: marker,
          controller: _spiderfyController,
          fade: Fade.fadeIn,
          translate: AnimatedTranslate.fromMyPosToNewPos(
            position: marker.getPixel(customPoint: cluster.point),
            newPosition: util.removeAnchor(
                points[i]!, marker.width, marker.height, marker.anchor),
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
        ..forward().then((_) => setState(() {
              _hidePolygon();
            })); // for remove previous layer (animation)
    }

    _clusterManager.recursivelyFromTopClusterLevel(
        _currentZoom, widget.options.disableClusteringAtZoom, (layer) {
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
      var dest = widget.map
          .getBoundsCenterZoom(cluster.bounds, widget.options.fitBoundsOptions);

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
        _showPolygon(cluster.markers.fold<List<LatLng>>(
            [], (result, marker) => result..add(marker.point)));
      }

      final latTween =
          Tween<double>(begin: center.latitude, end: dest.center.latitude);
      final lonTween =
          Tween<double>(begin: center.longitude, end: dest.center.longitude);
      final zoomTween =
          Tween<double>(begin: _currentZoom.toDouble(), end: dest.zoom);

      Animation<double> animation = CurvedAnimation(
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

      Animation<double> animation = CurvedAnimation(
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
          widget.options.spiderfySpiralDistanceMultiplier, count, center);
    }

    return Spiderfy.circle(widget.options.spiderfyCircleRadius, count, center);
  }
}
