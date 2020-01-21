import 'dart:math' show sqrt;
import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart'
    show Aabb2, Aabb3, Triangle, Vector2, Vector3;

extension ListExt<T> on List<T> {
  Iterable<V> mapIndex<V>(V Function(int index, T item) fn) =>
      asMap().entries.map((entry) => fn(entry.key, entry.value));
}

extension Aabb2Ext on Aabb2 {
  double get dx => this.max.x - this.min.x;
  double get dy => this.max.y - this.min.y;

  Rect get rect =>
      Rect.fromLTRB(this.min.x, this.max.y, this.max.x, this.min.y);
}

extension Aabb3Ext on Aabb3 {
  Aabb3 perspectiveTransformed(Matrix4 matrix) {
    final min = Vector3.copy(this.min);
    final max = Vector3.copy(this.max);
    matrix.perspectiveTransform(min);
    matrix.perspectiveTransform(max);
    return Aabb3.minMax(min, max);
  }

  double get dx => this.max.x - this.min.x;
  double get dy => this.max.y - this.min.y;
  double get dz => this.max.z - this.min.z;
}

extension TriangleExt on Triangle {
  List<Vector3> get points => [point0, point1, point2];

  Triangle perspectiveTransform(Matrix4 matrix) {
    matrix.perspectiveTransform(point0);
    matrix.perspectiveTransform(point1);
    matrix.perspectiveTransform(point2);

    return this;
  }

  Triangle perspectiveTransformed(Matrix4 matrix) =>
      Triangle.copy(this).perspectiveTransform(matrix);

  Triangle transformed(Matrix4 matrix) =>
      Triangle.copy(this)..transform(matrix);

  Vector3 get a => point0 - point1;
  Vector3 get b => point1 - point2;
  Vector3 get c => point2 - point0;

  Vector3 get normalVector => ((a - b).cross(b - c)).normalized();

  double get area2 {
    final la = a.length;
    final lb = b.length;
    final lc = c.length;

    final s = (la + lb + lc) / 2;
    return s * (s - la) * (s - lb) * (s - lc);
  }

  double get area => sqrt(area2);

  Vector3 get centroid => (point0 + point1 + point2) / 3;

  /// Check if a triangle is visible in the xy plane to a viewer in the positive side of the Z axys
  bool get isVisible => normalVector.z > 0;

  List<Offset> xyProjection() => points.map((v) => Offset(v.x, v.y)).toList();

  Triangle xyFlattened() => Triangle.points(Vector3(point0.x, point0.y, 0),
      Vector3(point1.x, point1.y, 0), Vector3(point2.x, point2.y, 0));
}

extension IterableVector3 on Iterable<Vector3> {
  Aabb2 boundingRect() {
    var minX = this.first.x;
    var maxX = this.first.x;
    var minY = this.first.y;
    var maxY = this.first.y;

    for (final point in this) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    return Aabb2.minMax(Vector2(minX, minY), Vector2(maxX, maxY));
  }

  Aabb3 boundingBox() {
    final maxPoint = Vector3.copy(this.first);
    final minPoint = Vector3.copy(this.first);

    for (final point in this) {
      if (point.x < minPoint.x) minPoint.x = point.x;
      if (point.y < minPoint.y) minPoint.y = point.y;
      if (point.z < minPoint.z) minPoint.z = point.z;
      if (point.x > maxPoint.x) maxPoint.x = point.x;
      if (point.y > maxPoint.y) maxPoint.y = point.y;
      if (point.z > maxPoint.z) maxPoint.z = point.z;
    }

    return Aabb3.minMax(minPoint, maxPoint);
  }
}

extension IterableTriangleExt on Iterable<Triangle> {
  Aabb2 boundingRect() => expand((t) => t.points).boundingRect();
  Aabb3 boundingBox() => expand((t) => t.points).boundingBox();
}
