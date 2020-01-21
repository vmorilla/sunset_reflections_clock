import 'dart:developer' show log;

import "package:test/test.dart";
import 'package:vector_math/vector_math_64.dart'
    show Vector3, Triangle, makeViewMatrix;
import '../extensions.dart';

void main() {
  test("Triangle area is correctly obtained", () {
    final triangle =
        Triangle.points(Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0.5, 1, 0));

    expect(triangle.area, equals(0.5));
  });

  test("Camera matrix and xxx", () {
    final cameraPosition = Vector3(0, 20, 10);
    final cameraFocus = Vector3(0, 0, 0);
    final upDirection = Vector3(0, 1, 0);
    final view = makeViewMatrix(cameraPosition, cameraFocus, upDirection);

    final origin = Vector3(0, 0, 0);
    final x = Vector3(1, 0, 0);
    final y = Vector3(0, 1, 0);
    final z = Vector3(0, 0, -1);

    log("Origin: ${view.transform3(origin)}");
    log("X: ${view.transform3(x)}");
    log("Y: ${view.transform3(y)}");
    log("Z: ${view.transform3(z)}");

    expect(z, equals(0));
  });
}
