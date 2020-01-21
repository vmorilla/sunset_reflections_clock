import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart' hide Image;
import '../main_model.dart';

Future<Image> loadImage(ImageProvider image, BuildContext context,
    [Size size]) async {
  final imageConfig = createLocalImageConfiguration(context, size: size);
  final imageStream = image.resolve(imageConfig);
  final completer = Completer<Image>();
  var listener;

  void onImage(ImageInfo info, bool synchronousCall) {
    completer.complete(info.image);
    imageStream.removeListener(listener);
  }

  listener = ImageStreamListener(onImage);
  imageStream.addListener(listener);
  return completer.future;
}

Size maxAppSizeinPixels(BuildContext context) {
  final media = MediaQuery.of(context);
  final size = media.size * media.devicePixelRatio;
  return size.maxFittingRectWithAspectRatio(appAspectRatio);
}

Size maxAppSize(BuildContext context) {
  final media = MediaQuery.of(context);
  return media.size.maxFittingRectWithAspectRatio(appAspectRatio);
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
