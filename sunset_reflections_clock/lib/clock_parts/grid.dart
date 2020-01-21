import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../basic3d/path3d.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'dart:math' show cos, max, min, pi, sin;

import '../main_model.dart';

extension MapExt<K, V> on Map<K, V> {
  /// Returns an iterable by applying `mapFn` to the index, key and value of each entry
  Iterable<T> mapIndex<T>(T Function(int index, K key, V value) mapFn) =>
      entries
          .toList()
          .asMap()
          .entries
          .map((entry) => mapFn(entry.key, entry.value.key, entry.value.value));

  void forEachIndex(void Function(int index, K key, V value) fn) {
    for (final entry in entries.toList().asMap().entries)
      fn(entry.key, entry.value.key, entry.value.value);
  }
}

Paint _gridBrush(Color color) => Paint()
  ..color = color
  ..strokeWidth = 0.002
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

class BackGrid extends StatelessWidget {
  final int position;

  const BackGrid({@required this.position, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    final cache = props.cache[position];
    final color = props.theme.digitsColors[position];

    return Path3D(
        viewPort: props.viewPort,
        cameraPath: cache.backGrid,
        paint: _gridBrush(color));
  }
}

class FrontGrid extends StatelessWidget {
  final int position;

  const FrontGrid({@required this.position, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    final cache = props.cache[position];

    return Path3D(
        viewPort: props.viewPort,
        cameraPath: cache.frontGrid,
        paint: _gridBrush(Colors.black));
  }
}

List<Vector2> clipLine(double x0, double y0, double x1, double y1, Rect rect) {
  double t(double v0, double v1, double value) => (value - v0) / (v1 - v0);
  double v(double v0, double v1, double t) => v0 + t * (v1 - v0);

  double minT = 0;
  double maxT = 1;

  if (x0 < rect.left)
    minT = max(minT, t(x0, x1, rect.left));
  else if (x0 > rect.right) minT = max(minT, t(x0, x1, rect.right));

  if (y0 < rect.top)
    minT = max(minT, t(y0, y1, rect.top));
  else if (y0 > rect.bottom) minT = max(minT, t(y0, y1, rect.bottom));

  if (x1 < rect.left)
    maxT = min(maxT, t(x0, x1, rect.left));
  else if (x1 > rect.right) maxT = min(maxT, t(x0, x1, rect.right));

  if (y1 < rect.top)
    maxT = min(maxT, t(x0, x1, rect.top));
  else if (y1 > rect.bottom) maxT = min(maxT, t(y0, y1, rect.bottom));

  if (minT <= 1 && maxT >= 0 && minT < maxT) {
    // FIXME: edge case if y negative
    // if (y0 < rect.top && y1 < rect.top) {
    //   log("Warning!!!!");
    // }
    return [
      Vector2(v(x0, x1, minT), v(y0, y1, minT)),
      Vector2(v(x0, x1, maxT), v(y0, y1, maxT))
    ];
  } else
    return null;
}

Path gridPath(Rect rect, double radius) {
  final path = Path();
  double x0, y0;

  void moveTo(double x, double y) {
    x0 = x;
    y0 = y;
  }

  void lineTo(double x1, double y1) {
    final line = clipLine(x0, y0, x1, y1, rect);
    if (line != null) {
      path.moveTo(line[0].x, line[0].y);
      path.lineTo(line[1].x, line[1].y);
    }
    moveTo(x1, y1);
  }

  void relativeLineTo(double dx, double dy) {
    lineTo(x0 + dx, y0 + dy);
  }

  void drawHalfHexagon(double x, double y) {
    moveTo(x + radius * cos(pi / 6), y + radius * sin(pi / 6));
    lineTo(x, y);
    relativeLineTo(-radius * cos(pi / 6), radius * sin(pi / 6));
    relativeLineTo(0, radius);
  }

  for (double y = rect.top; y < rect.bottom + radius; y += 3 * radius) {
    for (double x = rect.left - radius;
        x < rect.right + radius;
        x += 2 * radius * cos(pi / 6)) {
      drawHalfHexagon(x, y);
      drawHalfHexagon(x + radius * cos(pi / 6), y + radius * (1 + sin(pi / 6)));
    }
  }

  path.addRect(rect);

  return path;
}

// class GridPainter extends CustomPainter {
//   final Color color;
//   final Path path;
//   final String id;

//   GridPainter({this.color, this.path, this.id});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final brush = Paint()
//       ..color = color
//       ..strokeWidth = 0.002
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;

//     canvas.drawPath(path, brush);
//   }

//   @override
//   bool shouldRepaint(GridPainter oldDelegate) =>
//       oldDelegate.color != color || oldDelegate.path != path;
// }
