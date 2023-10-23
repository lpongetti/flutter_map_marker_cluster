import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster_example/clustering_many_markers_page.dart';
import 'package:flutter_map_marker_cluster_example/clustering_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clustering Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ClusteringPage(),
      routes: <String, WidgetBuilder>{
        ClusteringPage.route: (context) => const ClusteringPage(),
        ClusteringManyMarkersPage.route: (context) =>
            const ClusteringManyMarkersPage(),
      },
    );
  }
}
