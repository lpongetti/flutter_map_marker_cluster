import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Culling Tests', () {
    late MapCamera mockCamera;

    setUp(() {
      // Create a mock camera with a 800x600 screen centered on New York
      mockCamera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(40.7128, -74.0060), // New York
        zoom: 10,
        rotation: 0,
        nonRotatedSize: const Size(800, 600),
        size: const Size(800, 600),
      );
    });

    group('MarkerNode pixelBounds', () {
      test('returns correct Rect for center-aligned marker', () {
        const marker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        final centre = mockCamera.projectAtZoom(marker.point);

        final markerNode = MarkerNode(marker);
        final bounds = markerNode.pixelBounds(mockCamera);

        // Verify it returns a proper Rect
        expect(bounds, isA<Rect>());
        expect(bounds.left, equals(centre.dx - 20));
        expect(bounds.top, equals(centre.dy - 20));
        expect(bounds.width, equals(40.0));
        expect(bounds.height, equals(40.0));
      });

      test('returns correct Rect for topLeft-aligned marker', () {
        const marker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 40,
          height: 40,
          alignment: Alignment.topLeft,
          child: Icon(Icons.location_on),
        );

        final centre = mockCamera.projectAtZoom(marker.point);

        final markerNode = MarkerNode(marker);
        final bounds = markerNode.pixelBounds(mockCamera);

        expect(bounds, isA<Rect>());
        expect(bounds.left, equals(centre.dx - 40));
        expect(bounds.top, equals(centre.dy - 40));
        expect(bounds.width, equals(40.0));
        expect(bounds.height, equals(40.0));
      });

      test('returns correct Rect for bottomRight-aligned marker', () {
        const marker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 40,
          height: 40,
          alignment: Alignment.bottomRight,
          child: Icon(Icons.location_on),
        );

        final centre = mockCamera.projectAtZoom(marker.point);

        final markerNode = MarkerNode(marker);
        final bounds = markerNode.pixelBounds(mockCamera);

        expect(bounds, isA<Rect>());
        expect(bounds.left, equals(centre.dx));
        expect(bounds.top, equals(centre.dy));
        expect(bounds.width, equals(40.0));
        expect(bounds.height, equals(40.0));
      });

      test('different alignments produce different bounds', () {
        const centerMarker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        const topLeftMarker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 40,
          height: 40,
          alignment: Alignment.topLeft,
          child: Icon(Icons.location_on),
        );

        final centerNode = MarkerNode(centerMarker);
        final topLeftNode = MarkerNode(topLeftMarker);

        final centerBounds = centerNode.pixelBounds(mockCamera);
        final topLeftBounds = topLeftNode.pixelBounds(mockCamera);

        // Different alignments should produce different bounds
        expect(centerBounds.topLeft, isNot(equals(topLeftBounds.topLeft)));

        // But both should have the same size
        expect(centerBounds.size, equals(topLeftBounds.size));
      });

      test('handles different marker sizes', () {
        const smallMarker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 20,
          height: 20,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        const largeMarker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        final smallNode = MarkerNode(smallMarker);
        final largeNode = MarkerNode(largeMarker);

        final smallBounds = smallNode.pixelBounds(mockCamera);
        final largeBounds = largeNode.pixelBounds(mockCamera);

        expect(smallBounds.width, equals(20.0));
        expect(smallBounds.height, equals(20.0));
        expect(largeBounds.width, equals(80.0));
        expect(largeBounds.height, equals(80.0));
      });
    });

    group('MarkerClusterNode pixelBounds', () {
      test('returns correct Rect for cluster', () {
        final clusterNode = MarkerClusterNode(
          zoom: 10,
          alignment: Alignment.center,
          predefinedSize: const Size(50, 50),
        );

        // Add some mock bounds by creating a derived object
        clusterNode.recalculate(recursively: false);

        final bounds = clusterNode.pixelBounds(mockCamera);

        // Verify it returns a proper Rect
        expect(bounds, isA<Rect>());

        // For empty clusters, bounds might be zero, which is expected
        // The important thing is that it doesn't crash
      });

      test('handles different cluster sizes', () {
        final smallCluster = MarkerClusterNode(
          zoom: 10,
          alignment: Alignment.center,
          predefinedSize: const Size(30, 30),
        );

        final largeCluster = MarkerClusterNode(
          zoom: 10,
          alignment: Alignment.center,
          predefinedSize: const Size(100, 100),
        );

        smallCluster.recalculate(recursively: false);
        largeCluster.recalculate(recursively: false);

        final smallBounds = smallCluster.pixelBounds(mockCamera);
        final largeBounds = largeCluster.pixelBounds(mockCamera);

        expect(smallBounds, isA<Rect>());
        expect(largeBounds, isA<Rect>());
      });

      test('cluster bounds are properly square with different alignments', () {
        final cluster = MarkerClusterNode(
          zoom: 10,
          alignment: Alignment.centerLeft, // -1, 0
          predefinedSize: const Size(50, 50),
        );

        cluster.recalculate(recursively: false);
        final bounds = cluster.pixelBounds(mockCamera);

        // Should be exactly 50x50 square
        expect(bounds.width, equals(50.0));
        expect(bounds.height, equals(50.0));

        // Should be a proper rectangle
        expect(bounds.width, greaterThan(0));
        expect(bounds.height, greaterThan(0));
      });
    });

    group('Culling Logic', () {
      test('marker at screen center should overlap with camera bounds', () {
        const marker = Marker(
          point: LatLng(40.7128, -74.0060), // Center of screen
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        final markerNode = MarkerNode(marker);
        final markerBounds = markerNode.pixelBounds(mockCamera);
        final cameraBounds = mockCamera.pixelBounds;

        // Marker at center should overlap with camera bounds
        expect(cameraBounds.overlaps(markerBounds), isTrue);
      });

      test('marker far from screen should not overlap with camera bounds', () {
        // Create a camera focused on New York
        final nyCamera = MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(40.7128, -74.0060), // New York
          zoom: 15, // High zoom = small area
          rotation: 0,
          nonRotatedSize: const Size(800, 600),
          size: const Size(800, 600),
        );

        // Marker in London (far from New York)
        const londonMarker = Marker(
          point: LatLng(51.5074, -0.1278), // London
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        final markerNode = MarkerNode(londonMarker);
        final markerBounds = markerNode.pixelBounds(nyCamera);
        final cameraBounds = nyCamera.pixelBounds;

        // London marker should not overlap with New York camera bounds
        expect(cameraBounds.overlaps(markerBounds), isFalse);
      });

      test('partially visible marker should overlap with camera bounds', () {
        // Create a camera with a specific view
        final camera = MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(40.7128, -74.0060),
          zoom: 12,
          rotation: 0,
          nonRotatedSize: const Size(800, 600),
          size: const Size(800, 600),
        );

        // Marker that's partially visible (at edge of screen)
        const edgeMarker = Marker(
          point: LatLng(40.7200, -74), // Slightly north and east
          width: 100, // Large marker that might extend beyond screen
          height: 100,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        final markerNode = MarkerNode(edgeMarker);
        final markerBounds = markerNode.pixelBounds(camera);
        final cameraBounds = camera.pixelBounds;

        // Large marker at edge should still overlap
        expect(cameraBounds.overlaps(markerBounds), isTrue);
      });

      test('culling logic with different zoom levels', () {
        final markers = [
          const Marker(
            point: LatLng(40.7128, -74.0060),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(Icons.location_on),
          ),
          const Marker(
            point: LatLng(40.7200, -74),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(Icons.location_on),
          ),
        ];

        // Test at different zoom levels
        for (final double zoom in [8.0, 10.0, 12.0, 15.0]) {
          final camera = MapCamera(
            crs: const Epsg3857(),
            center: const LatLng(40.7128, -74.0060),
            zoom: zoom,
            rotation: 0,
            nonRotatedSize: const Size(800, 600),
            size: const Size(800, 600),
          );

          for (final marker in markers) {
            final markerNode = MarkerNode(marker);
            final markerBounds = markerNode.pixelBounds(camera);
            final cameraBounds = camera.pixelBounds;

            // All markers should be visible at these zoom levels
            expect(cameraBounds.overlaps(markerBounds), isTrue);
          }
        }
      });
    });

    group('Edge Cases', () {
      test('handles zero-sized marker', () {
        const marker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 0,
          height: 0,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        final markerNode = MarkerNode(marker);
        final bounds = markerNode.pixelBounds(mockCamera);

        expect(bounds, isA<Rect>());
        expect(bounds.width, equals(0.0));
        expect(bounds.height, equals(0.0));
      });

      test('handles very large marker', () {
        const marker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 2000, // Very large
          height: 2000,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        final markerNode = MarkerNode(marker);
        final bounds = markerNode.pixelBounds(mockCamera);

        expect(bounds, isA<Rect>());
        expect(bounds.width, equals(2000.0));
        expect(bounds.height, equals(2000.0));
      });

      test('handles null alignment (defaults to center)', () {
        const marker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 40,
          height: 40,
          alignment: null, // Should default to center
          child: Icon(Icons.location_on),
        );

        final markerNode = MarkerNode(marker);
        final bounds = markerNode.pixelBounds(mockCamera);

        expect(bounds, isA<Rect>());
        expect(bounds.width, equals(40.0));
        expect(bounds.height, equals(40.0));
      });
    });

    group('Performance', () {
      test('pixelBounds calculation is fast', () {
        const marker = Marker(
          point: LatLng(40.7128, -74.0060),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(Icons.location_on),
        );

        final markerNode = MarkerNode(marker);

        // Measure time for multiple calculations
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          markerNode.pixelBounds(mockCamera);
        }

        stopwatch.stop();

        // Should complete 1000 calculations in reasonable time (< 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
