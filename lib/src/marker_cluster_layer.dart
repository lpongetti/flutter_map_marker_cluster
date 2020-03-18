import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/anim_type.dart';
import 'package:flutter_map_marker_cluster/src/core/distance_grid.dart';
import 'package:flutter_map_marker_cluster/src/core/quick_hull.dart';
import 'package:flutter_map_marker_cluster/src/core/spiderfy.dart';
import 'package:flutter_map_marker_cluster/src/marker_cluster_layer_options.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong/latlong.dart';

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
  Map<int, DistanceGrid<MarkerClusterNode>> _gridClusters = {};
  Map<int, DistanceGrid<MarkerNode>> _gridUnclustered = {};
  MarkerClusterNode _topClusterLevel;
  int _maxZoom;
  int _minZoom;
  int _currentZoom;
  int _previusZoom;
  double _previusZoomDouble;
  AnimationController _zoomController;
  AnimationController _fitBoundController;
  AnimationController _centerMarkerController;
  AnimationController _spiderfyController;
  MarkerClusterNode _spiderfyCluster;
  PolygonLayer _polygon;

  _MarkerClusterLayerState();

  CustomPoint<num> _getPixelFromPoint(LatLng point) {
    var pos = widget.map.project(point);
    return pos.multiplyBy(
            widget.map.getZoomScale(widget.map.zoom, widget.map.zoom)) -
        widget.map.getPixelOrigin();
  }

  Point _getPixelFromMarker(MarkerNode marker, [LatLng customPoint]) {
    final pos = _getPixelFromPoint(customPoint ?? marker.point);
    return _removeAnchor(pos, marker.width, marker.height, marker.anchor);
  }

  Point _getPixelFromCluster(MarkerClusterNode cluster, [LatLng customPoint]) {
    final pos = _getPixelFromPoint(customPoint ?? cluster.point);

    Size size = getClusterSize(cluster);
    Anchor anchor =
        Anchor.forPos(widget.options.anchor, size.width, size.height);

    return _removeAnchor(pos, size.width, size.height, anchor);
  }

  Point _removeAnchor(Point pos, double width, double height, Anchor anchor) {
    final x = (pos.x - (width - anchor.left)).toDouble();
    final y = (pos.y - (height - anchor.top)).toDouble();
    return Point(x, y);
  }

  _initializeAnimationController() {
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

  _initializeClusters() {
    // set up DistanceGrids for each zoom
    for (var zoom = _maxZoom; zoom >= _minZoom; zoom--) {
      _gridClusters[zoom] = DistanceGrid(widget.options.maxClusterRadius);
      _gridUnclustered[zoom] = DistanceGrid(widget.options.maxClusterRadius);
    }

    _topClusterLevel = MarkerClusterNode(
      zoom: _minZoom - 1,
      map: widget.map,
    );
  }

  _addLayer(MarkerNode marker) {
    for (var zoom = _maxZoom; zoom >= _minZoom; zoom--) {
      var markerPoint = widget.map.project(marker.point, zoom.toDouble());
      // try find a cluster close by
      var cluster = _gridClusters[zoom].getNearObject(markerPoint);
      if (cluster != null) {
        cluster.addChild(marker);
        return;
      }

      var closest = _gridUnclustered[zoom].getNearObject(markerPoint);
      if (closest != null) {
        var parent = closest.parent;
        parent.removeChild(closest);

        var newCluster = MarkerClusterNode(zoom: zoom, map: widget.map)
          ..addChild(closest)
          ..addChild(marker);

        _gridClusters[zoom].addObject(
            newCluster, widget.map.project(newCluster.point, zoom.toDouble()));

        //First create any new intermediate parent clusters that don't exist
        var lastParent = newCluster;
        for (var z = zoom - 1; z > parent.zoom; z--) {
          var newParent = MarkerClusterNode(
            zoom: z,
            map: widget.map,
          );
          newParent.addChild(lastParent);
          lastParent = newParent;
          _gridClusters[z].addObject(
              lastParent, widget.map.project(closest.point, z.toDouble()));
        }
        parent.addChild(lastParent);

        _removeFromNewPosToMyPosGridUnclustered(closest, zoom);
        return;
      }

      _gridUnclustered[zoom].addObject(marker, markerPoint);
    }

    //Didn't get in anything, add us to the top
    _topClusterLevel.addChild(marker);
  }

  _addLayers() {
    for (var marker in widget.options.markers) {
      _addLayer(MarkerNode(marker));
    }

    _topClusterLevel.recalulateBounds();
  }

  _removeFromNewPosToMyPosGridUnclustered(MarkerNode marker, int zoom) {
    for (; zoom >= _minZoom; zoom--) {
      if (!_gridUnclustered[zoom].removeObject(marker)) {
        break;
      }
    }
  }

  Animation<double> _fadeAnimation(
      AnimationController controller, FadeType fade) {
    if (fade == FadeType.FadeIn)
      return Tween<double>(begin: 0.0, end: 1.0).animate(controller);
    if (fade == FadeType.FadeOut)
      return Tween<double>(begin: 1.0, end: 0.0).animate(controller);

    return null;
  }

  Animation<Point> _translateAnimation(AnimationController controller,
      TranslateType translate, Point pos, Point newPos) {
    if (translate == TranslateType.FromNewPosToMyPos)
      return Tween<Point>(
        begin: Point(newPos.x, newPos.y),
        end: Point(pos.x, pos.y),
      ).animate(controller);
    if (translate == TranslateType.FromMyPosToNewPos)
      return Tween<Point>(
        begin: Point(pos.x, pos.y),
        end: Point(newPos.x, newPos.y),
      ).animate(controller);

    return null;
  }

  Widget _buildMarker(MarkerNode marker, AnimationController controller,
      [FadeType fade = FadeType.None,
      TranslateType translate = TranslateType.None,
      Point newPos,
      Point myPos]) {
    assert((translate == TranslateType.None && newPos == null) ||
        (translate != TranslateType.None && newPos != null));

    final pos = myPos ?? _getPixelFromMarker(marker);

    Animation<double> fadeAnimation = _fadeAnimation(controller, fade);
    Animation<Point> translateAnimation =
        _translateAnimation(controller, translate, pos, newPos);

    return AnimatedBuilder(
      animation: controller,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onMarkerTap(marker),
        child: marker.builder(context),
      ),
      builder: (BuildContext context, Widget child) {
        return Positioned(
          width: marker.width,
          height: marker.height,
          left: translate == TranslateType.None
              ? pos.x
              : translateAnimation.value.x,
          top: translate == TranslateType.None
              ? pos.y
              : translateAnimation.value.y,
          child: Opacity(
            opacity: fade == FadeType.None ? 1 : fadeAnimation.value,
            child: child,
          ),
        );
      },
    );
  }

  List<Widget> _buildSpiderfyCluster(MarkerClusterNode cluster, int zoom) {
    final pos = _getPixelFromCluster(cluster);

    final points = _generatePointSpiderfy(
        cluster.markers.length, _getPixelFromPoint(cluster.point));

    final fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.3).animate(_spiderfyController);

    List<Widget> results = [];

    Size size = getClusterSize(cluster);

    results.add(
      AnimatedBuilder(
        animation: _spiderfyController,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onClusterTap(cluster),
          child: widget.options.builder(
            context,
            cluster.markers.map((node) => node.marker).toList(),
          ),
        ),
        builder: (BuildContext context, Widget child) {
          return Positioned(
            width: size.width,
            height: size.height,
            left: pos.x,
            top: pos.y,
            child: Opacity(
              opacity: fadeAnimation.value,
              child: child,
            ),
          );
        },
      ),
    );

    for (var i = 0; i < cluster.markers.length; i++) {
      final marker = cluster.markers[i];

      results.add(_buildMarker(
          marker,
          _spiderfyController,
          FadeType.FadeIn,
          TranslateType.FromMyPosToNewPos,
          _removeAnchor(points[i], marker.width, marker.height, marker.anchor),
          _getPixelFromMarker(marker, cluster.point)));
    }

    return results;
  }

  List<Marker> getClusterMarkers(MarkerClusterNode cluster) =>
      cluster.markers.map((node) => node.marker).toList();

  Size getClusterSize(MarkerClusterNode cluster) =>
      widget.options?.computeSize == null
          ? widget.options.size
          : widget.options.computeSize(getClusterMarkers(cluster));

  Widget _buildCluster(MarkerClusterNode cluster,
      [FadeType fade = FadeType.None,
      TranslateType translate = TranslateType.None,
      Point newPos]) {
    assert((translate == TranslateType.None && newPos == null) ||
        (translate != TranslateType.None && newPos != null));

    final pos = _getPixelFromCluster(cluster);

    Animation<double> fadeAnimation = _fadeAnimation(_zoomController, fade);
    Animation<Point> translateAnimation =
        _translateAnimation(_zoomController, translate, pos, newPos);

    Size size = getClusterSize(cluster);

    return AnimatedBuilder(
      animation: _zoomController,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onClusterTap(cluster),
        child: widget.options.builder(
          context,
          getClusterMarkers(cluster),
        ),
      ),
      builder: (BuildContext context, Widget child) {
        return Positioned(
          width: size.width,
          height: size.height,
          left: translate == TranslateType.None
              ? pos.x
              : translateAnimation.value.x,
          top: translate == TranslateType.None
              ? pos.y
              : translateAnimation.value.y,
          child: Opacity(
            opacity: fade == FadeType.None ? 1 : fadeAnimation.value,
            child: child,
          ),
        );
      },
    );
  }

  _spiderfy(MarkerClusterNode cluster) {
    if (_spiderfyCluster != null) {
      _unspiderfy();
      return;
    }

    setState(() {
      _spiderfyCluster = cluster;
    });
    _spiderfyController.forward();
  }

  _unspiderfy() {
    switch (_spiderfyController.status) {
      case AnimationStatus.completed:
        _spiderfyController.reverse().then((_) => setState(() {
              _spiderfyCluster = null;
            }));
        break;
      case AnimationStatus.forward:
        _spiderfyController
          ..stop()
          ..reverse().then((_) => setState(() {
                _spiderfyCluster = null;
              }));
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

    Size size = getClusterSize(cluster);
    Anchor anchor =
        Anchor.forPos(widget.options.anchor, size.width, size.height);

    final width = size.width - anchor.left;
    final height = size.height - anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return widget.map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  List<Widget> _buildLayer(layer) {
    List<Widget> layers = [];

    if (layer is MarkerNode) {
      if (!_boundsContainsMarker(layer)) {
        return List<Widget>();
      }

      // fadein if
      // animating and
      // zoomin and parent has the previus zoom
      if (_zoomController.isAnimating &&
          (_currentZoom > _previusZoom && layer.parent.zoom == _previusZoom)) {
        // marker
        layers.add(_buildMarker(
            layer,
            _zoomController,
            FadeType.FadeIn,
            TranslateType.FromNewPosToMyPos,
            _getPixelFromMarker(layer, layer.parent.point)));
        //parent
        layers.add(_buildCluster(layer.parent, FadeType.FadeOut));
      } else {
        layers.add(_buildMarker(layer, _zoomController));
      }
    }
    if (layer is MarkerClusterNode) {
      if (!_boundsContainsCluster(layer)) {
        return List<Widget>();
      }

      // fadein if
      // animating and
      // zoomout and children is more than one or zoomin and father has same point
      if (_zoomController.isAnimating &&
          (_currentZoom < _previusZoom && layer.children.length > 1)) {
        // cluster
        layers.add(_buildCluster(layer, FadeType.FadeIn));
        // children
        layer.children.forEach((child) {
          if (child is MarkerNode) {
            layers.add(_buildMarker(
                child,
                _zoomController,
                FadeType.FadeOut,
                TranslateType.FromMyPosToNewPos,
                _getPixelFromMarker(child, layer.point)));
          } else {
            layers.add(_buildCluster(
                child,
                FadeType.FadeOut,
                TranslateType.FromMyPosToNewPos,
                _getPixelFromCluster(child, layer.point)));
          }
        });
      } else if (_zoomController.isAnimating &&
          (_currentZoom > _previusZoom && layer.parent.point != layer.point)) {
        // cluster
        layers.add(_buildCluster(
            layer,
            FadeType.FadeIn,
            TranslateType.FromNewPosToMyPos,
            _getPixelFromCluster(layer, layer.parent.point)));
        //parent
        layers.add(_buildCluster(layer.parent, FadeType.FadeOut));
      } else {
        if (_isSpiderfyCluster(layer)) {
          layers.addAll(_buildSpiderfyCluster(layer, _currentZoom));
        } else {
          layers.add(_buildCluster(layer));
        }
      }
    }

    return layers;
  }

  List<Widget> _buildLayers() {
    if (widget.map.zoom != _previusZoomDouble) {
      _previusZoomDouble = widget.map.zoom;

      _unspiderfy();
    }

    int zoom = widget.map.zoom.ceil();

    List<Widget> layers = [];

    if (_polygon != null) layers.add(_polygon);

    if (zoom < _currentZoom || zoom > _currentZoom) {
      _previusZoom = _currentZoom;
      _currentZoom = zoom;

      _zoomController
        ..reset()
        ..forward().then((_) => setState(() {
              _hidePolygon();
            })); // for remove previus layer (animation)
    }

    _topClusterLevel.recurvisely(_currentZoom, (layer) {
      layers.addAll(_buildLayer(layer));
    });

    return layers;
  }

  _isSpiderfyCluster(MarkerClusterNode cluster) {
    return _spiderfyCluster != null && _spiderfyCluster.point == cluster.point;
  }

  Function _onClusterTap(MarkerClusterNode cluster) {
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
        widget.options.onClusterTap(cluster);
      }

      // check if children can uncluster
      final cannotDivide = cluster.markers.every((marker) =>
          marker.parent.zoom == _maxZoom &&
          marker.parent == cluster.markers[0].parent);
      if (cannotDivide) {
        _spiderfy(cluster);
        return null;
      }

      if (!widget.options.zoomToBoundsOnClick) return null;

      _showPolygon(cluster.markers.fold<List<LatLng>>(
          [], (result, marker) => result..add(marker.point)));

      final center = widget.map.center;
      final dest = widget.map
          .getBoundsCenterZoom(cluster.bounds, widget.options.fitBoundsOptions);

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
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          _zoomTween.evaluate(animation),
        );
      };

      _fitBoundController.addListener(listener);

      _fitBoundController.forward().then((_) {
        _fitBoundController
          ..removeListener(listener)
          ..reset();
      });
    };
  }

  _showPolygon(List<LatLng> points) {
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

  _hidePolygon() {
    if (widget.options.showPolygon) {
      setState(() {
        _polygon = null;
      });
    }
  }

  Function _onMarkerTap(MarkerNode marker) {
    return () {
      print('tapped!!');

      if (_zoomController.isAnimating ||
          _centerMarkerController.isAnimating ||
          _fitBoundController.isAnimating) return null;

      // This is handled as an optional callback rather than leaving the package
      // user to wrap their Marker child Widget in a GestureDetector as only one
      // GestureDetector gets triggered per gesture (usually the child one) and
      // therefore this _onMarkerTap function never gets called.
      if (widget.options.onMarkerTap != null) {
        widget.options.onMarkerTap(marker.marker);
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
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          widget.map.zoom,
        );
      };

      _centerMarkerController.addListener(listener);

      _centerMarkerController.forward().then((_) {
        _centerMarkerController
          ..removeListener(listener)
          ..reset();
      });
    };
  }

  List<Point> _generatePointSpiderfy(int count, Point center) {
    if (widget.options.spiderfyShapePositions != null) {
      return widget.options.spiderfyShapePositions(count, center);
    }
    if (count >= widget.options.circleSpiralSwitchover) {
      return Spiderfy.spiral(
          widget.options.spiderfySpiralDistanceMultiplier, count, center);
    }

    return Spiderfy.circle(widget.options.spiderfyCircleRadius, count, center);
  }

  @override
  void initState() {
    _currentZoom = _previusZoom = widget.map.zoom.ceil();
    _minZoom = widget.map.options.minZoom?.ceil() ?? 1;
    _maxZoom = widget.map.options.maxZoom?.floor() ?? 20;

    _initializeAnimationController();
    _initializeClusters();
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
      _initializeClusters();
      _addLayers();
    }
    super.didUpdateWidget(oldWidget);
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
