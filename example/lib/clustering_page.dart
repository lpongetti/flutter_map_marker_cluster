import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster_example/drawer.dart';
import 'package:latlong2/latlong.dart';

class ClusteringPage extends StatefulWidget {
  static const String route = 'clusteringPage';

  const ClusteringPage({super.key});

  @override
  State<ClusteringPage> createState() => _ClusteringPageState();
}

class _ClusteringPageState extends State<ClusteringPage> {

  late List<Marker> markers;
  late int pointIndex;
  List<LatLng> points = [
    const LatLng(51.5, -0.09),
    const LatLng(49.8566, 3.3522),
  ];

  @override
  void initState() {
    pointIndex = 0;
    markers = [
      Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: points[pointIndex],
        child: const Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
      const Marker(
        alignment: Alignment.center,
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        child: Icon(Icons.pin_drop),
      ),
    ];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clustering Page'),
      ),
      drawer: buildDrawer(context, ClusteringPage.route),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pointIndex++;
          if (pointIndex >= points.length) {
            pointIndex = 0;
          }
          setState(() {
            markers[0] = Marker(
              point: points[pointIndex],
              alignment: Alignment.center,
              height: 30,
              width: 30,
              child: const Icon(Icons.pin_drop),
            );
            markers = List.from(markers);
          });
        },
        child: const Icon(Icons.refresh),
      ),
      body: FlutterMap(
          options: MapOptions(
            initialCenter: points[0],
            initialZoom: 5,
            maxZoom: 15,
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                spiderfyCircleRadius: 80,
                spiderfySpiralDistanceMultiplier: 2,
                circleSpiralSwitchover: 12,
                maxClusterRadius: 120,
                rotate: true,
                size: const Size(40, 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(50),
                maxZoom: 15,
                markers: markers,
                polygonOptions: const PolygonOptions(
                    borderColor: Colors.blueAccent,
                    color: Colors.black12,
                    borderStrokeWidth: 3),
                builder: (context, markers) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue,
                    ),
                    child: Center(
                      child: Text(
                        markers.length.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}
