import 'dart:math' show Random, min;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Aabb2;
import '../flutter_clock_helper/model.dart';
import '../main_model.dart';
import '../basic3d/camera_body.dart';
import '../basic3d/path3d.dart';
import '../basic3d/extensions.dart';

import '../time_notifier.dart';

final _randomizer = Random();

class CathodeSet extends StatelessWidget {
  final int position;

  const CathodeSet({Key key, this.position}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    final cache = props.cache[position];
    final color = props.theme.digitsColors[position];
    final digits = cache.digits;

    final is24HourFormat = Provider.of<ClockModel>(context).is24HourFormat;
    return Selector<TimeNotifier, int>(
        selector: _selector(position, is24HourFormat),
        builder: (_, value, __) => Stack(
            children: digits
                .mapIndex((digit, path) => Cathode(
                    viewPort: props.viewPort,
                    path: path,
                    digit: digit,
                    color: color,
                    value: value))
                .toList()));
  }

  static int _tensOfHours12(BuildContext _, TimeNotifier time) =>
      time.value.hour.remainder(12) ~/ 10;
  static int _unitsOfHours12(BuildContext _, TimeNotifier time) =>
      time.value.hour.remainder(12).remainder(10);
  static int _tensOfHours24(BuildContext _, TimeNotifier time) =>
      time.value.hour ~/ 10;
  static int _unitsOfHours24(BuildContext _, TimeNotifier time) =>
      time.value.hour.remainder(10);
  static int _tensOfMinutes(BuildContext _, TimeNotifier time) =>
      time.value.minute ~/ 10;
  static int _unitsOfMinutes(BuildContext _, TimeNotifier time) =>
      time.value.minute.remainder(10);

  static int Function(BuildContext, TimeNotifier) _selector(
      int position, bool is24HoursFormat) {
    switch (position) {
      case 0:
        return is24HoursFormat ? _tensOfHours24 : _tensOfHours12;
        break;
      case 1:
        return is24HoursFormat ? _unitsOfHours24 : _unitsOfHours12;
        break;
      case 2:
        return _tensOfMinutes;
        break;
      default:
        return _unitsOfMinutes;
        break;
    }
  }
}

class Cathode extends StatelessWidget {
  final Aabb2 viewPort;
  final CameraPath path;
  final Color color;
  final int digit;
  final int value;

  const Cathode({this.viewPort, this.path, this.color, this.digit, this.value});

  @override
  Widget build(BuildContext context) {
    final on = digit == value;
    return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 1000),
        tween: Tween(begin: on ? 0.0 : 1.0, end: on ? 1.0 : 0.0),
        curve: transition(on),
        builder: (context, voltage, _) => Stack(children: [
              Path3D(
                  willChange: voltage != 0 && voltage != 1,
                  viewPort: viewPort,
                  cameraPath: path,
                  paint: glowPaint(voltage)),
              Path3D(
                  willChange: voltage != 0 && voltage != 1,
                  viewPort: viewPort,
                  cameraPath: path,
                  paint: wirePaint(voltage))
            ]));
  }

  Curve transition(bool on) {
    return on
        ? _randomizer.nextInt(5) == 0 ? Curves.elasticInOut : Curves.easeInCubic
        : Curves.easeInCubic;
  }

  static const wireFactor = 300;

  Paint wirePaint(double voltage) {
    final wireColor = Color.lerp(Colors.black, color, 3 * voltage);
    return Paint()
      ..color = wireColor
      ..strokeWidth = (0.9 + 5 * min(1.0, voltage / 0.5)) / wireFactor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4 / wireFactor);
  }

  Paint glowPaint(double voltage) {
    final glowColor = color.withAlpha((voltage * voltage * 255).floor());

    return Paint()
      ..color = glowColor
      ..strokeWidth = 15 / wireFactor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 / wireFactor);
  }
}
