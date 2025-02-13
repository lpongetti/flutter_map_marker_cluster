import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/src/core/distance_grid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('addObject', () {
    final grid = DistanceGrid<Marker>(100),
        obj = const Marker(
          point: LatLng(1, 2),
          child: FlutterLogo(),
        );

    grid.addObject(obj, Offset.zero);
    expect(grid.removeObject(obj), true);
  });

  test('eachObject', () {
    final grid = DistanceGrid<Marker>(100),
        obj = const Marker(
          point: LatLng(1, 2),
          child: FlutterLogo(),
        );

    grid.addObject(obj, Offset.zero);

    grid.eachObject((o) {
      expect(o, obj);
    });
  });

  test('getNearObject', () {
    final grid = DistanceGrid<Marker>(100),
        obj = const Marker(
          point: LatLng(1, 2),
          child: FlutterLogo(),
        );

    grid.addObject(obj, Offset.zero);

    expect(grid.getNearObject(const Offset(50, 50)), obj);
    expect(grid.getNearObject(const Offset(100, 0)), obj);
  });

  test('getNearObject double', () {
    final grid = DistanceGrid<Marker>(100),
        obj = const Marker(
          point: LatLng(1, 2),
          child: FlutterLogo(),
        );

    grid.addObject(obj, Offset.zero);

    expect(grid.getNearObject(const Offset(50, 50)), obj);
    expect(grid.getNearObject(const Offset(100, 0)), obj);
    expect(grid.getNearObject(const Offset(100.1, 0)), null);
  });

  test('getNearObject with cellSize 0', () {
    final grid = DistanceGrid<Marker>(0),
        obj1 = const Marker(
          point: LatLng(1, 2),
          child: FlutterLogo(),
        ),
        obj2 = const Marker(
          point: LatLng(2, 3),
          child: FlutterLogo(),
        );

    grid.addObject(obj1, const Offset(50, 50));
    grid.addObject(obj2, Offset.zero);

    expect(grid.getNearObject(const Offset(50, 50)), obj1);
    expect(grid.getNearObject(Offset.zero), obj2);
  });

  test('getNearObject with cellSize 0 double', () {
    final grid = DistanceGrid<Marker>(0),
        obj1 = const Marker(
          point: LatLng(1, 2),
          child: FlutterLogo(),
        ),
        obj2 = const Marker(
          point: LatLng(2, 3),
          child: FlutterLogo(),
        );

    grid.addObject(obj1, const Offset(50, 50));
    grid.addObject(obj2, Offset.zero);

    expect(grid.getNearObject(const Offset(50, 50)), obj1);
    expect(grid.getNearObject(Offset.zero), obj2);
  });
}
