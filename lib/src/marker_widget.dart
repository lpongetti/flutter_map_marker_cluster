import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/src/node/marker_node.dart';

class MarkerWidget extends StatelessWidget {
  final MarkerNode marker;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final Function(bool)? onHover;
  final bool buildOnHover;
  final bool markerChildBehavior;
  final double opacity;
  final bool absorbing;

  MarkerWidget({
    required this.marker,
    required this.onTap,
    this.onDoubleTap,
    required this.markerChildBehavior,
    this.onHover,
    this.buildOnHover = false,
    this.opacity = 1.0,
    this.absorbing = false,
  }) : super(key: marker.key ?? ObjectKey(marker.marker));

  @override
  Widget build(BuildContext context) {
    Widget content = markerChildBehavior
        ? marker.child
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            child: buildOnHover && onHover != null
                ? MouseRegion(
                    onEnter: (_) => onHover!(true),
                    onExit: (_) => onHover!(false),
                    child: marker.child,
                  )
                : marker.child,
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
