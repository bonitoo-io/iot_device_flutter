import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iot_device_flutter/home_page.dart';
import 'package:iot_device_flutter/iot_center_client_dart.dart';
import 'package:iot_device_flutter/sensors.dart';
import 'package:iot_device_flutter/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

String platformStr = defaultTargetPlatform == TargetPlatform.android
    ? "android"
    : defaultTargetPlatform == TargetPlatform.iOS
        ? "ios"
        : "flutter";

String generateNewId() {
  var uuid = const Uuid();
  return "mobile-" + uuid.v4().replaceAll("-", "");
}

Future saveClient(IotCenterClient client) async {
  final sp = await SharedPreferences.getInstance();
  final json = client.toJson();
  final string = jsonEncode(json);
  sp.setString(iotCenterSharedPreferencesKey, string);
}

Future<IotCenterClient?> loadClient() async {
  try {
    final minLogoTimeFuture =
        Future.delayed(const Duration(milliseconds: 1500));
    final sp = await SharedPreferences.getInstance();
    final str = sp.getString(iotCenterSharedPreferencesKey);
    final json = jsonDecode(str ?? "");
    final client = IotCenterClient.fromJson(json);
    if (client == null) return null;
    if (client.clientID == "") {
      client.clientID = generateNewId();
      await saveClient(client);
    }
    await minLogoTimeFuture;
    return client;
  } catch (e) {
    return null;
  }
}

createDefaultClient() =>
    IotCenterClient("", generateNewId(), device: platformStr);

class AppState {
  IotCenterClient iotCenterClient;
  List<SensorInfo> sensors;

  AppState(this.iotCenterClient, this.sensors);
}

Future<AppState> loadApp() async {
  final sensorsF = Sensors().sensors;
  final clientF = loadClient();
  return AppState(await clientF ?? createDefaultClient(), await sensorsF);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FutureBuilder<AppState>(
            future: loadApp(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data!;
                return HomePage(
                  title: 'Flutter Demo Home Page',
                  client: data.iotCenterClient,
                  saveClient: saveClient,
                  sensors: data.sensors,
                );
              }
              return Container(
                  padding: const EdgeInsets.all(50),
                  decoration: const BoxDecoration(gradient: pinkPurpleGradient),
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                          image:
                              AssetImage("assets/images/influxdata-logo.png"),
                          fit: BoxFit.contain),
                    ),
                  ));
            }));
  }
}
