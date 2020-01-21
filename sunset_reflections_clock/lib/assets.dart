import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Image, Texture;
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import 'basic3d/textures.dart';
import 'basic3d/mesh_registry.dart';
import 'clock_parts/sight.dart';
import 'themes.dart';
import 'main_model.dart';

const prefix = "assets";
const sights = "$prefix/sights";
const meshesKey = "$prefix/3d";
const digitsKey = "$prefix/digits.svg";
const sightKey = "$sights/san_nicolas";

class ClockAssets {
  final MeshRegistry meshRegistry;
  final LinkedHashMap<int, Path> digits;
  final Rect digitsRefRect;
  final SightData sightData;

  ClockAssets._(
      {this.meshRegistry, this.digits, this.digitsRefRect, this.sightData});

  static Future<ClockAssets> load(
      BuildContext context, ClockTheme theme) async {
    final appMaxSize = appSizeInPixels(MediaQuery.of(context));

    final bundle = rootBundle;
    final digits = await bundle.loadStructuredData(digitsKey, svgPathParser);
    final meshRegistry = await MeshRegistry.load(bundle, meshesKey);
    final sightData = await loadSight(context, sightKey, theme);
    await Textures.registerImages(context, appMaxSize);

    return ClockAssets._(
      meshRegistry: meshRegistry,
      digits: digits,
      digitsRefRect: digits[0].getBounds(),
      sightData: sightData,
    );
  }
}

extension LinkedHashMapExt<K, V> on LinkedHashMap<K, V> {
  LinkedHashMap<K2, V> mapKeys<K2>(K2 Function(K) fn) {
    final mappedEntries =
        entries.map((entry) => MapEntry(fn(entry.key), entry.value));
    return LinkedHashMap.fromEntries(mappedEntries);
  }
}

extension SizeExt on Size {
  Size maxFittingRectWithAspectRatio(double aspectRatio) {
    if (aspectRatio > 1)
      return longestSide / shortestSide > aspectRatio
          ? Size(shortestSide * aspectRatio, shortestSide)
          : Size(longestSide, longestSide / aspectRatio);
    else
      return shortestSide / longestSide < aspectRatio
          ? Size(shortestSide, shortestSide / aspectRatio)
          : Size(longestSide * aspectRatio, longestSide);
  }
}

Size appSizeInPixels(MediaQueryData media) =>
    (media.size * media.devicePixelRatio)
        .maxFittingRectWithAspectRatio(appAspectRatio);

Future<LinkedHashMap<int, Path>> svgPathParser(String data) async {
  final doc = parse(data);
  final pathElements = doc.findAllElements("path");
  final idPathPairs = pathElements.map((pathElm) => MapEntry(
      int.parse(pathElm.getAttribute("id")),
      parseSvgPathData(pathElm.getAttribute("d"))));

  return LinkedHashMap.fromEntries((idPathPairs));
}

Future<Image> loadImage(ImageProvider imageProvider, BuildContext context,
    [Size size]) async {
  final imageConfig = createLocalImageConfiguration(context, size: size);

  final completer = Completer<Image>();
  final listener = ImageStreamListener((info, _) {
    completer.complete(info.image);
  });

  final imageStream = imageProvider.resolve(imageConfig);
  imageStream.addListener(listener);

  return completer.future;
}
