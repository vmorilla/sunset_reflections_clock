import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

abstract class CameraBody {
  final Aabb2 containingRect;

  const CameraBody(this.containingRect);
}

class CameraMesh extends CameraBody {
  final Vertices vertices;

  const CameraMesh(Aabb2 containingRect, this.vertices) : super(containingRect);
}

class CameraPath {
  final Path path;
  final Rect containingRect;

  CameraPath(this.path, this.containingRect);
}
