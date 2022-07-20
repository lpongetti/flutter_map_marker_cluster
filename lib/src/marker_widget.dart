import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';

class MarkerWidget extends StatelessWidget {
  final MarkerNode marker;
  final VoidCallback onTap;

  MarkerWidget({
    required this.marker,
    required this.onTap,
  }) : super(key: ObjectKey(marker));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: marker.builder(context),
    );
  }
}
