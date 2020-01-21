import 'dart:developer';

import 'package:flutter/widgets.dart';

class ClipCoordinates extends StatelessWidget {
  final Rect container;
  final Rect rect;
  final Widget child;

  static const clipRectangle = Rect.fromLTRB(-1, -1, 1, 1);

  const ClipCoordinates(
      {Key key,
      @required this.rect,
      @required this.child,
      this.container = clipRectangle})
      : assert(rect != null),
        assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) => CustomSingleChildLayout(
      delegate: ClipCoordinatesLayoutDelegate(rect, container), child: child);
}

class ClipCoordinatesLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect rect;
  final Rect container;

  const ClipCoordinatesLayoutDelegate(this.rect, this.container)
      : assert(rect != null);
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = size.width / container.width * (rect.left - container.left);
    final y = size.height / container.height * (rect.top - container.top);
    return Offset(x, y);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final parentSize = super.getSize(constraints);
    final childSize = Size(parentSize.width * rect.width / container.width,
        parentSize.height * rect.height / container.height);

    if (childSize.height < 0) {
      log("upps");
    }

    return BoxConstraints.tightFor(
        width: childSize.width, height: childSize.height);
  }

  @override
  bool shouldRelayout(ClipCoordinatesLayoutDelegate oldDelegate) =>
      rect != oldDelegate.rect;
}
