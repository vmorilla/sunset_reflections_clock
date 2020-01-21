import 'dart:ui';

import 'package:flutter/material.dart' hide Image, Texture;
import 'package:vector_math/vector_math_64.dart';

import 'clip_coordinates.dart';
import 'textures.dart';
import 'painters.dart';
import 'camera_body.dart';
import 'extensions.dart';

class Mesh extends StatelessWidget {
  final Widget child;
  final Aabb2 viewPort;
  final CameraMesh mesh;
  final Texture texture;
  final Image imageTexture;
  final Color color;
  final bool clip;

  Mesh(this.viewPort,
      {this.child,
      this.mesh,
      this.texture,
      this.color,
      this.imageTexture,
      this.clip = false});

  @override
  Widget build(BuildContext context) {
    return ClipCoordinates(
        container: viewPort.rect,
        rect: mesh.containingRect.rect,
        child: CustomPaint(
          isComplex: true,
          willChange: false,
          child: child,
          painter: MeshPainter(mesh,
              texture: texture,
              color: color,
              imageTexture: imageTexture,
              clipRect: clip ? viewPort.rect : null),
        ));
  }
}
