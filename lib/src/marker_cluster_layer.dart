import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster/src/anim_type.dart';
import 'package:flutter_map_marker_cluster/src/cluster_manager.dart';
import 'package:flutter_map_marker_cluster/src/cluster_widget.dart';
import 'package:flutter_map_marker_cluster/src/core/quick_hull.dart';
import 'package:flutter_map_marker_cluster/src/core/spiderfy.dart';
import 'package:flutter_map_marker_cluster/src/core/util.dart' as util;
import 'package:flutter_map_marker_cluster/src/map_calculator.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer_options.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_map_marker_cluster/src/spiderfy_cluster_widget.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:latlong2/latlong.dart';

class MarkerClusterLayer extends StatefulWidget {
  final MarkerClusterLayerOptions options;
  final MapState map;
  final Stream<void> stream;

  MarkerClusterLayer(this.options, this.map, this.stream);

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

  Point _getPixelFromMarker(MarkerNode marker, [LatLng? customPoint]) {
    final pos = _mapCalculator.getPixelFromPoint(customPoint ?? marker.point);
    return util.removeAnchor(pos, marker.width, marker.height, marker.anchor);
  }

  void _initializeAnimationController() {
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

  void _addLayers() {
    for (var marker in widget.options.markers) {
      _clusterManager.addLayer(
        MarkerNode(marker),
        widget.options.disableClusteringAtZoom,
        _maxZoom,
        _minZoom,
      );
    }

    _clusterManager.recalculateTopClusterLevelBounds();
  }

  Animation<double>? _fadeAnimation(
      AnimationController? controller, FadeType fade) {
    if (fade == FadeType.fadeIn)
      return Tween<double>(begin: 0.0, end: 1.0).animate(controller!);
    if (fade == FadeType.fadeOut)
      return Tween<double>(begin: 1.0, end: 0.0).animate(controller!);

    return null;
  }

  Animation<Point>? _translateAnimation(AnimationController? controller,
      TranslateType translate, Point pos, Point? newPos) {
    if (translate == TranslateType.fromNewPosToMyPos)
      return Tween<Point>(
        begin: Point(newPos!.x, newPos.y),
        end: Point(pos.x, pos.y),
      ).animate(controller!);
    if (translate == TranslateType.fromMyPosToNewPos)
      return Tween<Point>(
        begin: Point(pos.x, pos.y),
        end: Point(newPos!.x, newPos.y),
      ).animate(controller!);

    return null;
  }

  Widget _buildMarker(MarkerNode marker, AnimationController controller,
      [FadeType fade = FadeType.none,
      TranslateType translate = TranslateType.none,
      Point? newPos,
      Point? myPos]) {
    assert((translate == TranslateType.none && newPos == null) ||
        (translate != TranslateType.none && newPos != null));

    final pos = myPos ?? _getPixelFromMarker(marker);

    var fadeAnimation = _fadeAnimation(controller, fade);
    var translateAnimation =
        _translateAnimation(controller, translate, pos, newPos);

    return AnimatedBuilder(
      key: Key('marker-${marker.hashCode}'),
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final rotate = marker.rotate ?? widget.options.rotate ?? false;
        final markerWidget = rotate
            ? Transform.rotate(
                angle: -widget.map.rotationRad,
                origin: marker.rotateOrigin ?? widget.options.rotateOrigin,
                alignment:
                    marker.rotateAlignment ?? widget.options.rotateAlignment,
                child: Opacity(
                  opacity: fade == FadeType.none ? 1 : fadeAnimation!.value,
                  child: child,
                ),
              )
            : Opacity(
                opacity: fade == FadeType.none ? 1 : fadeAnimation!.value,
                child: child,
              );
        return Positioned(
          width: marker.width,
          height: marker.height,
          left: translate == TranslateType.none
              ? pos.x as double?
              : translateAnimation!.value.x as double?,
          top: translate == TranslateType.none
              ? pos.y as double?
              : translateAnimation!.value.y as double?,
          child: markerWidget,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onMarkerTap(marker) as void Function()?,
        child: marker.builder(context),
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

        _spiderfyController.reverse().then((_) => setState(() {
              _clusterManager.spiderfyCluster = null;
            }));

        if (widget.options.popupOptions != null) {
          widget.options.popupOptions!.popupController
              .hidePopupsOnlyFor(markersGettingClustered);
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
          ..reverse().then((_) => setState(() {
                _clusterManager.spiderfyCluster = null;
              }));

        if (widget.options.popupOptions != null) {
          widget.options.popupOptions!.popupController
              .hidePopupsOnlyFor(markersGettingClustered);
        }
        if (widget.options.onMarkersClustered != null) {
          widget.options.onMarkersClustered!(markersGettingClustered);
        }
        break;
      default:
        break;
    }
  }

  bool _boundsContainsMarker(MarkerNode marker) {
    var pixelPoint = widget.map.project(marker.point);

    final width = marker.width - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return widget.map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  bool _boundsContainsCluster(MarkerClusterNode cluster) {
    var pixelPoint = widget.map.project(cluster.point);

    var size = cluster.size();
    var anchor = Anchor.forPos(widget.options.anchor, size.width, size.height);

    final width = size.width - anchor.left;
    final height = size.height - anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return widget.map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  List<Widget> _buildLayer(layer) {
    var layers = <Widget>[];

    if (layer is MarkerNode) {
      if (!_boundsContainsMarker(layer)) {
        return <Widget>[];
      }

      // fade in if
      // animating and
      // zoom in and parent has the previous zoom
      if (_zoomController.isAnimating &&
          (_currentZoom > _previousZoom &&
              layer.parent!.zoom == _previousZoom)) {
        // marker
        layers.add(_buildMarker(
            layer,
            _zoomController,
            FadeType.fadeIn,
            TranslateType.fromNewPosToMyPos,
            _getPixelFromMarker(layer, layer.parent!.point)));
        //parent
        layers.add(ClusterWidget(
            cluster: layer.parent!,
            builder: widget.options.builder,
            mapCalculator: _mapCalculator,
            zoomController: _zoomController,
            onTap: _onClusterTap(layer.parent!),
            fadeAnimation: _fadeAnimation,
            translateAnimation: _translateAnimation,
            fadeType: FadeType.fadeOut));
      } else {
        layers.add(_buildMarker(layer, _zoomController));
      }
    }
    if (layer is MarkerClusterNode) {
      if (!_boundsContainsCluster(layer)) {
        return <Widget>[];
      }

      // fade in if
      // animating and
      // zoom out and children is more than one or zoom in and father has same point
      if (_zoomController.isAnimating &&
          (_currentZoom < _previousZoom && layer.children.length > 1)) {
        // cluster
        layers.add(ClusterWidget(
            cluster: layer,
            builder: widget.options.builder,
            mapCalculator: _mapCalculator,
            onTap: _onClusterTap(layer),
            fadeAnimation: _fadeAnimation,
            translateAnimation: _translateAnimation,
            zoomController: _zoomController,
            fadeType: FadeType.fadeIn));
        // children
        var markersGettingClustered = <Marker>[];
        layer.children.forEach((child) {
          if (child is MarkerNode) {
            markersGettingClustered.add(child.marker);

            layers.add(_buildMarker(
                child,
                _zoomController,
                FadeType.fadeOut,
                TranslateType.fromMyPosToNewPos,
                _getPixelFromMarker(child, layer.point)));
          } else {
            layers.add(ClusterWidget(
                cluster: child,
                builder: widget.options.builder,
                mapCalculator: _mapCalculator,
                onTap: _onClusterTap(child),
                zoomController: _zoomController,
                fadeAnimation: _fadeAnimation,
                translateAnimation: _translateAnimation,
                fadeType: FadeType.fadeOut,
                translateType: TranslateType.fromMyPosToNewPos,
                newPos: (child as MarkerClusterNode)
                    .getPixel(customPoint: layer.point)));
          }
        });

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
        layers.add(ClusterWidget(
            cluster: layer,
            builder: widget.options.builder,
            mapCalculator: _mapCalculator,
            onTap: _onClusterTap(layer),
            zoomController: _zoomController,
            fadeAnimation: _fadeAnimation,
            translateAnimation: _translateAnimation,
            fadeType: FadeType.fadeIn,
            translateType: TranslateType.fromNewPosToMyPos,
            newPos: layer.getPixel(customPoint: layer.parent!.point)));
        //parent
        layers.add(ClusterWidget(
            cluster: layer.parent!,
            builder: widget.options.builder,
            onTap: _onClusterTap(layer.parent!),
            mapCalculator: _mapCalculator,
            zoomController: _zoomController,
            fadeAnimation: _fadeAnimation,
            translateAnimation: _translateAnimation,
            fadeType: FadeType.fadeOut));
      } else {
        if (_clusterManager.isSpiderfyCluster(layer)) {
          layers.addAll(_buildSpiderfyCluster(layer, _currentZoom));
        } else {
          layers.add(ClusterWidget(
            cluster: layer,
            builder: widget.options.builder,
            mapCalculator: _mapCalculator,
            onTap: _onClusterTap(layer),
            zoomController: _zoomController,
            fadeAnimation: _fadeAnimation,
            translateAnimation: _translateAnimation,
          ));
        }
      }
    }

    return layers;
  }

  List<Widget> _buildSpiderfyCluster(
      MarkerClusterNode cluster, int currentZoom) {
    final results = <Widget>[];
    results.add(SpiderfyClusterWidget(
      cluster: cluster,
      builder: widget.options.builder,
      mapCalculator: _mapCalculator,
      onTap: _onClusterTap(cluster),
      spiderfyController: _spiderfyController,
    ));
    final points = _generatePointSpiderfy(cluster.markers.length,
        _mapCalculator.getPixelFromPoint(cluster.point));

    for (var i = 0; i < cluster.markers.length; i++) {
      final marker = cluster.markers[i];

      results.add(_buildMarker(
          marker,
          _spiderfyController,
          FadeType.fadeIn,
          TranslateType.fromMyPosToNewPos,
          util.removeAnchor(
              points[i]!, marker.width, marker.height, marker.anchor),
          _getPixelFromMarker(marker, cluster.point)));
    }
    return results;
  }

  List<Widget> _buildLayers() {
    if (widget.map.zoom != _previousZoomDouble) {
      _previousZoomDouble = widget.map.zoom;

      _unspiderfy();
    }

    var zoom = widget.map.zoom.ceil();

    var layers = <Widget>[];

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
      if (_zoomController.isAnimating ||
          _centerMarkerController.isAnimating ||
          _fitBoundController.isAnimating ||
          _spiderfyController.isAnimating) {
        return null;
      }

      // This is handled as an optional callback rather than leaving the package
      // user to wrap their cluster Marker child Widget in a GestureDetector as only one
      // GestureDetector gets triggered per gesture (usually the child one) and
      // therefore this _onClusterTap() function never gets called.
      if (widget.options.onClusterTap != null) {
        widget.options.onClusterTap!(cluster);
      }

      if (!widget.options.zoomToBoundsOnClick) {
        _spiderfy(cluster);
        return null;
      }

      final center = widget.map.center;
      var dest = widget.map
          .getBoundsCenterZoom(cluster.bounds, widget.options.fitBoundsOptions);

      // check if children can un-cluster
      var cannotDivide = cluster.markers.every((marker) =>
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

      final _latTween =
          Tween<double>(begin: center.latitude, end: dest.center.latitude);
      final _lngTween =
          Tween<double>(begin: center.longitude, end: dest.center.longitude);
      final _zoomTween =
          Tween<double>(begin: _currentZoom.toDouble(), end: dest.zoom);

      Animation<double> animation = CurvedAnimation(
          parent: _fitBoundController,
          curve: widget.options.animationsOptions.fitBoundCurves);

      final listener = () {
        widget.map.move(
            LatLng(
                _latTween.evaluate(animation), _lngTween.evaluate(animation)),
            _zoomTween.evaluate(animation),
            source: MapEventSource.custom);
      };

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

  Function _onMarkerTap(MarkerNode marker) {
    return () {
      if (_zoomController.isAnimating ||
          _centerMarkerController.isAnimating ||
          _fitBoundController.isAnimating) return null;

      if (widget.options.popupOptions != null) {
        final popupOptions = widget.options.popupOptions!;
        popupOptions.markerTapBehavior
            .apply(marker.marker, popupOptions.popupController);
      }

      // This is handled as an optional callback rather than leaving the package
      // user to wrap their Marker child Widget in a GestureDetector as only one
      // GestureDetector gets triggered per gesture (usually the child one) and
      // therefore this _onMarkerTap function never gets called.
      if (widget.options.onMarkerTap != null) {
        widget.options.onMarkerTap!(marker.marker);
      }

      if (!widget.options.centerMarkerOnClick) return null;

      final center = widget.map.center;

      final _latTween =
          Tween<double>(begin: center.latitude, end: marker.point.latitude);
      final _lngTween =
          Tween<double>(begin: center.longitude, end: marker.point.longitude);

      Animation<double> animation = CurvedAnimation(
          parent: _centerMarkerController,
          curve: widget.options.animationsOptions.centerMarkerCurves);

      final listener = () {
        widget.map.move(
            LatLng(
                _latTween.evaluate(animation), _lngTween.evaluate(animation)),
            widget.map.zoom,
            source: MapEventSource.custom);
      };

      _centerMarkerController.addListener(listener);

      _centerMarkerController.forward().then((_) {
        _centerMarkerController
          ..removeListener(listener)
          ..reset();
      });
    };
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

  @override
  void initState() {
    _mapCalculator = MapCalculator(widget.map);

    _currentZoom = _previousZoom = widget.map.zoom.ceil();
    _previousZoomDouble = widget.map.zoom;
    _minZoom = widget.map.options.minZoom?.ceil() ?? 1;
    _maxZoom = widget.map.options.maxZoom?.floor() ?? 20;
    _previousZoomDouble = widget.map.zoom;
    _initializeAnimationController();
    _initializeClusterManager();
    _addLayers();

    _zoomController.forward();

    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        return Container(
          child: Stack(
            children: _buildLayers(),
          ),
        );
      },
    );
  }
}
