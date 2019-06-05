import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/center_zoom.dart' show CenterZoom;
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/src/core/distance_grid.dart';
import 'package:flutter_map_marker_cluster/src/core/quick_hull.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:latlong/latlong.dart';

enum _FadeType {
  None,
  FadeIn,
  FadeOut,
}

enum _TranslateType {
  None,
  To,
  From,
}

class PolygonOptions {
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;

  const PolygonOptions({
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });
}

class MarkerClusterGroupPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    return MarkerClusterGroupLayer(options, mapState, stream);
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MarkerClusterGroupLayerOptions;
  }
}

typedef ClusterWidgetBuilder = Widget Function(
    BuildContext context, List<Marker> markers);

class MarkerClusterGroupLayerOptions extends LayerOptions {
  final ClusterWidgetBuilder builder;
  final List<Marker> markers;
  final double width;
  final double height;
  final int maxClusterRadius;
  final FitBoundsOptions fitBoundsOptions;
  final bool zoomToBoundsOnClick;
  final Duration animationDuration;
  final bool centerMarkerOnClick;
  final int spiderfyDistanceMultiplier;
  final int circleSpiralSwitchover;
  final List<Point> Function(int, Point) spiderfyShapePositions;
  final PolygonOptions polygonOptions;

  MarkerClusterGroupLayerOptions({
    @required this.builder,
    this.markers = const [],
    this.width = 30,
    this.height = 30,
    this.maxClusterRadius = 80,
    this.animationDuration = const Duration(milliseconds: 500),
    this.fitBoundsOptions =
        const FitBoundsOptions(padding: EdgeInsets.all(12.0)),
    this.zoomToBoundsOnClick = true,
    this.centerMarkerOnClick = true,
    this.spiderfyDistanceMultiplier = 1,
    this.circleSpiralSwitchover = 9,
    this.spiderfyShapePositions,
    this.polygonOptions = const PolygonOptions(),
  }) : assert(builder != null);
}

class MarkerClusterGroupLayer extends StatefulWidget {
  final MarkerClusterGroupLayerOptions options;
  final MapState map;
  final Stream<Null> stream;

  MarkerClusterGroupLayer(this.options, this.map, this.stream);

  @override
  _MarkerClusterGroupLayerState createState() =>
      _MarkerClusterGroupLayerState(this.options, this.map, this.stream);
}

class _MarkerClusterGroupLayerState extends State<MarkerClusterGroupLayer>
    with TickerProviderStateMixin {
  final MarkerClusterGroupLayerOptions options;
  final MapState map;
  final Stream<Null> stream;
  Map<int, DistanceGrid<MarkerClusterNode>> _gridClusters = {};
  Map<int, DistanceGrid<MarkerNode>> _gridUnclustered = {};
  MarkerClusterNode _topClusterLevel;
  int maxZoom;
  int minZoom;
  int currentZoom;
  int previusZoom;
  double previusZoomDouble;
  AnimationController _zoomController;
  AnimationController _fitBoundController;
  AnimationController _centerMarkerController;
  AnimationController _spiderfyController;
  MarkerClusterNode _spiderfyCluster;
  PolygonLayer _polygon;

  _MarkerClusterGroupLayerState(this.options, this.map, this.stream);

  CustomPoint<num> _getPixelFromPoint(LatLng point) {
    var pos = map.project(point);
    return pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
        map.getPixelOrigin();
  }

  Point _getPixelFromMarker(MarkerNode marker) {
    final pos = _getPixelFromPoint(marker.point);
    final x = (pos.x - (marker.width - marker.anchor.left)).toDouble();
    final y = (pos.y - (marker.height - marker.anchor.top)).toDouble();
    return Point(x, y);
  }

  Point _getPixelFromCluster(MarkerClusterNode cluster) {
    final pos = _getPixelFromPoint(cluster.point);
    final x = (pos.x - options.width / 2).toDouble();
    final y = (pos.y - options.height / 2).toDouble();
    return Point(x, y);
  }

  _initializeAnimationController() {
    _zoomController = AnimationController(
      vsync: this,
      duration: options.animationDuration,
    );

    _fitBoundController = AnimationController(
      vsync: this,
      duration: options.animationDuration,
    );

    _centerMarkerController = AnimationController(
      vsync: this,
      duration: options.animationDuration,
    );

    _spiderfyController = AnimationController(
      vsync: this,
      duration: options.animationDuration,
    );
  }

  _initializeClusters() {
    // set up DistanceGrids for each zoom
    for (var zoom = maxZoom; zoom >= minZoom; zoom--) {
      _gridClusters[zoom] = DistanceGrid(options.maxClusterRadius);
      _gridUnclustered[zoom] = DistanceGrid(options.maxClusterRadius);
    }

    _topClusterLevel = MarkerClusterNode(
      zoom: minZoom - 1,
      map: map,
    );
  }

  _addLayer(MarkerNode marker) {
    for (var zoom = maxZoom; zoom >= minZoom; zoom--) {
      var markerPoint = map.project(marker.point, zoom.toDouble());
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

        var newCluster = MarkerClusterNode(zoom: zoom, map: map)
          ..addChild(closest)
          ..addChild(marker);

        _gridClusters[zoom].addObject(
            newCluster, map.project(newCluster.point, zoom.toDouble()));

        //First create any new intermediate parent clusters that don't exist
        var lastParent = newCluster;
        for (var z = zoom - 1; z > parent.zoom; z--) {
          var newParent = MarkerClusterNode(
            zoom: z,
            map: map,
          );
          newParent.addChild(lastParent);
          lastParent = newParent;
          _gridClusters[z]
              .addObject(lastParent, map.project(closest.point, z.toDouble()));
        }
        parent.addChild(lastParent);

        _removeFromGridUnclustered(closest, zoom);
        return;
      }

      _gridUnclustered[zoom].addObject(marker, markerPoint);
    }

    //Didn't get in anything, add us to the top
    _topClusterLevel.addChild(marker);
  }

  _addLayers() {
    for (var marker in options.markers) {
      _addLayer(MarkerNode(marker));
    }

    _topClusterLevel.recalulateBounds();
  }

  _removeFromGridUnclustered(MarkerNode marker, int zoom) {
    for (; zoom >= minZoom; zoom--) {
      if (!_gridUnclustered[zoom].removeObject(marker)) {
        break;
      }
    }
  }

  Animation<double> _fadeAnimation(
      AnimationController controller, _FadeType fade) {
    if (fade == _FadeType.FadeIn)
      return Tween<double>(begin: 0.0, end: 1.0).animate(controller);
    if (fade == _FadeType.FadeOut)
      return Tween<double>(begin: 1.0, end: 0.0).animate(controller);

    return null;
  }

  Animation<Point> _translateAnimation(AnimationController controller,
      _TranslateType translate, Point pos, Point newPos) {
    if (translate == _TranslateType.From)
      return Tween<Point>(
        begin: Point(newPos.x, newPos.y),
        end: Point(pos.x, pos.y),
      ).animate(controller);
    if (translate == _TranslateType.To)
      return Tween<Point>(
        begin: Point(pos.x, pos.y),
        end: Point(newPos.x, newPos.y),
      ).animate(controller);

    return null;
  }

  Widget _buildMarker(MarkerNode marker, AnimationController controller,
      [_FadeType fade = _FadeType.None,
      _TranslateType translate = _TranslateType.None,
      Point newPos]) {
    assert((translate == _TranslateType.None && newPos == null) ||
        (translate != _TranslateType.None && newPos != null));

    final pos = _getPixelFromMarker(marker);

    Animation<double> fadeAnimation = _fadeAnimation(controller, fade);
    Animation<Point> translateAnimation =
        _translateAnimation(controller, translate, pos, newPos);

    return AnimatedBuilder(
      animation: controller,
      child: GestureDetector(
        onTap: _onMarkerTap(marker),
        child: marker.builder(context),
      ),
      builder: (BuildContext context, Widget child) {
        return Positioned(
          width: marker.width,
          height: marker.height,
          left: translate == _TranslateType.None
              ? pos.x
              : translateAnimation.value.x,
          top: translate == _TranslateType.None
              ? pos.y
              : translateAnimation.value.y,
          child: Opacity(
            opacity: fade == _FadeType.None ? 1 : fadeAnimation.value,
            child: child,
          ),
        );
      },
    );
  }

  List<Widget> _buildSpiderfyCluster(MarkerClusterNode cluster, int zoom) {
    final pos = _getPixelFromCluster(cluster);

    final points = _generatePointSpiderfy(cluster.markers.length, pos);

    final fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.3).animate(_spiderfyController);

    List<Widget> results = [];

    results.add(
      AnimatedBuilder(
        animation: _spiderfyController,
        child: GestureDetector(
          onTap: _onClusterTap(cluster),
          child: options.builder(
            context,
            cluster.markers.map((node) => node.marker).toList(),
          ),
        ),
        builder: (BuildContext context, Widget child) {
          return Positioned(
            width: options.width,
            height: options.height,
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

      results.add(_buildMarker(marker, _spiderfyController, _FadeType.FadeIn,
          _TranslateType.To, points[i]));
    }

    return results;
  }

  Widget _buildCluster(MarkerClusterNode cluster,
      [_FadeType fade = _FadeType.None,
      _TranslateType translate = _TranslateType.None,
      Point newPos]) {
    assert((translate == _TranslateType.None && newPos == null) ||
        (translate != _TranslateType.None && newPos != null));

    final pos = _getPixelFromCluster(cluster);

    Animation<double> fadeAnimation = _fadeAnimation(_zoomController, fade);
    Animation<Point> translateAnimation =
        _translateAnimation(_zoomController, translate, pos, newPos);

    return AnimatedBuilder(
      animation: _zoomController,
      child: GestureDetector(
        onTap: _onClusterTap(cluster),
        child: options.builder(
          context,
          cluster.markers.map((node) => node.marker).toList(),
        ),
      ),
      builder: (BuildContext context, Widget child) {
        return Positioned(
          width: options.width,
          height: options.height,
          left: translate == _TranslateType.None
              ? pos.x
              : translateAnimation.value.x,
          top: translate == _TranslateType.None
              ? pos.y
              : translateAnimation.value.y,
          child: Opacity(
            opacity: fade == _FadeType.None ? 1 : fadeAnimation.value,
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

  List<Widget> _buildLayers() {
    if (map.zoom != previusZoomDouble) {
      previusZoomDouble = map.zoom;

      _unspiderfy();
    }

    int zoom = map.zoom.ceil();

    List<Widget> clusters = [];
    List<Widget> markers = [];

    if (zoom < currentZoom || zoom > currentZoom) {
      previusZoom = currentZoom;
      currentZoom = zoom;

      _zoomController
        ..reset()
        ..forward().then(
            (_) => setState(() {})); // for remove previus layer (animation)
    }

    _topClusterLevel.recurvisely(currentZoom, (layer) {
      if (layer is MarkerNode) {
        // fadein if
        // animating and
        // zoomin and parent has the previus zoom
        if (_zoomController.isAnimating &&
            (currentZoom > previusZoom && layer.parent.zoom == previusZoom)) {
          // marker
          markers.add(_buildMarker(layer, _zoomController, _FadeType.FadeIn,
              _TranslateType.From, _getPixelFromCluster(layer.parent)));
          //parent
          clusters.add(_buildCluster(layer.parent, _FadeType.FadeOut));
        } else {
          markers.add(_buildMarker(layer, _zoomController));
        }
      }
      if (layer is MarkerClusterNode) {
        // fadein if
        // animating and
        // zoomout and children is more than one or zoomin and father has same point
        if (_zoomController.isAnimating &&
            (currentZoom < previusZoom && layer.children.length > 1)) {
          // cluster
          clusters.add(_buildCluster(layer, _FadeType.FadeIn));
          // children
          layer.children.forEach((child) {
            if (child is MarkerNode) {
              markers.add(_buildMarker(
                  child,
                  _zoomController,
                  _FadeType.FadeOut,
                  _TranslateType.To,
                  _getPixelFromCluster(layer)));
            } else {
              clusters.add(_buildCluster(child, _FadeType.FadeOut,
                  _TranslateType.To, _getPixelFromCluster(layer)));
            }
          });
        } else if (_zoomController.isAnimating &&
            (currentZoom > previusZoom && layer.parent.point != layer.point)) {
          // cluster
          clusters.add(_buildCluster(layer, _FadeType.FadeIn,
              _TranslateType.From, _getPixelFromCluster(layer.parent)));
          //parent
          clusters.add(_buildCluster(layer.parent, _FadeType.FadeOut));
        } else {
          if (_isSpiderfyCluster(layer)) {
            clusters.addAll(_buildSpiderfyCluster(layer, currentZoom));
          } else {
            clusters.add(_buildCluster(layer));
          }
        }
      }
    });

    List<Widget> result = [];
    if (_polygon != null) result.add(_polygon);

    return result..addAll(clusters)..addAll(markers);
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

      // check if children can uncluster
      final cannotDivide =
          cluster.markers.every((marker) => marker.parent.zoom == maxZoom);
      if (cannotDivide) {
        _spiderfy(cluster);
        return null;
      }

      if (!options.zoomToBoundsOnClick) return null;

      _showPolygon(cluster.children.fold<List<LatLng>>([], (result, child) {
        if (child is MarkerNode) result.add(child.point);
        if (child is MarkerClusterNode) result.add(child.point);
        return result;
      }));

      Future.delayed(Duration(milliseconds: 500)).then((_) {
        _hidePolygon();

        final center = map.center;
        final dest =
            _getBoundsCenterZoom(cluster.bounds, options.fitBoundsOptions);

        final _latTween =
            Tween<double>(begin: center.latitude, end: dest.center.latitude);
        final _lngTween =
            Tween<double>(begin: center.longitude, end: dest.center.longitude);
        final _zoomTween =
            Tween<double>(begin: currentZoom.toDouble(), end: dest.zoom);

        Animation<double> animation = CurvedAnimation(
            parent: _fitBoundController, curve: Curves.fastOutSlowIn);

        final listener = () {
          map.move(
            LatLng(
                _latTween.evaluate(animation), _lngTween.evaluate(animation)),
            _zoomTween.evaluate(animation),
          );
        };

        _fitBoundController.addListener(listener);

        _fitBoundController.forward().then((_) {
          _fitBoundController
            ..removeListener(listener)
            ..reset();
        });
      });
    };
  }

  _showPolygon(List<LatLng> points) {
    setState(() {
      _polygon = PolygonLayer(
        PolygonLayerOptions(polygons: [
          Polygon(
            points: QuickHull.getConvexHull(points),
            borderStrokeWidth: options.polygonOptions.borderStrokeWidth,
            color: options.polygonOptions.color,
            borderColor: options.polygonOptions.borderColor,
          ),
        ]),
        map,
        stream,
      );
    });
  }

  _hidePolygon() {
    setState(() {
      _polygon = null;
    });
  }

  Function _onMarkerTap(MarkerNode marker) {
    return () {
      if (_zoomController.isAnimating ||
          _centerMarkerController.isAnimating ||
          _fitBoundController.isAnimating) return null;

      if (!options.centerMarkerOnClick) return null;

      final center = map.center;

      final _latTween =
          Tween<double>(begin: center.latitude, end: marker.point.latitude);
      final _lngTween =
          Tween<double>(begin: center.longitude, end: marker.point.longitude);

      Animation<double> animation = CurvedAnimation(
          parent: _centerMarkerController, curve: Curves.fastOutSlowIn);

      final listener = () {
        map.move(
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          map.zoom,
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

  CenterZoom _getBoundsCenterZoom(
      LatLngBounds bounds, FitBoundsOptions options) {
    var paddingTL =
        CustomPoint<double>(options.padding.left, options.padding.top);
    var paddingBR =
        CustomPoint<double>(options.padding.right, options.padding.bottom);

    var paddingTotalXY = paddingTL + paddingBR;

    var zoom = map.getBoundsZoom(bounds, paddingTotalXY, inside: false);
    zoom = min(options.maxZoom, zoom);

    var paddingOffset = (paddingBR - paddingTL) / 2;
    var swPoint = map.project(bounds.southWest, zoom);
    var nePoint = map.project(bounds.northEast, zoom);
    var center = map.unproject((swPoint + nePoint) / 2 + paddingOffset, zoom);
    return CenterZoom(
      center: center,
      zoom: zoom,
    );
  }

  List<Point> _generatePointSpiderfy(int count, Point center) {
    if (options.spiderfyShapePositions != null) {
      return options.spiderfyShapePositions(count, center);
    }
    if (count >= options.circleSpiralSwitchover) {
      return _generatePointsSpiral(count, center);
    }

    return _generatePointsCircle(count, center);
  }

  List<Point> _generatePointsSpiral(int count, Point center) {
    final pi2 = pi * 2;
    final spiralFootSeparation = 28; //related to size of spiral (experiment!)
    final spiralLengthStart = 11;
    final spiralLengthFactor = 5;

    // var spiderfyDistanceMultiplier = widget.spiderfyDistanceMultiplier,
    num legLength = options.spiderfyDistanceMultiplier * spiralLengthStart;
    final separation =
        options.spiderfyDistanceMultiplier * spiralFootSeparation;
    final lengthFactor =
        options.spiderfyDistanceMultiplier * spiralLengthFactor * pi2;
    num angle = 0;

    final result = List<Point>(count);
    // Higher index, closer position to cluster center.
    for (var i = count; i >= 0; i--) {
      // Skip the first position, so that we are already farther from center and we avoid
      // being under the default cluster icon (especially important for Circle Markers).
      if (i < count) {
        result[i] = CustomPoint<double>(center.x + legLength * cos(angle),
            center.y + legLength * sin(angle));
      }
      angle += separation / legLength + i * 0.0005;
      legLength += lengthFactor / angle;
    }
    return result;
  }

  List<Point> _generatePointsCircle(int count, Point center) {
    final pi2 = pi * 2;
    final circleFootSeparation = 25; //related to circumference of circle
    final circleStartAngle = 0;

    num circumference =
        options.spiderfyDistanceMultiplier * circleFootSeparation * (2 + count);
    double legLength = circumference / pi2; //radius from circumference
    double angleStep = pi2 / count;

    legLength = max(
        legLength,
        max(
            options.height,
            options
                .width)); // Minimum distance to get outside the cluster icon.

    final result = List<Point>(count);

    for (var i = 0; i < count; i++) {
      double angle = circleStartAngle + i * angleStep;

      result[i] = CustomPoint<double>(center.x + 5 + legLength * cos(angle),
          center.y + 5 + legLength * sin(angle));
    }
    return result;
  }

  @override
  void initState() {
    currentZoom = previusZoom = map.zoom.ceil();
    minZoom = map.options.minZoom.ceil();
    maxZoom = map.options.maxZoom.floor();

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
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        return Container(
          child: Stack(
            children: _buildLayers(),
          ),
        );
      },
    );
  }
}
