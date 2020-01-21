import 'dart:convert';
import 'dart:math' show sin;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:flutter_suncalc/flutter_suncalc.dart';
import 'dart:ui';

import '../themes.dart';
import '../basic3d/painters.dart';
import '../utils/images.dart';
import '../utils/math.dart';

enum SightImages { night, day, moon }

Future<SightData> loadSight(
    BuildContext context, String sightKey, ClockTheme theme) async {
  final bundle = DefaultAssetBundle.of(context);
  final moonSize =
      (maxAppSizeinPixels(context).shortestSide * theme.moonRelativeSize)
          .floor();

  final moon = ResizeImage(AssetImage("$sightKey/full-moon.png"),
      width: moonSize, height: moonSize);
  final sightData = await bundle.loadStructuredData("$sightKey/desc.json",
      (data) => _sightParser(data, moon, bundle, sightKey, context));

  return sightData;
}

class SightData {
  final String name;
  final String description;
  final GPSCoordinates gps;
  final Ecliptic ecliptic;
  final Map<SightImages, Image> images;
  final Size size;

  Future<Image> render(DateTime time, Size size) async {
    final painter = SightPainter(time, this);
    final image = await painter.paintImage(size);
    return image;
  }

  SightData({this.name, this.description, this.gps, this.ecliptic, this.images})
      : size = Size(images[SightImages.day].width.toDouble(),
            images[SightImages.day].height.toDouble());

  Offset absoluteCelestialPosition(double azimuth, double altitude) {
    return ecliptic
        .relativeCelestialPosition(azimuth, altitude)
        .scale(size.width, size.height);
  }

  Map<String, DateTime> getSunTimes(DateTime date) =>
      SunCalc.getTimes(date, gps.latitude, gps.longitude);

  Offset moonPosition(DateTime time) => _sunCalcCelestialPosition(
      SunCalc.getMoonPosition(time, gps.latitude, gps.longitude));

  double moonParallacticAngle(DateTime time) => SunCalc.getMoonPosition(
      time, gps.latitude, gps.longitude)["parallacticAngle"];

  static double moonIlluminationFraction(DateTime time) =>
      SunCalc.getMoonIllumination(time)["fraction"];

  Offset sunPosition(DateTime time) => _sunCalcCelestialPosition(
      SunCalc.getSunPosition(time, gps.latitude, gps.longitude));

  Offset _sunCalcCelestialPosition(Map<String, num> position) =>
      absoluteCelestialPosition(position["azimuth"], position["altitude"]);

  Rect get eclipticRect => Rect.fromLTRB(
      ecliptic.east * size.width,
      ecliptic.zenith * size.height,
      ecliptic.west * size.width,
      ecliptic.horizon * size.height);
}

class Ecliptic {
  final double zenith;
  final double horizon;
  final double east;
  final double west;

  Ecliptic({this.zenith, this.east, this.horizon, this.west});

  Size get size => Size(west - east, zenith - horizon);
  Rect get rect => Rect.fromLTRB(east, zenith, east, horizon);

  Offset relativeCelestialPosition(double azimuth, double altitude) {
    final x = east + size.width * (1 + sin(azimuth)) / 2;
    final y = horizon + size.height * sin(altitude);

    return Offset(x, y);
  }
}

class GPSCoordinates {
  final double latitude;
  final double longitude;

  GPSCoordinates(this.latitude, this.longitude);
}

class SightPainter extends CustomPainter {
  final SightData sight;
  final DateTime now;

  static const sunAuraColor = Color(0xFFFFF4BC);
  static const sunHubColor = Color(0xFFFFFEFA);
  static const sunRimColor = Color(0xFFFFFCE1);

  //static const darkNightBlue = Color(0xFF141654);
  static const darkNightBlue = Color(0xFF000d1a);

  static final List<Color> skyColors = _mirror([
    darkNightBlue, // midnight
    Color(0xFF45385B), // night end / night starts
    Color(0xFFAC748F), // dawn / dusk
    Color(0xFF3c84a7), // sunrise end / sunset starts
    Color(0xFF87CEEB), // noon
  ]);

  static final List<double> cityLuminosity = _mirror([
    0, // midnight
    0, // night end / night starts
    0.2, // dawn / dusk
    1, // sunrise end / sunset starts
    1, // noon
  ]);

  SightPainter(this.now, this.sight);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size, doAntiAlias: false);
    // Coordinates scaled to the size of the image
    canvas.scale(
        size.width / sight.size.width, size.height / sight.size.height);

    final sunPosition = sight.sunPosition(now);
    final moonPosition = sight.moonPosition(now);
    final dayRange = timesRange(now);
    final skyColorFn = makeInterpolation(dayRange, skyColors, Color.lerp);
    final skyColor = skyColorFn(_timeToMinutes(now));

    final luminosityFn = makeInterpolationDouble(dayRange, cityLuminosity);
    final luminosity = luminosityFn(_timeToMinutes(now));

    _drawSky(canvas, skyColor, luminosity, sunPosition, sight.size);
    _drawSun(canvas, sunPosition, radius: 100);
    _drawMoon(canvas, moonPosition, sight.moonParallacticAngle(now),
        SightData.moonIlluminationFraction(now));

    _drawCity(canvas, luminosity);
    //_drawColorTester(canvas, skyColors, dayRange);
  }

  void _drawSun(Canvas canvas, Offset position, {double radius = 10}) {
    const sunGradient = RadialGradient(colors: [sunHubColor, sunRimColor]);

    final sunRect = Rect.fromCenter(
        center: position, width: radius * 2, height: radius * 2);

    final sunPaint = Paint()
      ..shader = sunGradient.createShader(sunRect)
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, radius);

    canvas.drawOval(sunRect, sunPaint);
  }

  // void _drawColorTester(Canvas canvas, List<Color> colors, List<double> times) {
  //   final size = sight.size;
  //   final inputRange = times.map((t) => t / (24 * 60)).toList();
  //   final interpolate = makeInterpolation(inputRange, colors, Color.lerp, 0, 1);
  //   final nSteps = 100;

  //   for (int i = 0; i < nSteps; i++) {
  //     final color = interpolate(i / nSteps);
  //     canvas.drawRect(
  //         Rect.fromLTWH(
  //             i * size.width / nSteps, 0, size.width / nSteps, size.height / 5),
  //         Paint()
  //           ..color = color
  //           ..style = PaintingStyle.fill);
  //   }

  //   for (final time in times) {
  //     final t = time / (24 * 60) * size.width;
  //     canvas.drawPoints(
  //         PointMode.polygon,
  //         [
  //           Offset(t - size.width / nSteps, 0),
  //           Offset(t + size.width / nSteps, 0),
  //           Offset(t, size.width / nSteps),
  //           Offset(t - size.width / nSteps, 0),
  //         ],
  //         Paint()
  //           ..color = Colors.white
  //           ..style = PaintingStyle.stroke
  //           ..strokeWidth = 5);
  //   }
  // }

  /// Draws the night and day images of the [Sight]
  /// The day image is modulated with transparency depending on the luminosity.
  void _drawCity(Canvas canvas, double luminosity) {
    canvas.drawImage(sight.images[SightImages.night], Offset.zero, Paint());
    final dayImage = sight.images[SightImages.day];
    final points = [
      Offset(0, 0),
      Offset(dayImage.width.toDouble(), 0),
      Offset(dayImage.width.toDouble(), dayImage.height.toDouble()),
      Offset(0, dayImage.height.toDouble())
    ];
    final vertices = Vertices(VertexMode.triangleFan, points,
        textureCoordinates: points,
        colors: List.filled(4, Colors.white.withOpacity(luminosity)));
    final dayPaint = Paint()
      ..shader = ImageShader(dayImage, TileMode.repeated, TileMode.repeated,
          Matrix4.identity().storage);
    canvas.drawVertices(vertices, BlendMode.modulate, dayPaint);
  }

  void _drawMoon(Canvas canvas, Offset moonPosition, double parallacticAngle,
      double illuminationFraction) {
    final moon = sight.images[SightImages.moon];

    Path oval(double minRadius) => Path()
      ..addOval(Rect.fromCenter(
          center: Offset.zero, width: minRadius * 2, height: 2));

    final moonRadius = moon.width / 2.0;
    final Matrix4 tMatrix =
        Matrix4.translationValues(moonPosition.dx, moonPosition.dy, 0) *
            Matrix4.diagonal3Values(moonRadius * 1.1, moonRadius * 1.1, 1) *
            Matrix4.rotationZ(parallacticAngle);

    Path moonShadow = Path.combine(PathOperation.intersect,
        Path()..addRect(Rect.fromLTRB(-1, -1, 0, 1)), oval(1));
    if (illuminationFraction > 0.5) {
      moonShadow = Path.combine(PathOperation.difference, moonShadow,
          oval(illuminationFraction * 2 - 1));
    } else {
      moonShadow = Path.combine(
          PathOperation.union, moonShadow, oval(illuminationFraction * 2 - 1));
    }

    // const moonlightGradient =
    //     RadialGradient(colors: [Color(0xFFFFFEFA), Color(0xFFFFFCE1)]);

    // final sunPaint = Paint()
    //   ..shader = sunGradient.createShader(sunRect)
    //   ..maskFilter = MaskFilter.blur(BlurStyle.solid, radius);
    canvas.saveLayer(
        Rect.fromCenter(
            center: moonPosition,
            width: moonRadius * 2,
            height: moonRadius * 2),
        Paint()..blendMode = BlendMode.screen);

    canvas.drawImage(
        moon, moonPosition - Offset(moonRadius, moonRadius), Paint());
    canvas.drawPath(
        moonShadow.transform(tMatrix.storage),
        Paint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, moonRadius / 10)
          ..color = Colors.black
          ..style = PaintingStyle.fill);

    canvas.restore();
  }

  void _drawSky(
      Canvas canvas, Color skyColor, double light, Offset center, Size size) {
    // final testColors = [
    //   Colors.black,
    //   Colors.black,
    //   Colors.cyan,
    //   Colors.red,
    //   Colors.yellow
    // ];
    final colors = [
      sunAuraColor,
      sunAuraColor,
      Color.lerp(sunAuraColor, skyColor, 0.8),
      Color.lerp(sunAuraColor, skyColor, 0.9),
      skyColor
    ];
    final stops = [0.01, 0.015, 0.022, 0.1, 0.2];

    final skyGradient = RadialGradient(colors: colors, stops: stops
        //radius: 0.01 + (1 - light) / 20 //Color(0xFF4C81C3)],
        );
    final rect = Rect.fromCenter(
        center: center, width: size.width * 10, height: size.height * 10);

    final paint = Paint()..shader = skyGradient.createShader(rect);

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(SightPainter oldDelegate) =>
      oldDelegate.sight != sight || oldDelegate.now != now;

  List<double> timesRange(DateTime time) {
    final sunTimes =
        sight.getSunTimes(time).map((k, v) => MapEntry(k, _timeToMinutes(v)));

    return [
      0.0,
      sunTimes["nightEnd"],
      sunTimes["dawn"],
      sunTimes["sunriseEnd"],
      sunTimes["solarNoon"],
      sunTimes["sunsetStart"],
      sunTimes["dusk"],
      sunTimes["night"],
      Duration.minutesPerDay.toDouble()
    ];
  }

  double _timeToMinutes(DateTime t) {
    return (t.hour * 60 + t.minute).toDouble();
  }
}

List<T> _mirror<T>(List<T> a) {
  final reversed = a.reversed.toList()..remove(a.last);
  return List.unmodifiable(List<T>.from(a)..addAll(reversed));
}

Future<SightData> _sightParser(String text, ImageProvider moon,
    AssetBundle bundle, String assetsPrefix, BuildContext context) async {
  Future<MapEntry<SightImages, Image>> parsePictureEntry(
      MapEntry<String, dynamic> entry) async {
    final enumMap = {"night": SightImages.night, "day": SightImages.day};

    final img =
        await loadImage(AssetImage("$assetsPrefix/${entry.value}"), context);
    return MapEntry(enumMap[entry.key], img);
  }

  Future<Map<SightImages, Image>> parsePictures(
      Map<String, Object> pictures) async {
    final entriesFuture = pictures.entries.map(parsePictureEntry);
    final entries = await Future.wait(entriesFuture);
    return Map.fromEntries(entries);
  }

  final parsers = {
    "gps": (v) => GPSCoordinates(v["lat"], v["lon"]),
    "ecliptic": (v) => Ecliptic(
        east: v["east"],
        zenith: v["zenith"],
        west: v["west"],
        horizon: v["horizon"]),
    "pictures": parsePictures
  };

  final jsonMap = jsonDecode(text, reviver: (key, value) {
    final parser = key != null ? parsers[key] : null;
    return parser != null ? parser(value) : value;
  });

  final Map<SightImages, Image> images = await jsonMap["pictures"];
  images[SightImages.moon] = await loadImage(moon, context);

  return SightData(
      name: jsonMap["name"],
      description: jsonMap["description"],
      gps: jsonMap["gps"],
      ecliptic: jsonMap["ecliptic"],
      images: images);
}
