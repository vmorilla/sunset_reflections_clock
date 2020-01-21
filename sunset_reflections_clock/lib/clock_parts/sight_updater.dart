import 'dart:ui';

import 'package:flutter/material.dart' hide Image, Texture;
import 'package:provider/provider.dart';
import 'sight.dart';
import '../utils/images.dart';
import '../main_model.dart';
import '../time_notifier.dart';

class SightUpdater extends StatelessWidget {
  final Widget Function(BuildContext, Image) builder;

  const SightUpdater({Key key, @required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<TimeNotifier, List<int>>(
      selector: SightUpdater._roundedTime,
      builder: _sightBuilder,
    );
  }

  Widget _sightBuilder(BuildContext context, List<int> timeValues, Widget _) {
    final time = DateTime.utc(timeValues[0], timeValues[1], timeValues[2],
        timeValues[3], timeValues[4]);
    final assets = MainModel.of(context).assets;
    return _SightImageFuture(
        sight: assets.sightData, time: time, builder: builder);
  }

  static List<int> _roundedTime(
      BuildContext context, TimeNotifier timeNotifier) {
    final delayed = timeNotifier.value.subtract(Duration(seconds: 30));
    return [
      delayed.year,
      delayed.month,
      delayed.day,
      delayed.hour,
      delayed.minute
    ];
  }
}

class _SightImageFuture extends StatefulWidget {
  final SightData sight;
  final DateTime time;
  final Widget Function(BuildContext context, Image image) builder;

  const _SightImageFuture({Key key, this.sight, this.time, this.builder})
      : super(key: key);

  @override
  _SightImageFutureState createState() => _SightImageFutureState();
}

class _SightImageFutureState extends State<_SightImageFuture> {
  bool _loading = false;
  Image _image;

  @override
  void didChangeDependencies() {
    _updateImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(_SightImageFuture oldWidget) {
    if (oldWidget.sight != widget.sight || oldWidget.time != widget.time)
      _updateImage();
    super.didUpdateWidget(oldWidget);
  }

  void _updateImage() {
    if (!_loading) {
      _loading = true;
      final size = maxAppSize(context);
      // This way the tester runs more smoothly except for the first, since we don't
      // want the clock to appear with no reflections
      final delay =
          _image == null ? Duration(seconds: 0) : Duration(seconds: 5);
      Future.delayed(delay).then((_) {
        if (mounted) {
          widget.sight.render(widget.time, size).then((im) {
            setState(() {
              _image = im;
              _loading = false;
            });
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      _image != null ? widget.builder(context, _image) : Container();
}
