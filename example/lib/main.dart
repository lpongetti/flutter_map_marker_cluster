import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';

final markers = [
  Marker(
      anchorPos: AnchorPos.align(AnchorAlign.center),
      height: 30,
      width: 30,
      point: LatLng(51.5, -0.09),
      builder: (ctx) => Icon(Icons.pin_drop)),
  Marker(
    anchorPos: AnchorPos.align(AnchorAlign.center),
    height: 30,
    width: 30,
    point: LatLng(53.3498, -6.2603),
    builder: (ctx) => Icon(Icons.pin_drop),
  ),
  Marker(
    anchorPos: AnchorPos.align(AnchorAlign.center),
    height: 30,
    width: 30,
    point: LatLng(53.3488, -6.2613),
    builder: (ctx) => Icon(Icons.pin_drop),
  ),
  Marker(
    anchorPos: AnchorPos.align(AnchorAlign.center),
    height: 30,
    width: 30,
    point: LatLng(48.8566, 2.3522),
    builder: (ctx) => Icon(Icons.pin_drop),
  ),
  Marker(
    anchorPos: AnchorPos.align(AnchorAlign.center),
    height: 30,
    width: 30,
    point: LatLng(49.8566, 3.3522),
    builder: (ctx) => Icon(Icons.pin_drop),
  ),
];

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: new MapOptions(
        zoom: 2,
        minZoom: 2,
        maxZoom: 16,
        plugins: [
          MarkerClusterGroupPlugin(),
        ],
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerClusterGroupLayerOptions(
          maxClusterRadius: 120,
          height: 40,
          width: 40,
          fitBoundsOptions: FitBoundsOptions(
            padding: EdgeInsets.all(50),
          ),
          markers: markers,
          polygonOptions: PolygonOptions(
              borderColor: Colors.blueAccent,
              color: Colors.black12,
              borderStrokeWidth: 3),
          builder: (context, markers) {
            return FloatingActionButton(
              child: Text(markers.length.toString()),
              onPressed: null,
            );
          },
        ),
      ],
    );
  }
}
