// @dart=2.9
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_marker_cluster_example/clustering_many_markers_page.dart';
import 'package:flutter_map_marker_cluster_example/clustering_page.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clustering Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ClusteringPage(),
      routes: <String, WidgetBuilder>{
        ClusteringPage.route: (context) => ClusteringPage(),
        ClusteringManyMarkersPage.route: (context) => ClusteringManyMarkersPage(),
      },
    );
  }
}

