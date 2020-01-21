import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' show Triangle, Vector3;

import 'mesh_data.dart';

enum Meshes { tube, base, stand }

class MeshRegistry {
  Map<Meshes, MeshData> _meshes;
  MeshData operator [](Meshes id) => _meshes[id];

  MeshRegistry._() : _meshes = Map<Meshes, MeshData>();

  static Future<MeshRegistry> load(AssetBundle bundle, String location) async {
    final registry = MeshRegistry._();
    for (final key in Meshes.values) {
      final mesh = await _loadMesh(bundle, _meshKey(location, key));
      registry._meshes[key] = mesh;
    }

    return registry;
  }

  static String _meshKey(String location, Meshes mesh) =>
      "$location/${mesh.toString().split('.').last}.stl";

  static Future<MeshData> _loadMesh(AssetBundle bundle, String key) =>
      bundle.loadBinaryData(key, _stlParser);
}

extension on AssetBundle {
  Future<T> loadBinaryData<T>(
      String key, FutureOr<T> parser(ByteData bd)) async {
    final data = await load(key);
    return await parser(data);
  }
}

// STL Parser

MeshData _stlParser(ByteData data) => MeshData(_loadSTLMesh(data));

Iterable<Triangle> _loadSTLMesh(ByteData data) sync* {
  final nTriangles = data.getUint32(80, Endian.little);
  for (int i = 0; i < nTriangles; i++) {
    final offset = 84 + i * (4 * 4 * 3 + 2);
    yield _readSTLTriangle(data, offset);
  }
}

Triangle _readSTLTriangle(ByteData data, int offset) => Triangle.points(
    _readSTLVertex(data, offset + 1 * 12),
    _readSTLVertex(data, offset + 2 * 12),
    _readSTLVertex(data, offset + 3 * 12));

Vector3 _readSTLVertex(ByteData data, int offset) => Vector3(
    data.getFloat32(offset, Endian.little),
    data.getFloat32(offset + 4, Endian.little),
    data.getFloat32(offset + 8, Endian.little));
