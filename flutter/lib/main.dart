import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pibot_flutter/screens/connect.dart';
import 'package:pibot_flutter/screens/control.dart';

void main() {
  runApp(const PiBotApp());
}

class PiBotApp extends StatelessWidget {
  const PiBotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: 'PiBot',
        themeMode: ThemeMode.dark,
        home: LaunchPage(),
    );
  }
}

class LaunchPage extends StatefulWidget {
  const LaunchPage({Key? key}) : super(key: key);

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  static const String _topic = "pibot/move";
  MqttServerClient? _client;

  void _sendMessage(String command, {List<String>? args}) {
    if (_client == null) return;

    final parts = [command, ...(args ?? [])];

    final builder = MqttClientPayloadBuilder();
    builder.addString(parts.join(" "));

    _client?.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
  }

  void _onDisconnected() {
    print('PiBot::disconnected');
    Fluttertoast.showToast(
        msg: "Disconnected",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
    );

    _setClient(null);
  }

  void _setAddress(String address) async {
    final parts = address.split(":");
    MqttServerClient client;
    if (parts.length == 2) {
      client = MqttServerClient.withPort(parts[0], '', int.parse(parts[1]))
          ..logging(on: false)
          ..setProtocolV311();
    } else {
      client = MqttServerClient(address, '')
          ..logging(on: false)
          ..setProtocolV311();
    }
    client.keepAlivePeriod = 300; // keep alive for 5 mins
    client.onDisconnected = _onDisconnected;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('PiBot::client exception - $e');
      Fluttertoast.showToast(
          msg: "Failed to connect: NoConnectionException",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
      );
      client.disconnect();
      return;
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('PiBot::socket exception - $e');
      Fluttertoast.showToast(
          msg: "Failed to connect: SocketException",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
      );
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state != MqttConnectionState.connected) {
      print('PiBot::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      Fluttertoast.showToast(
          msg: "Failed to connect, status is ${client.connectionStatus}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
      );
      client.disconnect();
      return;
    }

    _setClient(client);
  }

  void _setClient(MqttServerClient? client) {
    setState(() {
      _client = client;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("PiBot"),
      ),
      body: Center(
        child: (_client == null) ? ConnectScreen(onSubmit: _setAddress) : ControlScreen(sendMessage: _sendMessage)
        // child: Column(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: <Widget>[
        //     const Text(
        //       'You have pushed the button this many times:',
        //     ),
        //     Text(
        //       '$_counter',
        //       style: Theme.of(context).textTheme.headline4,
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
