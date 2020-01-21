import 'dart:async';
import 'dart:math' show max, min, pi;
import 'dart:ui';

import 'package:flutter/material.dart' hide Image, Texture;
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart'
    show Aabb2, Vector2, Vector3, makePerspectiveMatrix;

import 'basic3d/camera_body.dart';
import 'clock_parts/grid.dart';
import 'basic3d/mesh_registry.dart';
import 'basic3d/scene3d.dart';
import 'basic3d/textures.dart';
import 'assets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'themes.dart';
import 'basic3d/uvmappers.dart';

const appAspectRatio = 5 / 3;

class MainModel {
  final ClockModel model;
  final ClockAssets assets;
  final Texture tubeTexture;
  final Texture reflectionTexture;
  final Texture standTexture;
  final Vector3 tubeDimensions;

  ClockTheme _theme;
  ClockTheme get theme => _theme;
  set theme(ClockTheme newTheme) {
    _theme = newTheme;
    _setTableTexture();
  }

  Texture _tableTexture;
  Texture get tableTexture => _tableTexture;

  Aabb2 _viewPort;
  Scene3d _scene;
  Vector3 _gridDimensions;
  List<RenderCache> _cache;
  CameraMesh _table;

  Scene3d get scene => _scene;
  Vector3 get gridDimensions => _gridDimensions;
  List<Color> get digitsColors => theme.digitsColors;
  List<RenderCache> get cache => _cache;
  Aabb2 get viewPort => _viewPort;
  CameraMesh get table => _table;

  void _setTableTexture() {
    _tableTexture = OpaqueTexture(Colors.black, 0.2,
        blendMode: BlendMode.src, imageKey: theme.tableTexture);
  }

  MainModel(this.model, theme, this.assets)
      : _theme = theme,
        tubeDimensions = assets.meshRegistry[Meshes.tube].dimensions(),
        tubeTexture = GlassTexture(Colors.blue[800]),
        reflectionTexture =
            MirrorTexture(Colors.white, theme.reflectionIntensity),
        standTexture = OpaqueTexture(Colors.white, 0.2, imageKey: "plastic") {
    _setTableTexture();
    _scene = Scene3d(
        cameraPosition: theme.cameraPosition,
        cameraFocusPosition: theme.cameraFocusPosition,
        upDirection: Vector3(0, 1, 0),
        projectionMatrix: makePerspectiveMatrix(pi / 6, 1, 600, 800),
        light: //DirectionalDiffuseLight(
            //direction: Vector3(-3, -1, -1), color: Colors.white)
            PointDiffuseLight(
                position: Vector3(800, 400, 200), color: Colors.white));

    _gridDimensions = Vector3(
        theme.gridFractionalDimensions.x * tubeDimensions.x,
        theme.gridFractionalDimensions.y * tubeDimensions.y,
        theme.gridFractionalDimensions.z * tubeDimensions.z);

    final standDimensions = assets.meshRegistry[Meshes.stand].dimensions();
    final tubeDistance = theme.tubeDistanceFraction * standDimensions.x;
    final minutesSeparation = (theme.tubeDistanceFraction - 1) *
        theme.minutesSecondsDistanceRatio /
        2 *
        standDimensions.x;

    _table = assets.meshRegistry[Meshes.base]
        .render(scene, tableTexture, UVMappers.flatFloor);

    _cache = [0, 1, 2, 3]
        .map((i) => computeCache(Vector3(
            (i - 1.5) * tubeDistance + minutesSeparation * (i < 2 ? -1 : 1),
            0,
            0)))
        .toList();

    _viewPort = Aabb2.centerAndHalfExtents(
        _viewPort.center,
        Vector2(
                (_viewPort.max.x - _viewPort.min.x) /
                    2 *
                    (1 + theme.sideMargins.width),
                (_viewPort.max.y - _viewPort.min.y) / 2) *
            (1 + theme.sideMargins.height));
  }

  static MainModel of(BuildContext context) =>
      Provider.of<ClockPropertiesNotifier>(context).value;

  RenderCache computeCache(Vector3 offset) {
    final tube = assets.meshRegistry[Meshes.tube]
        .transformed(Matrix4.translation(offset));
    final stand = assets.meshRegistry[Meshes.stand]
        .transformed(Matrix4.translation(offset));

    final projectedTubeMesh = tube.render(scene, tubeTexture);
    final projectedStandMesh =
        stand.render(scene, standTexture, UVMappers.cylindrical);
    final projectedReflectionMesh = tube
        .reflectingSubset(Vector3(-3, -1, 0), 0.3)
        .render(scene, reflectionTexture, UVMappers.reflection);

    final tubeRect = projectedTubeMesh.containingRect;
    final standRect = projectedStandMesh.containingRect;
    final vport = Aabb2.minMax(
        Vector2(min(standRect.min.x, tubeRect.min.x),
            min(standRect.min.y, tubeRect.min.y)),
        Vector2(max(standRect.max.x, tubeRect.max.x),
            max(standRect.max.y, tubeRect.max.y)));

    _viewPort = boundingBoxUnion(viewPort, vport);

    final grids = computeGrids(offset);

    return RenderCache(
        tubeVertices: projectedTubeMesh,
        tubeReflectionVertices: projectedReflectionMesh,
        standVertices: projectedStandMesh,
        viewPort: vport,
        frontGrid: CameraPath(grids[0], _flipRectangle(grids[0].getBounds())),
        backGrid: CameraPath(grids[1], _flipRectangle(grids[1].getBounds())),
        digits: computeDigits(offset));
  }

  List<Path> computeGrids(Vector3 translation) {
    Matrix4 shiftMatrix = Matrix4.translation(translation);
    Path dark = Path();
    Path light = Path();

    void add(Path parentPath, Path basePath, Matrix4 modelTransform) {
      final Matrix4 transform = scene.viewMatrix * shiftMatrix * modelTransform;
      final path = basePath.transform(transform.storage);
      parentPath.addPath(path, Offset.zero);
    }

    final front = gridPath(
        Rect.fromCenter(
            center: Offset(0, gridDimensions.y / 2),
            width: gridDimensions.x,
            height: gridDimensions.y),
        theme.gridRadius);

    final top = gridPath(
        Rect.fromCenter(
            center: Offset.zero,
            width: gridDimensions.x,
            height: gridDimensions.z),
        theme.gridRadius);

    final side = gridPath(
        Rect.fromCenter(
            center: Offset(0, gridDimensions.y / 2),
            width: gridDimensions.z,
            height: gridDimensions.y),
        theme.gridRadius);

    // Front
    add(dark, front, Matrix4.translation(Vector3(0, 0, gridDimensions.z / 2)));

    // Top
    add(
        dark,
        top,
        Matrix4.translation(Vector3(0, gridDimensions.y, 0)) *
            Matrix4.rotationX(pi / 2));

    // Back
    add(light, front,
        Matrix4.translation(Vector3(0, 0, -gridDimensions.z / 2)));

    // Right
    add(
        light,
        side,
        Matrix4.translation(Vector3(gridDimensions.x / 2, 0, 0)) *
            Matrix4.rotationY(pi / 2));

    // Left
    add(
      light,
      side,
      Matrix4.translation(Vector3(-gridDimensions.x / 2, 0, 0)) *
          Matrix4.rotationY(pi / 2),
    );

    return [dark, light];
  }

  List<CameraPath> computeDigits(Vector3 translation) {
    final digitsRefRect = assets.digitsRefRect;
    final centerMatrix = Matrix4.translationValues(
        -digitsRefRect.center.dx, -digitsRefRect.bottom, 0);

    final scaleMatrix = Matrix4.diagonal3Values(
        gridDimensions.x / digitsRefRect.width,
        -gridDimensions.y / digitsRefRect.height,
        1);

    final offsetMatrix = Matrix4.translation(translation);
    final worldMatrixBeforeZ = offsetMatrix * scaleMatrix * centerMatrix;

    final paths = List<Path>(10);
    assets.digits.forEachIndex((index, digit, path) {
      final zTranslation = Matrix4.translationValues(
          0, 0, gridDimensions.z * ((1 + index) / 11 - 1 / 2));
      paths[digit] = path.transform(
          (scene.viewMatrix * zTranslation * worldMatrixBeforeZ).storage);
    });

    final camPaths =
        paths.map((p) => CameraPath(p, _flipRectangle(p.getBounds()))).toList();

    return camPaths;
  }
}

class RenderCache {
  final CameraMesh tubeVertices;
  final CameraMesh tubeReflectionVertices;
  final CameraMesh standVertices;
  final CameraPath frontGrid;
  final CameraPath backGrid;
  final Aabb2 viewPort;
  final List<CameraPath> digits;

  RenderCache(
      {this.tubeVertices,
      this.tubeReflectionVertices,
      this.standVertices,
      this.viewPort,
      this.frontGrid,
      this.backGrid,
      this.digits});
}

Aabb2 boundingBoxUnion(Aabb2 a, Aabb2 b) {
  if (a == null) return b;
  if (b == null) return a;

  return Aabb2.minMax(Vector2(min(a.min.x, b.min.x), min(a.min.y, b.min.y)),
      Vector2(max(a.max.x, b.max.x), max(a.max.y, b.max.y)));
}

class ClockPropertiesNotifier extends ValueNotifier<MainModel> {
  ClockPropertiesNotifier() : super(null);

  void load(BuildContext context, ClockModel model) {
    final theme = Theme.of(context);
    final newTheme = theme.brightness == Brightness.light
        ? ClockThemes.modern
        : ClockThemes.classic;

    if (newTheme != value?.theme) {
      if (value?.assets == null) {
        ClockAssets.load(context, newTheme).then((assets) {
          final props = MainModel(model, newTheme, assets);
          value = props;
        });
      } else {
        scheduleMicrotask(() {
          final oldTheme = value.theme;
          // avoid 3d computations if not necessary
          if (newTheme.gridRadius != oldTheme.gridRadius ||
              newTheme.cameraFocusPosition != oldTheme.cameraFocusPosition ||
              newTheme.cameraPosition != oldTheme.cameraPosition ||
              newTheme.gridFractionalDimensions !=
                  oldTheme.gridFractionalDimensions ||
              newTheme.minutesSecondsDistanceRatio !=
                  oldTheme.minutesSecondsDistanceRatio ||
              newTheme.tubeDistanceFraction != oldTheme.tubeDistanceFraction) {
            final props = MainModel(model, newTheme, value.assets);
            value = props;
          } else {
            value.theme = newTheme;
            notifyListeners();
          }
        });
      }
    }
  }
}

extension<T> on List<T> {
  void forEachIndex(void Function(int index, T value) fn) {
    for (final entry in toList().asMap().entries) fn(entry.key, entry.value);
  }
}

Rect _flipRectangle(Rect rect) =>
    Rect.fromLTRB(rect.left, rect.bottom, rect.right, rect.top);
