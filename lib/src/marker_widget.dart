import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';

class MarkerWidget extends StatelessWidget {
  final MarkerNode marker;
  final VoidCallback onTap;
  final Function(bool)? onHover;
  final bool buildOnHover;
  final Function()? hoverOnTap;

  MarkerWidget({
    required this.marker,
    required this.onTap,
    this.onHover,
    this.buildOnHover = false,
    this.hoverOnTap,
  }) : super(key: marker.key ?? ObjectKey(marker.marker));

  @override
  Widget build(BuildContext context) {
    final m = marker.builder(context);
    return buildOnHover
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hoverOnTap ?? onTap,
            child: onHover != null
                ? MouseRegion(
                    onEnter: (_) => onHover!(true),
                    onExit: (_) => onHover!(false),
                    child: m,
                  )
                : m)
        : m;
  }
}
