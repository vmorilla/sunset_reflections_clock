import 'dart:ui';
import 'package:flutter/material.dart' hide Image, Texture;

import '../basic3d/mesh_registry.dart';
import '../basic3d/textures.dart';
import '../basic3d/mesh.dart';
import '../main_model.dart';

import '../basic3d/uvmappers.dart';

class TextureTester extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    final colors = [Colors.white, Colors.black, Colors.blue];
    final blends = List.from(BlendMode.values)..remove(BlendMode.clear);
    final alphas = [50, 125, 250];

    Iterable<Widget> options() sync* {
      for (final blend in blends)
        for (final color in colors)
          for (final alpha in alphas)
            yield _buildChild(props, blend, color.withAlpha(alpha),
                "$blend - ${color.toString()} $alpha");
    }

    final children = options().toList();

    return GridView.count(
        crossAxisCount: colors.length,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: children);
  }

  Widget _buildChild(
      MainModel props, BlendMode blend, Color color, String text) {
    final scene = props.scene;
    final texture = TestTexture(color, blendMode: blend, imageKey: "dark_wood");
    final mesh = props.assets.meshRegistry[Meshes.base];
    final cameraMesh = mesh.render(scene, texture, UVMappers.flatFloor);

    return Stack(fit: StackFit.expand, children: [
      Mesh(cameraMesh.containingRect, mesh: cameraMesh, texture: texture),
      Center(child: Text(text, style: TextStyle(color: color.withAlpha(255))))
    ]);
  }
}
