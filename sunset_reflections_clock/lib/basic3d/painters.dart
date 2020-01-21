import '../basic3d/camera_body.dart';
import '../basic3d/textures.dart';
import 'dart:ui';
import 'package:flutter/material.dart' hide Image, Texture;
import 'extensions.dart';

abstract class ClipCoordinatesPainter extends CustomPainter {
  final Rect rect;
  final Rect clip;

  const ClipCoordinatesPainter(this.rect, [this.clip]) : assert(rect != null);

  @override
  void paint(Canvas canvas, Size size) {
    final Matrix4 matrix = Matrix4.diagonal3Values(
            size.width / rect.width, size.height / rect.height, 1) *
        Matrix4.translationValues(-rect.left, -rect.top, 0);

    canvas.transform(matrix.storage);
    if (clip != null) {
      canvas.clipRect(clip, doAntiAlias: false);
    }
  }

  @override
  bool shouldRepaint(ClipCoordinatesPainter oldDelegate) =>
      rect != oldDelegate.rect || clip != oldDelegate.clip;
}

class MeshPainter extends ClipCoordinatesPainter {
  final CameraMesh mesh;
  final Texture texture;
  final Color color;
  final Image image;

  MeshPainter(this.mesh,
      {this.texture, this.color, Image imageTexture, Rect clipRect})
      : image = imageTexture ?? texture?.image,
        super(
            mesh.containingRect.rect,
            clipRect != null
                ? viewportBoundaries(clipRect, mesh.containingRect.rect)
                : null);

  static Rect viewportBoundaries(Rect viewport, Rect body) {
    return viewport.intersect(body);
  }

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);
    // canvas.drawRect(
    //     Offset(-1, -1) & size, Paint()..color = Colors.red.withAlpha(50));
    // canvas.drawRect(Offset(-1, -1) & Size(2, 2),
    //     Paint()..color = Colors.green.withAlpha(50));

    canvas.drawMesh(mesh.vertices,
        texture: texture, color: color, imageTexture: image);
  }

  @override
  bool shouldRepaint(MeshPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      mesh != oldDelegate.mesh ||
      texture != oldDelegate.texture ||
      color != oldDelegate.color ||
      image != oldDelegate.image;
}

class PathPainter extends ClipCoordinatesPainter {
  final CameraPath cPath;
  final Paint brush;

  PathPainter(this.cPath, Paint paint)
      : brush = paint,
        super(cPath.containingRect);

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);

    canvas.drawPath(cPath.path, brush);
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      cPath != oldDelegate.cPath ||
      paint != oldDelegate.paint;
}

extension CustomPainterExt on CustomPainter {
  Future<Image> paintImage(Size size) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    paint(canvas, size);
    final picture = recorder.endRecording();
    return picture.toImage(size.width.floor(), size.height.floor());
  }
}

extension CanvasExt on Canvas {
  void drawMesh(Vertices mesh,
      {Texture texture, Color color, Image imageTexture}) {
    assert(texture != null || color != null);
    assert(!(texture != null && color != null));

    final paint = Paint();
    if (color != null) {
      paint
        ..color = color
        ..style = PaintingStyle.fill;
    } else {
      final image = imageTexture ?? texture.image;
      if (image != null) {
        final matrix =
            Matrix4.diagonal3Values(1 / image.width, 1 / image.height, 1);

        paint.shader = ImageShader(
            image, TileMode.repeated, TileMode.repeated, matrix.storage);
      }
    }

    this.drawVertices(mesh, texture.blendMode ?? BlendMode.src, paint);
  }
}
