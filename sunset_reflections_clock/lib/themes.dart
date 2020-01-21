import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

final defaults = ClockTheme(
  backgroundColor: darkBackgroundColor,
  cameraFocusPosition: Vector3(0, 300, 0),
  cameraPosition: Vector3(0, 800, 800),
  digitsColors: List.filled(4, Colors.red),
  gridFractionalDimensions: Vector3(8 / 10, 3 / 4, 6 / 16),
  gridRadius: 10,
  minutesSecondsDistanceRatio: 2,
  moonRelativeSize: 1 / 3,
  reflectionIntensity: 0.2,
  sideMargins: Size(0.01, 0.01),
  tableTexture: "wood",
  tubeDistanceFraction: 1.1,
);

class ClockTheme {
  final BoxDecoration backgroundColor;
  final Vector3 cameraFocusPosition;
  final Vector3 cameraPosition;
  final List<Color> digitsColors;
  final Vector3 gridFractionalDimensions;
  final double gridRadius;
  final double minutesSecondsDistanceRatio;
  final double moonRelativeSize;
  final double reflectionIntensity;
  final Size sideMargins;
  final double tubeDistanceFraction;
  final String tableTexture;

  /// Builds a theme from a selection of configurable parameters.
  /// The following parameters can be provided:
  /// - [backgroundColor]: box decoration used for the background
  /// - [cameraFocusPosition]: point in the scene the camera is pointing at
  /// - [cameraPosition]: position of the camera in the scene
  /// - [digitsColors]: array of the colors of the digits (tens of hours, units of hours, tens of minutes and minutes)
  /// - [gridFractionalDimensions]: dimensions of the grid expressed as a fraction of the size of the tube
  /// - [gridRadius]: radius of the hexagons in the grid (in world size)
  /// - [minutesSecondsDistanceRatio]: separation between minutes and hours expressed as a fraction of the separation between consecutive tubes
  /// - [moonRelativeSize]: size of the moon in relation to the smallest side of the view
  /// - [reflectionIntensity]: intensity of the reflections in the vacuum tubes (0: reflection is not seen, 1: mirror like reflection)
  /// - [sideMargins]: margin between the viewport (the 3d rectangle) and the borders of the containing widget (if the margin is negative, a part of the
  /// - [tableTexture]: image used as a texture for the table
  /// clock won't be displayed)
  /// - [tubeDistanceFraction]: separation between tube expressed as a fraction of the stand width (>= 1)
  ClockTheme({
    BoxDecoration backgroundColor,
    Vector3 cameraFocusPosition,
    Vector3 cameraPosition,
    List<Color> digitsColors,
    Vector3 gridFractionalDimensions,
    double gridRadius,
    double minutesSecondsDistanceRatio,
    double moonRelativeSize,
    double reflectionIntensity,
    Size sideMargins,
    double tubeDistanceFraction,
    String tableTexture,
  })  : this.backgroundColor = backgroundColor ?? defaults.backgroundColor,
        this.cameraFocusPosition =
            cameraFocusPosition ?? defaults.cameraFocusPosition,
        this.cameraPosition = cameraPosition ?? defaults.cameraPosition,
        this.digitsColors = digitsColors ?? defaults.digitsColors,
        this.gridFractionalDimensions =
            gridFractionalDimensions ?? defaults.gridFractionalDimensions,
        this.gridRadius = gridRadius ?? defaults.gridRadius,
        this.minutesSecondsDistanceRatio =
            minutesSecondsDistanceRatio ?? defaults.minutesSecondsDistanceRatio,
        this.moonRelativeSize = moonRelativeSize ?? defaults.moonRelativeSize,
        this.reflectionIntensity =
            reflectionIntensity ?? defaults.reflectionIntensity,
        this.sideMargins = sideMargins ?? defaults.sideMargins,
        this.tubeDistanceFraction =
            tubeDistanceFraction ?? defaults.tubeDistanceFraction,
        this.tableTexture = tableTexture ?? defaults.tableTexture;
}

class ClockThemes {
  static final modern = ClockTheme(
    backgroundColor: lightBackgroundColor,
    tableTexture: "light_wood",
    digitsColors: [
      Colors.cyan[300],
      Colors.red,
      Color.lerp(Colors.orange, Colors.yellow[300], 0.5),
      Colors.green
    ],
    reflectionIntensity: 0.3,
    sideMargins: Size(-0.05, 0.025),
  );

  static final classic = ClockTheme(
      backgroundColor: darkBackgroundColor, tableTexture: "dark_wood");
}

final darkBackgroundColor = BoxDecoration(
  gradient: RadialGradient(
    center: Alignment.topCenter,
    stops: [0.0, 0.9],
    colors: [
      Color(0xFF612828),
      Color(0xFF421264),
    ],
  ),
);

final lightBackgroundColor = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    stops: [0.1, 0.5, 0.7],
    colors: [
      Colors.blueGrey,
      Colors.indigo[600],
      Colors.indigo[400],
    ],
  ),
);
