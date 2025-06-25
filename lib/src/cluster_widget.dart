import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class ClusterWidget extends StatelessWidget {
  final MarkerClusterNode cluster;
  final ClusterWidgetBuilder builder;
  final VoidCallback onTap;
  final double opacity;
  final bool absorbing;

  ClusterWidget({
    required this.cluster,
    required this.builder,
    required this.onTap,
    this.opacity = 1.0,
    this.absorbing = false,
  }) : super(key: ObjectKey(cluster));

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: builder(context, cluster.mapMarkers),
    );
    if (opacity < 1.0 || absorbing) {
      content = AbsorbPointer(
        absorbing: absorbing,
        child: Opacity(
          opacity: opacity,
          child: content,
        ),
      );
    }
    return content;
  }
}
