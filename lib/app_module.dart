import 'dart:io';

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_example/app_widget.dart';
import 'package:mqtt_example/blocs/mqtt_bloc.dart';

class AppModule extends ModuleWidget {

  @override
  List<Bloc> get blocs => [
    Bloc((i) => MqttBloc()),
  ];

  @override
  List<Dependency> get dependencies => [
  ];

  @override
  Widget get view => AppWidget();

  static Inject get to => Inject<AppModule>.of();
}