

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:neat_periodic_task/neat_periodic_task.dart';

class MqttBloc extends BlocBase {

  MqttBloc() {
    id = generateRandomString(10);
    checkMqttConnection();
  }

  late String id;
  MqttServerClient? clientMobile;
  MqttConnectMessage? connectMessage;
  var pongCount = 0;

  String generateRandomString(int len) {
    var r = Random();
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890@!#%&';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
  }

  Future<int> connectionMobile() async {
    clientMobile = MqttServerClient.withPort('broker.emqx.io', id, 1883);
    connectMessage = MqttConnectMessage()
        .authenticateAs('rafa160', '123456')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    clientMobile!.logging(on: false);
    clientMobile!.keepAlivePeriod = 20;
    clientMobile!.setProtocolV311();
    clientMobile!.autoReconnect = false;
    clientMobile!.resubscribeOnAutoReconnect = false;
    clientMobile!.onConnected = onConnected;
    clientMobile!.onSubscribeFail = onSubscribeFail;
    clientMobile!.pongCallback = pong;
    clientMobile!.connectionMessage = connectMessage;

    try {
      await clientMobile!.connect();
      print('connected');
    } catch (e) {
      clientMobile!.disconnect();
      return -1;
    }

    if (clientMobile!.connectionStatus!.state == MqttConnectionState.connected) {

      try{
        clientMobile!.published!.listen((MqttPublishMessage message) {
          final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
        });
      } catch (e) {
        print('$e');
      }

    } else {
      clientMobile!.disconnect();
    }

    return 0;

  }

  void publishMessage(){
  }

  // connection succeeded
  Future<void> onConnected() async  {

  }

// unconnected
  void onDisconnected(MqttClient clientServer) {
    clientServer.disconnect();
  }

  void onDisconnectedMobile(MqttServerClient clientServer) {
    clientServer.disconnect();
  }

// subscribe to topic succeeded
  void onSubscribed(MqttClient clientServer,String topic) {
    clientServer.subscribe(topic, MqttQos.atLeastOnce);
  }


  void onSubscribedMobile(MqttServerClient clientServer,String topic) {
    clientServer.subscribe(topic, MqttQos.atLeastOnce);
  }

// subscribe to topic failed
  void onSubscribeFail(String topic) {
  }

// unsubscribe succeeded
  void onUnsubscribed(String topic) {
    clientMobile!.unsubscribe(topic);
  }

// PING response received
  void pong() {
    pongCount++;
  }

  /// Simple task to always make sure the mqtt server is connected.

  late NeatPeriodicTaskScheduler scheduler;

  Future<void> mqttTaskConnection() async {
    scheduler = NeatPeriodicTaskScheduler(
      interval: const Duration(seconds: 15),
      name: 'check-mqtt-connection',
      timeout: const Duration(seconds: 5),
      task: () async => checkMqttConnection(),
      minCycle: const Duration(seconds: 5),
    );
    scheduler.start();
  }


  /// Function to check if the client is null or it disconnected from the
  /// mqtt server.

  void checkMqttConnection() async {
    if (kDebugMode) {
      print('running task...');
    }
    if(clientMobile == null || clientMobile!.connectionStatus!.state == MqttConnectionState.disconnected) {
      await connectionMobile();
      onSubscribedMobile(clientMobile!, 'msg_topic');
    }
  }

  final StreamController<List<MqttReceivedMessage<MqttMessage>>>? streamMqttSensorSubscriptionController =
  StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast();
  Stream<List<MqttReceivedMessage<MqttMessage>>>? get mqttSensorSubscriptionStream => streamMqttSensorSubscriptionController?.stream;
  Sink<List<MqttReceivedMessage<MqttMessage>>>? get mqttSensorSubscriptionSink => streamMqttSensorSubscriptionController?.sink;

  String returnBodyPayload(List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
    var body = jsonDecode(MqttPublishPayload.bytesToStringAsString(message.payload.message));
    return body['msg'];
  }
}