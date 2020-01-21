import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'painters.dart';
import 'camera_body.dart';
import 'clip_coordinates.dart';
import 'extensions.dart';

class Path3D extends StatelessWidget {
  final Aabb2 viewPort;
  final CameraPath cameraPath;
  final Paint paint;
  final bool willChange;
  final bool isComplex;

  const Path3D(
      {Key key,
      this.viewPort,
      this.cameraPath,
      this.paint,
      this.willChange = false,
      this.isComplex = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) => ClipCoordinates(
      container: viewPort.rect,
      rect: cameraPath.containingRect,
      child: CustomPaint(
          willChange: willChange,
          isComplex: isComplex,
          painter: PathPainter(cameraPath, paint)));
}
