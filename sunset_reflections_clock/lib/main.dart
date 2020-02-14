// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter_clock_helper/customizer.dart';
import 'helpers/sight_tester.dart';
import 'main_model.dart';
import 'themes.dart';
import 'time_notifier.dart';
import 'clock_parts/clock.dart';

const timesFaster = 30;
const testMode = false;

void main() {
  // A temporary measure until Platform supports web and TargetPlatform supports
  // macOS.
  if (!kIsWeb && Platform.isMacOS) {
    // TODO(gspencergoog): Update this when TargetPlatform includes macOS.
    // https://github.com/flutter/flutter/issues/31366
    // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override.
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  runApp(ClockCustomizer((ClockModel model) => VacuumClockApp(model)));
}

class VacuumClockApp extends StatelessWidget {
  const VacuumClockApp(this.model);

  final ClockModel model;

  @override
  Widget build(BuildContext context) {
    // final timeProvider = ChangeNotifierProvider(
    //     create: (context) => TimeNotifier(DateTime.now(), timesFaster: 30));
    final modelProvider = ChangeNotifierProvider.value(value: model);
    final propertiesProvider =
        ChangeNotifierProxyProvider<ClockModel, ClockPropertiesNotifier>(
            create: (context) => ClockPropertiesNotifier(),
            update: (context, model, notifier) =>
                notifier..load(context, model));

    //return MultiProvider(providers: [assetsProvider], child: TestWidget2());
    return MultiProvider(
        providers: [modelProvider, propertiesProvider],
        child: WaitForProperties(
            builder: (context, props) => ChangeNotifierProvider(
                create: (context) =>
                    TimeNotifier(DateTime.now(), timesFaster: timesFaster),
                child: Selector<ClockModel, bool>(
                    selector: (_, model) =>
                        model.weatherCondition == WeatherCondition.sunny,
                    builder: (_, testMode, __) => App(testMode: testMode)))));
  }
}

class App extends StatelessWidget {
  final bool testMode;

  const App({this.testMode = false});

  @override
  Widget build(BuildContext context) {
    return testMode
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Expanded(child: VacuumClock()),
                Expanded(child: SightTester())
              ])
        : VacuumClock();
  }
}

class WaitForProperties extends StatelessWidget {
  final Widget Function(BuildContext context, MainModel properties) builder;

  const WaitForProperties({@required this.builder});

  @override
  Widget build(BuildContext context) {
    final properties = MainModel.of(context);
    return properties != null
        ? builder(context, properties)
        : Container(
            decoration: Theme.of(context).brightness == Brightness.light
                ? lightBackgroundColor
                : darkBackgroundColor,
            child: Center(child: CircularProgressIndicator()));
  }
}
