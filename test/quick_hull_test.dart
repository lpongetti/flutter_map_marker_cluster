import 'package:flutter_map_marker_cluster/src/core/quick_hull.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('creates a hull', () {
    expect(
        QuickHull.getConvexHull(
          [
            const LatLng(0, 0),
            const LatLng(10, 0),
            const LatLng(10, 10),
            const LatLng(0, 10),
            const LatLng(5, 5),
          ],
        ),
        [
          const LatLng(0, 10),
          const LatLng(10, 10),
          const LatLng(10, 0),
          const LatLng(0, 0),
        ]);
  });

  test('creates a hull for vertically-aligned objects', () {
    expect(
        QuickHull.getConvexHull(
          [
            const LatLng(0, 0),
            const LatLng(5, 0),
            const LatLng(10, 0),
          ],
        ),
        [
          const LatLng(0, 0),
          const LatLng(10, 0),
        ]);
  });

  test('creates a hull for horizontally-aligned objects', () {
    expect(
        QuickHull.getConvexHull(
          [
            const LatLng(0, 0),
            const LatLng(0, 5),
            const LatLng(0, 10),
          ],
        ),
        [
          const LatLng(0, 0),
          const LatLng(0, 10),
        ]);
  });
}
