import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

// We make the clock run a bit faster since the delay of the animations gives a false sense of unaccuracy
const advanceDuration = Duration(milliseconds: 500);

class TimeNotifier extends ValueNotifier<DateTime> {
  final int timesFaster;
  final Duration updatePeriod;

  int _originInMilliseconds;
  Timer _ticker;

  TimeNotifier(DateTime origin,
      {this.timesFaster = 1, this.updatePeriod = const Duration(minutes: 1)})
      : _originInMilliseconds = origin.millisecondsSinceEpoch,
        super(origin) {
    _startTimer();
  }

  static DateTime of(BuildContext context) =>
      Provider.of<TimeNotifier>(context).value;

  void reset(DateTime v) {
    if (timesFaster != 1) {
      _originInMilliseconds = ((v.millisecondsSinceEpoch -
                  DateTime.now().millisecondsSinceEpoch * timesFaster) /
              (1 - timesFaster))
          .floor();
    }
    value = v;
  }

  void _updateTime(Timer _) {
    value = timesFaster == 1
        ? DateTime.now().add(advanceDuration)
        : DateTime.fromMillisecondsSinceEpoch(_originInMilliseconds +
            (DateTime.now().millisecondsSinceEpoch - _originInMilliseconds) *
                timesFaster);
  }

  void _startTimer() {
    final period = updatePeriod ~/ timesFaster;
    _ticker = Timer(
        timesFaster == 1
            ? _firstTick(DateTime.now().add(advanceDuration))
            : _firstTick(DateTime.now()) ~/ timesFaster, () {
      _ticker = Timer.periodic(period, _updateTime);
      _updateTime(null);
    });
  }

  Duration _firstTick(DateTime time) {
    return updatePeriod -
        Duration(seconds: time.second, milliseconds: time.millisecond);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
