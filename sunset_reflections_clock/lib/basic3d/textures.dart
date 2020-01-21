import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Image;
import 'package:vector_math/vector_math_64.dart';
import '../utils/math.dart';
import 'scene3d.dart';

const _texturesKeyPrefix = "assets/textures";
const _texturesKeys = ["wood", "plastic", "dark_wood", "light_wood"];

abstract class Texture {
  final Color baseColor;
  final BlendMode blendMode;
  final String imageKey;

  Texture(this.baseColor, this.blendMode, {this.imageKey});

  Color getColor(Scene3d scene, Vector3 position, Vector3 normal);
  Image get image =>
      imageKey != null ? TextureImagesRegistry.instance[imageKey] : null;
}

abstract class Textures {
  static Future<int> registerImages(BuildContext context, [Size size]) =>
      TextureImagesRegistry.instance
          .registerKeys(_texturesKeys, context, size: size);
}

class TestTexture extends Texture {
  TestTexture(Color color, {BlendMode blendMode, String imageKey})
      : super(color, blendMode, imageKey: imageKey);

  @override
  Color getColor(Scene3d scene, Vector3 position, Vector3 normal) {
    final light = scene.light;
    final reflection = scene.cameraFocusDirection
        .dot(light.reflectionAngleAt(position, normal))
        .abs();
    final lightIntensity = light.intensityAt(position, normal);

    final color = Color.fromARGB(
        (baseColor.alpha * pow(reflection, 2)).floor(),
        (baseColor.red * lightIntensity * light.color.red) ~/ 255,
        (baseColor.green * lightIntensity * light.color.green) ~/ 255,
        (baseColor.blue * lightIntensity * light.color.blue) ~/ 255);

    return color;
  }
}

class GlassTexture extends Texture {
  GlassTexture(Color color) : super(color, BlendMode.src);

  final alphaFn = makeInterpolationDouble([0, 0.05, 0.5, 1], [255, 150, 50, 0]);
  final lightFn = makeInterpolationDouble([0, 0.5, 1], [0.0, 0.5, 0.6]);

  @override
  Color getColor(Scene3d scene, Vector3 position, Vector3 normal) {
    final light = scene.light;
    final lightIntensity = lightFn(light.intensityAt(position, normal));
    final cameraAlignment = scene.cameraFocusDirection.dot(normal).abs();

    final color = Color.fromARGB(
        alphaFn(cameraAlignment).floor(),
        (baseColor.red * lightIntensity * light.color.red) ~/ 255,
        (baseColor.green * lightIntensity * light.color.green) ~/ 255,
        (baseColor.blue * lightIntensity * light.color.blue) ~/ 255);

    return color;
  }
}

class OpaqueTexture extends Texture {
  OpaqueTexture(Color color, double glossness,
      {BlendMode blendMode = BlendMode.plus, String imageKey})
      : super(color.withOpacity(glossness), BlendMode.plus, imageKey: imageKey);

  @override
  Color getColor(Scene3d scene, Vector3 position, Vector3 normal) {
    final light = scene.light;
    final lightIntensity = light.intensityAt(position, normal);
    //final cameraAlignment = scene.cameraFocusDirection.dot(normal).abs();

    final color = Color.fromARGB(
        baseColor.alpha,
        (baseColor.red * lightIntensity * light.color.red) ~/ 255,
        (baseColor.green * lightIntensity * light.color.green) ~/ 255,
        (baseColor.blue * lightIntensity * light.color.blue) ~/ 255);

    return color;
  }
}

class MirrorTexture extends Texture {
  MirrorTexture(Color color, double reflectionIntensity)
      : super(color.withOpacity(reflectionIntensity), BlendMode.srcATop);

  @override
  Color getColor(Scene3d scene, Vector3 position, Vector3 normal) => baseColor;
}

class TextureImagesRegistry {
  static final _instance = TextureImagesRegistry._();
  static TextureImagesRegistry get instance => _instance;

  TextureImagesRegistry._();

  Map<String, ImageInfo> _imagesMap = Map<String, ImageInfo>();
  Map<String, ImageStreamListener> _listenersMap =
      Map<String, ImageStreamListener>();
  Map<String, ImageStream> _streamsMap = Map<String, ImageStream>();

  Future<int> registerKeys(Iterable<String> keys, BuildContext context,
      {AssetBundle bundle, Size size}) async {
    final keyList = keys.toList();
    for (final textureKey in keyList) {
      final assetKey = "$_texturesKeyPrefix/$textureKey.jpg";
      final imageProvider = AssetImage(assetKey, bundle: bundle);
      await register(textureKey, imageProvider, context, size);
    }

    return keyList.length;
  }

  Future<void> register(
      String key, ImageProvider imageProvider, BuildContext context,
      [Size size]) {
    final imageConfig = createLocalImageConfiguration(context, size: size);

    final imageStream = imageProvider.resolve(imageConfig);
    final completer = Completer<void>();
    final listener = ImageStreamListener((info, _) {
      _imagesMap[key] = info;
      completer.complete();
    });

    final existingStream = _streamsMap[key];
    if (existingStream?.key != imageStream.key) {
      existingStream?.removeListener(_listenersMap[key]);
      _listenersMap[key] = listener;
      _streamsMap[key] = imageStream;
      imageStream.addListener(listener);

      return completer.future;
    } else
      return Future.value();
  }

  Image operator [](String textureKey) => _imagesMap[textureKey]?.image;
}
