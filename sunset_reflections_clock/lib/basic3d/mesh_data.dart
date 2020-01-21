import 'dart:ui' show Vertices;

import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart'
    show Aabb2, Aabb3, Quad, Triangle, Vector3;

import 'camera_body.dart';
import 'extensions.dart';
import 'scene3d.dart';
import 'textures.dart';
import 'uvmappers.dart';

class MeshData {
  final List<Triangle> triangles;

  MeshData(Iterable<Triangle> triangles) : triangles = triangles.toList();
  MeshData.fromQuad(Quad quad)
      : triangles = [
          Triangle.points(quad.point0, quad.point1, quad.point2),
          Triangle.points(quad.point2, quad.point3, quad.point0)
        ];

  Aabb3 _boundingBox;
  Aabb3 get boundingBox {
    if (_boundingBox == null) _boundingBox = vertices.boundingBox();
    return _boundingBox;
  }

  Aabb2 get boundingRect =>
      Aabb2.minMax(boundingBox.min.xy, boundingBox.max.xy);

  Map<Vector3, Vector3> _gouraudNormals;
  Vector3 gouraudNormal(Vector3 point) {
    if (_gouraudNormals == null) _gouraudNormals = _computeGouraudNormals();

    return _gouraudNormals[point];
  }

  Map<Vector3, Vector3> _computeGouraudNormals() {
    final verticesNormals = Map<Vector3, Vector3>();
    for (final triangle in triangles) {
      final faceNormal = triangle.normalVector;
      for (final vertex in triangle.points) {
        final vertexNormal = verticesNormals[vertex];
        if (vertexNormal != null) {
          vertexNormal.add(faceNormal);
        } else
          verticesNormals[vertex] = faceNormal;
      }
    }

    for (final normal in verticesNormals.values) {
      normal.normalize();
    }

    return verticesNormals;
  }

  Iterable<Vector3> get vertices => triangles.expand((t) => t.points);

  Vector3 dimensions() {
    final bb = vertices.boundingBox();
    return bb.max - bb.min;
  }

  MeshData transformed(Matrix4 matrix) =>
      MeshData(triangles.map((t) => t.transformed(matrix)));

  MeshData perspTransformed(Matrix4 matrix) =>
      MeshData(triangles.map((t) => t.perspectiveTransformed(matrix)));

  static Iterable<_FaceInfo> zip(MeshData worldView, MeshData clipView,
      [List<List<Offset>> uvCoordinates]) sync* {
    if (uvCoordinates != null)
      for (var i = 0; i < worldView.triangles.length; i++) {
        final uv = uvCoordinates[i];
        if (uv != null)
          yield _FaceInfo(
              worldView.triangles[i], clipView.triangles[i], uvCoordinates[i]);
      }
    else
      for (var i = 0; i < worldView.triangles.length; i++)
        yield _FaceInfo(worldView.triangles[i], clipView.triangles[i]);
  }

  MeshData reflectingSubset(Vector3 lightDirection, double minReflection) {
    final normlightDirection = lightDirection.normalized();
    final minReflection = 0.3;

    return MeshData(triangles
        .where((t) => -t.normalVector.dot(normlightDirection) > minReflection));
  }

  CameraMesh render(Scene3d scene, Texture texture, [UVMapper uvmapper]) {
    final worldMesh = this; // for clarity purposes
    final uvmap = uvmapper != null ? uvmapper(worldMesh, scene) : null;
    final clipMesh = worldMesh.perspTransformed(scene.viewMatrix);
    final triangles = zip(worldMesh, clipMesh, uvmap)
        // Triangles not facing the camera are discarded
        .where((t) => t.clipView.isVisible)
        .toList();

    triangles
        .sort((a, b) => a.clipView.centroid.z.compareTo(b.clipView.centroid.z));

    final colorTestPoint = triangles.worldPoints.first;
    final colorTest =
        texture.getColor(scene, colorTestPoint, gouraudNormal(colorTestPoint));
    final colors = colorTest != null
        ? triangles.worldPoints
            .map((v) => texture.getColor(scene, v, gouraudNormal(v)))
            .toList()
        : null;

    final textureCoordinates =
        uvmapper != null ? triangles.uvCoordinates.toList() : null;

    final vertices = Vertices(VertexMode.triangles, triangles.vertices.toList(),
        colors: colors, textureCoordinates: textureCoordinates);

    return CameraMesh(clipMesh.boundingRect, vertices);
  }
}

class _FaceInfo {
  final Triangle worldView;
  final Triangle clipView;
  final List<Offset> uv;

  _FaceInfo(this.worldView, this.clipView, [this.uv]);
}

extension on List<_FaceInfo> {
  Iterable<Offset> get vertices =>
      expand((t) => t.clipView.points.map((v) => Offset(v.x, v.y)));
  Iterable<Vector3> get worldPoints => expand((t) => t.worldView.points);
  Iterable<Offset> get uvCoordinates => expand((t) => t.uv);
}
