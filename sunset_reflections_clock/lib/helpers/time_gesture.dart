import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../time_notifier.dart';

class TimeGesture extends StatelessWidget {
  final Widget Function(BuildContext context, DateTime time) builder;

  const TimeGesture({@required this.builder});

  void _horizontalDrag(TimeNotifier tn, DragUpdateDetails drag) {
    _timeUpdate(tn, Duration(minutes: drag.delta.dx.floor()));
  }

  void _verticalDrag(TimeNotifier tn, DragUpdateDetails drag) {
    _timeUpdate(tn, Duration(days: drag.delta.dy.floor()));
  }

  void _timeUpdate(TimeNotifier tn, Duration d) {
    tn.reset(tn.value.add(d));
  }

  @override
  Widget build(BuildContext context) {
    final tn = Provider.of<TimeNotifier>(context);
    return GestureDetector(
        onHorizontalDragUpdate: (drag) => _horizontalDrag(tn, drag),
        onVerticalDragUpdate: (drag) => _verticalDrag(tn, drag),
        child: builder(context, tn.value));
  }
}
