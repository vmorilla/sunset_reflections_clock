import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../basic3d/clip_coordinates.dart';
import '../time_notifier.dart';
import '../flutter_clock_helper/model.dart';
import '../main_model.dart';
import '../basic3d/extensions.dart';

class AccessibleTime extends StatelessWidget {
  const AccessibleTime();

  @override
  Widget build(BuildContext context) =>
      Selector2<ClockModel, TimeNotifier, String>(
          selector: _formattedTime,
          builder: (_, time, __) => Container(
              child: Semantics(
                  label: clockDescription(),
                  value: time,
                  child: Stack(children: [
                    TubeSemantics(position: 0, value: time[0]),
                    TubeSemantics(position: 1, value: time[1]),
                    TubeSemantics(position: 2, value: time[3]),
                    TubeSemantics(position: 3, value: time[4]),
                  ]))));

  static String _formattedTime(
      BuildContext context, ClockModel model, TimeNotifier timeNotifier) {
    final timeFormat = model.is24HourFormat ? DateFormat.Hm() : DateFormat.jm();
    return timeFormat.format(timeNotifier.value);
  }
}

class TubeSemantics extends StatelessWidget {
  final int position;
  final String value;
  final Widget child;

  const TubeSemantics({Key key, this.position, this.value, this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    final cache = props.cache[position];

    return ClipCoordinates(
        container: props.viewPort.rect,
        rect: cache.frontGrid.containingRect,
        child: Semantics(
            label: tubeDescriptionMessage(position),
            value: value.toString(),
            readOnly: true,
            child: child));
  }
}

String tubeDescriptionMessage(int position) {
  switch (position) {
    case 0:
      return Intl.message(
          "A cold cathode display showing the first digit of the current time hours",
          name: "hourTens");
    case 1:
      return Intl.message(
          "A cold cathode display showing the last digit of the current time hours",
          name: "hourUnits");
    case 2:
      return Intl.message(
          "A cold cathode display showing the first digit of the current time minutes",
          name: "minuteTens");
    default:
      return Intl.message(
          "A cold cathode display showing the last digit of the current time minutes",
          name: "minuteUnits");
  }
}

String clockDescription() =>
    Intl.message("A beautiful clock showing the current time",
        name: "clockDesc");
