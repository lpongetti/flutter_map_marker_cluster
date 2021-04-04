import 'package:flutter_map_marker_cluster/src/core/quick_hull.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('creates a hull', () {
    expect(
        QuickHull.getConvexHull(
          [
            LatLng(0, 0),
            LatLng(10, 0),
            LatLng(10, 10),
            LatLng(0, 10),
            LatLng(5, 5),
          ],
        ),
        [
          LatLng(0, 10),
          LatLng(10, 10),
          LatLng(10, 0),
          LatLng(0, 0),
        ]);
  });

  test('creates a hull for vertically-aligned objects', () {
    expect(
        QuickHull.getConvexHull(
          [
            LatLng(0, 0),
            LatLng(5, 0),
            LatLng(10, 0),
          ],
        ),
        [
          LatLng(0, 0),
          LatLng(10, 0),
        ]);
  });

  test('creates a hull for horizontally-aligned objects', () {
    expect(
        QuickHull.getConvexHull(
          [
            LatLng(0, 0),
            LatLng(0, 5),
            LatLng(0, 10),
          ],
        ),
        [
          LatLng(0, 0),
          LatLng(0, 10),
        ]);
  });
}
