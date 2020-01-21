import 'package:flutter/material.dart' hide Image, Texture;
import '../main_model.dart';
import '../basic3d/mesh.dart';
import 'semantics.dart';
import 'cathode.dart';
import 'grid.dart';
import 'sight_updater.dart';
import 'tube.dart';

class VacuumClock extends StatelessWidget {
  const VacuumClock();

  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    return Container(
      decoration: props.theme.backgroundColor,
      child: Stack(fit: StackFit.expand, children: [
        StaticBackground(),
        Cathodes(),
        StaticForeground(),
        Reflections(),
        AccessibleTime()
      ]),
    );
  }
}

class Table extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final props = MainModel.of(context);
    return Mesh(props.viewPort,
        mesh: props.table, texture: props.tableTexture, clip: true);
  }
}

class StaticBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(children: [
        Table(),
        TubeStand(position: 0),
        TubeStand(position: 1),
        TubeStand(position: 2),
        TubeStand(position: 3),
        BackGrid(position: 0),
        BackGrid(position: 1),
        BackGrid(position: 2),
        BackGrid(position: 3),
      ]);
}

class Cathodes extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(children: [
        RepaintBoundary(child: CathodeSet(position: 0)),
        RepaintBoundary(child: CathodeSet(position: 1)),
        RepaintBoundary(child: CathodeSet(position: 2)),
        RepaintBoundary(child: CathodeSet(position: 3)),
      ]);
}

class StaticForeground extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(children: [
        FrontGrid(position: 0),
        FrontGrid(position: 1),
        FrontGrid(position: 2),
        FrontGrid(position: 3),
        TubeGlass(position: 0),
        TubeGlass(position: 1),
        TubeGlass(position: 2),
        TubeGlass(position: 3),
      ]);
}

class Reflections extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SightUpdater(builder: (_, image) {
        return Stack(children: [
          TubeReflection(position: 0, image: image),
          TubeReflection(position: 1, image: image),
          TubeReflection(position: 2, image: image),
          TubeReflection(position: 3, image: image),
        ]);
      });
}
