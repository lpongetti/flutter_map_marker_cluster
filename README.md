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

[flutter_map](https://github.com/fleaflet/flutter_map/releases) package removed old layering system with v3.0.0 use `MarkerClusterLayerWidget` as member of `children` parameter list and configure it using `MarkerClusterLayerOptions`.

```dart
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clustering Many Markers Page')),
      drawer: buildDrawer(context, ClusteringManyMarkersPage.route),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng((maxLatLng.latitude + minLatLng.latitude) / 2,
              (maxLatLng.longitude + minLatLng.longitude) / 2),
          zoom: 6,
          maxZoom: 15,
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              fitBoundsOptions: const FitBoundsOptions(
                padding: EdgeInsets.all(50),
                maxZoom: 15,
              ),
              markers: markers,
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue),
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
```

### Run the example

See the `example/` folder for a working example app.

## Supporting Me

A donation through my Ko-Fi page would be infinitly appriciated:
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/lorenzopongetti)

but, if you can't or won't, a star on GitHub and a like on pub.dev would also go a long way!

Every donation gives me fuel to continue my open-source projects and lets me know that I'm doing a good job.
