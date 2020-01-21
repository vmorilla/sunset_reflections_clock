import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, makeViewMatrix;
import 'dart:math' show max;

abstract class Light {
  final Color color;
  Light(this.color);

  double intensityAt(Vector3 objectPosition, Vector3 objectNormal);
  Vector3 reflectionAngleAt(Vector3 objectPosition, Vector3 objectNormal);
}

class PointDiffuseLight extends Light {
  final Vector3 position;
  PointDiffuseLight({this.position, Color color}) : super(color);

  @override
  double intensityAt(Vector3 objectPosition, Vector3 objectNormal) {
    final lightVector = (objectPosition - position).normalized();
    final angle = objectNormal.dot(lightVector);
    return max(0, -angle);
  }

  @override
  Vector3 reflectionAngleAt(Vector3 objectPosition, Vector3 objectNormal) {
      final direction = (objectPosition - position).normalized();
      return direction - objectNormal * (2 * direction.dot(objectNormal));
  }


}

class DirectionalDiffuseLight extends Light {
  final Vector3 direction;
  DirectionalDiffuseLight({Vector3 direction, Color color})
      : this.direction = direction.normalized(),
        super(color);

  @override
  double intensityAt(Vector3 objectPosition, Vector3 objectNormal) {
    final angle = objectNormal.dot(direction);
    return max(0, -angle);
  }

  @override
  Vector3 reflectionAngleAt(Vector3 objectPosition, Vector3 objectNormal) =>
      direction - objectNormal * (2 * direction.dot(objectNormal));
}

class Scene3d {
  final Matrix4 cameraMatrix;
  final Vector3 cameraFocusDirection;
  final Matrix4 projectionMatrix;
  final Light light;

  Matrix4 _viewMatrix;

  Scene3d(
      {@required Vector3 cameraPosition,
      @required Vector3 cameraFocusPosition,
      @required Vector3 upDirection,
      this.projectionMatrix,
      this.light})
      : cameraMatrix =
            makeViewMatrix(cameraPosition, cameraFocusPosition, upDirection),
        cameraFocusDirection =
            (cameraFocusPosition - cameraPosition).normalized();

  Matrix4 get viewMatrix {
    _viewMatrix ??= projectionMatrix * cameraMatrix;
    return _viewMatrix;
  }
}
