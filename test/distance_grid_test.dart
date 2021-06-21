import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/src/core/distance_grid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('addObject', () {
    var grid = DistanceGrid(100),
        obj = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => FlutterLogo(),
        );

    grid.addObject(obj, Point(0, 0));
    expect(grid.removeObject(obj), true);
  });

  test('eachObject', () {
    var grid = DistanceGrid(100),
        obj = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
        );

    grid.addObject(obj, Point(0, 0));

    grid.eachObject((o) {
      expect(o, obj);
    });
  });

  test('getNearObject', () {
    var grid = DistanceGrid(100),
        obj = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
        );

    grid.addObject(obj, Point(0, 0));

    expect(grid.getNearObject(Point(50, 50)), obj);
    expect(grid.getNearObject(Point(100, 0)), obj);
  });

  test('getNearObject double', () {
    var grid = DistanceGrid(100),
        obj = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
        );

    grid.addObject(obj, Point(0, 0));

    expect(grid.getNearObject(Point(50.0, 50.0)), obj);
    expect(grid.getNearObject(Point(100.0, 0.0)), obj);
    expect(grid.getNearObject(Point(100.1, 0.0)), null);
  });

  test('getNearObject with cellSize 0', () {
    var grid = DistanceGrid(0),
        obj1 = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
        ),
        obj2 = Marker(
          point: LatLng(2, 3),
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
        );

    grid.addObject(obj1, Point(50, 50));
    grid.addObject(obj2, Point(0, 0));

    expect(grid.getNearObject(Point(50, 50)), obj1);
    expect(grid.getNearObject(Point(0, 0)), obj2);
  });

  test('getNearObject with cellSize 0 double', () {
    var grid = DistanceGrid(0),
        obj1 = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
        ),
        obj2 = Marker(
          point: LatLng(2, 3),
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
        );

    grid.addObject(obj1, Point(50.0, 50.0));
    grid.addObject(obj2, Point(0.0, 0.0));

    expect(grid.getNearObject(Point(50.0, 50.0)), obj1);
    expect(grid.getNearObject(Point(0, 0)), obj2);
  });
}
