import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../clock_parts/sight.dart';
import '../main_model.dart';
import 'time_gesture.dart';

class SightTester extends StatelessWidget {
  final dateFormat = new DateFormat.yMd().add_Hm();
  final dateTimeStyle = TextStyle(
      fontSize: 20,
      color: Colors.white,
      backgroundColor: Colors.black.withAlpha(100));
  final instructionsStyle = TextStyle(fontSize: 10, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    final assets = MainModel.of(context).assets;
    return TimeGesture(
        builder: (context, time) => CustomPaint(
            painter: SightPainter(time, assets.sightData),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Container(
                  //   color: Colors.black.withAlpha(100),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(4.0),
                  //     child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Text(swipeLeftRightMessage(),
                  //               style: instructionsStyle),
                  //           Text(swipeUpDownMessage(),
                  //               style: instructionsStyle),
                  //         ]),
                  //   ),
                  // ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(dateFormat.format(time), style: dateTimeStyle),
                  )
                ])));
  }
}

String swipeLeftRightMessage() =>
    Intl.message("Swipe left or right to change the hour",
        name: "swipeLeftRight");

String swipeUpDownMessage() =>
    Intl.message("Swipe up or down to change the day", name: "swipeLeftRight");
