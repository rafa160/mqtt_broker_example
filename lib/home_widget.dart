

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_example/app_module.dart';
import 'package:mqtt_example/blocs/mqtt_bloc.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key}) : super(key: key);

  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {

  var mqttBloc = AppModule.to.getBloc<MqttBloc>();
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? homeMqttSensorClient;

  @override
  void initState() {
    startMqttTask();
    homeMqttSensorClient = mqttBloc.clientMobile?.updates?.where((event) => event.first.topic.contains('msg_topic')).listen((event) {
      mqttBloc.mqttSensorSubscriptionSink?.add(event);
    });
    super.initState();
  }

  Future<void> startMqttTask() async {
    await mqttBloc.mqttTaskConnection();
  }

  Future<void> getMessage() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(
              height:  60,
            ),
            const Text('Mqtt Message Payload Test', style: TextStyle(fontSize: 20),),
            const SizedBox(
              height:  60,
            ),
          StreamBuilder<List<MqttReceivedMessage<MqttMessage>>>(
            stream: mqttBloc.mqttSensorSubscriptionStream,
            builder: (ctx, snapshot){
              if(!snapshot.hasData){
                 return const Text('No info');
              }
              else {
                var result = mqttBloc.returnBodyPayload(snapshot.data!);
                return Text(result);
              }
            },
          ),
          ],
        ),
      ),
    );
  }
}
