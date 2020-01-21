import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import '../basic3d/mesh.dart';
import '../main_model.dart';

class TubeGlass extends StatelessWidget {
  final int position;
  const TubeGlass({@required this.position, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    final cache = props.cache[position];

    return Mesh(props.viewPort,
        mesh: cache.tubeVertices, texture: props.tubeTexture, clip: true);
  }
}

class TubeReflection extends StatelessWidget {
  final int position;
  final Image image;
  const TubeReflection({@required this.position, @required this.image, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    final cache = props.cache[position];

    return Mesh(props.viewPort,
        mesh: cache.tubeReflectionVertices,
        texture: props.reflectionTexture,
        imageTexture: image,
        clip: true);
  }
}

class TubeStand extends StatelessWidget {
  final int position;
  const TubeStand({@required this.position, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    final cache = props.cache[position];

    return Mesh(props.viewPort,
        mesh: cache.standVertices, texture: props.standTexture);
  }
}
