import 'dart:math' show atan2, max, min, pi, pow, sin;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart'
    show Triangle, Vector3, makeViewMatrix;

import 'extensions.dart';
import 'mesh_data.dart';
import 'scene3d.dart';

typedef UVMapper = List<List<Offset>> Function(
    MeshData worldView, Scene3d scene);

abstract class UVMappers {
  static List<List<Offset>> cylindrical(MeshData worldView, Scene3d scene) {
    final bb = worldView.boundingBox;

    Offset radialMapping(Vector3 p) => Offset(
        1 + atan2(p.x - bb.center.x, p.z - bb.center.z) / pi,
        (p.y - bb.min.y) / bb.dy);

    Offset flatMapping(Vector3 p) =>
        Offset((p.x - bb.min.x) / bb.dx, (p.z - bb.min.z / bb.dz));

    List<Offset> cylinderMapping(Triangle t) => (t.normalVector.y == 0
            ? t.points.map(radialMapping)
            : t.points.map(flatMapping))
        .toList();

    return worldView.triangles.map(cylinderMapping).toList();
  }

  static List<List<Offset>> flatFloor(MeshData worldView, Scene3d scene) {
    final bb = worldView.boundingBox;

    Offset flatMappingY(Vector3 p) =>
        Offset((p.x - bb.min.x) / bb.dx, (p.z - bb.min.z) / bb.dz);

    Offset flatMappingZ(Vector3 p) =>
        Offset((p.y - bb.min.y) / bb.dy, (p.x - bb.min.x) / bb.dx);

    List<Offset> flatMapping(Triangle t) => t.points
        .map(t.normalVector.y != 0 ? flatMappingY : flatMappingZ)
        .toList();

    return worldView.triangles.map(flatMapping).toList();
  }

  static List<List<Offset>> reflection(MeshData worldView, Scene3d scene) {
    // TODO: move to constants / scene / theme
    final lightPosition = Vector3(-800, 400, 200);
    final lightDirection = Vector3(-3, -1, 0).normalized();
    final reflectionFraction = 0;

    final lightViewMatrix = makeViewMatrix(
        lightPosition, lightPosition + lightDirection, Vector3(0, 1, 0));

    Offset baseMax = offsetNegativeInfinity;
    Offset baseMin = offsetInfinity;

    Offset topMax = offsetNegativeInfinity;
    Offset topMin = offsetInfinity;

    Iterable<List<Offset>> getRawOffsets() sync* {
      for (final t in worldView.triangles) {
        final lightFacing = t.transformed(lightViewMatrix);
        final cameraFacing = t.transformed(scene.viewMatrix);
        if (lightFacing.normalVector.z >= reflectionFraction &&
            cameraFacing.normalVector.z >= 0) {
          if (t.normalVector.y == 0) {
            final baseOffsets = cameraFacing.points.map((p) {
              final offset = Offset(p.x, p.y);
              baseMax = offsetMax(baseMax, offset);
              baseMin = offsetMin(baseMin, offset);
              return offset;
            }).toList();
            yield baseOffsets;
          } else {
            final topOffsets = cameraFacing.points.map((p) {
              final offset = Offset(p.x, p.y);
              topMax = offsetMax(topMax, offset);
              topMin = offsetMin(topMin, offset);
              return offset;
            }).toList();
            yield topOffsets;
          }
        } else {
          yield null;
        }
      }
    }

    double normalizedX(double x, double min, double max) =>
        pow(sin(pi / 2 * normalized(x, min, max)), 1 / 2);

    final rawOffset = getRawOffsets().toList();

    Offset baseNormalOffset(Offset raw) {
      return Offset(normalizedX(raw.dx, baseMax.dx, baseMin.dx),
          normalized(raw.dy, topMax.dy, baseMin.dy));
    }

    final normalOffsets = rawOffset
        .map((t) => t != null ? t.map(baseNormalOffset).toList() : null);

    return normalOffsets.toList();
  }
}

const offsetInfinity = Offset(double.infinity, double.infinity);
const offsetNegativeInfinity =
    Offset(double.negativeInfinity, double.negativeInfinity);

Offset offsetMax(Offset a, Offset b) =>
    Offset(max(a.dx, b.dx), max(a.dy, b.dy));
Offset offsetMin(Offset a, Offset b) =>
    Offset(min(a.dx, b.dx), min(a.dy, b.dy));
Offset divide(Offset a, Offset b) => Offset(a.dx / b.dx, a.dy / b.dy);

Offset normalizedOffset(Offset value, Offset min, Offset max) =>
    divide((value - min), (max - min));

double normalized(double value, double min, double max) =>
    (value - min) / (max - min);
