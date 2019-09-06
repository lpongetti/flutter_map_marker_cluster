# Flutter Map Marker Cluster

[![pub package](https://img.shields.io/pub/v/flutter_map_marker_cluster.svg)](https://pub.dartlang.org/packages/flutter_map_marker_cluster) ![travis](https://api.travis-ci.com/lpongetti/flutter_map_marker_cluster.svg?branch=master)

A Dart implementation of Leaflet.markercluster for Flutter apps.
This is a plugin for [flutter_map](https://github.com/johnpryan/flutter_map) package

<div style="text-align: center"><table><tr>
  <td style="text-align: center">
  <a href="https://github.com/lpongetti/flutter_map_marker_cluster/blob/master/example.gif">
    <img src="https://github.com/lpongetti/flutter_map_marker_cluster/blob/master/example.gif" width="200"/></a>
</td>
</tr></table></div>

## Usage

Add flutter_map and  flutter_map_marker_cluster to your pubspec:

```yaml
dependencies:
  flutter_map: any
  flutter_map_marker_cluster: any # or the latest version on Pub
```

Add it in you FlutterMap and configure it using `MarkerClusterGroupLayerOptions`.

```dart
  Widget build(BuildContext context) {
    return FlutterMap(
      options: new MapOptions(
        plugins: [
          MarkerClusterPlugin(),
        ],
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerClusterLayerOptions(
          maxClusterRadius: 120,
          size: Size(40, 40),
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
```

### Run the example

See the `example/` folder for a working example app.
