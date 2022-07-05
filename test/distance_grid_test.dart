import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/src/core/distance_grid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('addObject', () {
    final grid = DistanceGrid<Marker>(100),
        obj = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => const FlutterLogo(),
        );

    grid.addObject(obj, const Point(0, 0));
    expect(grid.removeObject(obj), true);
  });

  test('eachObject', () {
    final grid = DistanceGrid<Marker>(100),
        obj = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => const FlutterLogo(),
        );

    grid.addObject(obj, const Point(0, 0));

    grid.eachObject((o) {
      expect(o, obj);
    });
  });

  test('getNearObject', () {
    final grid = DistanceGrid<Marker>(100),
        obj = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => const FlutterLogo(),
        );

    grid.addObject(obj, const Point(0, 0));

    expect(grid.getNearObject(const Point(50, 50)), obj);
    expect(grid.getNearObject(const Point(100, 0)), obj);
  });

  test('getNearObject double', () {
    final grid = DistanceGrid<Marker>(100),
        obj = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => const FlutterLogo(),
        );

    grid.addObject(obj, const Point(0, 0));

    expect(grid.getNearObject(const Point(50.0, 50.0)), obj);
    expect(grid.getNearObject(const Point(100.0, 0.0)), obj);
    expect(grid.getNearObject(const Point(100.1, 0.0)), null);
  });

  test('getNearObject with cellSize 0', () {
    final grid = DistanceGrid<Marker>(0),
        obj1 = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => const FlutterLogo(),
        ),
        obj2 = Marker(
          point: LatLng(2, 3),
          builder: (ctx) => const FlutterLogo(),
        );

    grid.addObject(obj1, const Point(50, 50));
    grid.addObject(obj2, const Point(0, 0));

    expect(grid.getNearObject(const Point(50, 50)), obj1);
    expect(grid.getNearObject(const Point(0, 0)), obj2);
  });

  test('getNearObject with cellSize 0 double', () {
    final grid = DistanceGrid<Marker>(0),
        obj1 = Marker(
          point: LatLng(1, 2),
          builder: (ctx) => const FlutterLogo(),
        ),
        obj2 = Marker(
          point: LatLng(2, 3),
          builder: (ctx) => const FlutterLogo(),
        );

    grid.addObject(obj1, const Point(50.0, 50.0));
    grid.addObject(obj2, const Point(0.0, 0.0));

    expect(grid.getNearObject(const Point(50.0, 50.0)), obj1);
    expect(grid.getNearObject(const Point(0, 0)), obj2);
  });
}
