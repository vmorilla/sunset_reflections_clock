import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../basic3d/clip_coordinates.dart';
import '../basic3d/painters.dart';

class PositionTests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final container = Rect.fromLTRB(-1, 1, 1, -1);
    final rect = Rect.fromLTRB(0, 0, 1, -1);

    return Stack(fit: StackFit.expand, children: [
      Container(color: Colors.white),
      ClipCoordinates(
          container: container,
          rect: rect,
          child: Container(color: Colors.grey)),
      ClipCoordinates(
          rect: rect, container: container, child: TestPaint(rect: rect))
    ]);
  }
}

class TestPaint extends StatelessWidget {
  final Rect rect;

  const TestPaint({Key key, @required this.rect}) : super(key: key);

  @override
  Widget build(BuildContext context) => CustomPaint(painter: TestPainter(rect));
}

class TestPainter extends ClipCoordinatesPainter {
  const TestPainter(Rect rect)
      : assert(rect != null),
        super(rect);

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);

    canvas.drawRect(rect, Paint()..color = Colors.red.withAlpha(100));
    Paint paint = Paint()..color = Colors.black;
    canvas.drawLine(Offset(0, -1), Offset(1, 0), paint);
    canvas.drawLine(Offset(1, 0), Offset(0.8, -0.1), paint);
    canvas.drawLine(Offset(1, 0), Offset(0.9, -0.2), paint);
  }
}
