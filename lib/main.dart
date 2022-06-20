import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iot_device_flutter/components/influx_intro_logo.dart';
import 'package:iot_device_flutter/components/styles/influx_styles.dart';
import 'package:iot_device_flutter/home_page.dart';
import 'package:iot_device_flutter/iot_center_client_dart.dart';
import 'package:iot_device_flutter/sensors.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

final String platformStr = defaultTargetPlatform == TargetPlatform.android
    ? "android"
    : defaultTargetPlatform == TargetPlatform.iOS
        ? "ios"
        : "flutter";

String generateNewId() {
  var uuid = const Uuid();
  return clientIdPrefix + uuid.v4().replaceAll("-", "").substring(0, 12);
}

class AppState {
  IotCenterClient iotCenterClient;
  List<SensorInfo> sensors;

  static Future saveClient(IotCenterClient client) async {
    final sp = await SharedPreferences.getInstance();
    final json = client.toJson();
    final string = jsonEncode(json);
    sp.setString(iotCenterSharedPreferencesKey, string);
  }

  static Future<String?> tryDiscover() async {
    try {
      final info = NetworkInfo();
      final wifiAddress = InternetAddress((await info.getWifiIP())!);
      final wifiBroadcastRaw = (await info.getWifiBroadcast());
      if (wifiBroadcastRaw == null) return null;
      var wifiBroadcast = InternetAddress(
          wifiBroadcastRaw.substring(0, 1) == "/"
              ? wifiBroadcastRaw.substring(1)
              : wifiBroadcastRaw);

      return await IotCenterClient.tryObtainUrl(wifiAddress, wifiBroadcast);
    } catch (e) {
      return null;
    }
  }

  static Future<IotCenterClient?> loadClient() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final str = sp.getString(iotCenterSharedPreferencesKey);
      final json = jsonDecode(str ?? "");
      final client = IotCenterClient.fromJson(json);
      if (client == null) return null;
      if (client.clientID == "" || client.clientID == clientIdPrefix) {
        client.clientID = generateNewId();
        await saveClient(client);
      }
      return client;
    } catch (e) {
      return null;
    }
  }

  static Future<IotCenterClient> setupClient() async {
    final discoverFuture = tryDiscover();
    final client = await loadClient() ??
        IotCenterClient("", generateNewId(), device: platformStr);

    if (!await client.testConnection()) {
      final loadedUrl = client.iotCenterUrl;
      final discoverUrl = await discoverFuture;

      if (discoverUrl != null) {
        client.iotCenterUrl = discoverUrl;
        if (await client.testConnection()) {
          saveClient(client);
        } else {
          client.iotCenterUrl = loadedUrl;
        }
      }
    }

    try {
      await client.configure();
      // ignore: empty_catches
    } catch (e) {}
    return client;
  }

  static Future<AppState> loadApp() async {
    final minLogoTimeF = Future.delayed(const Duration(milliseconds: 1500));
    final sensorsF = Sensors().sensors;
    final clientF = setupClient();
    await minLogoTimeF;
    return AppState(await clientF, await sensorsF);
  }

  AppState(this.iotCenterClient, this.sensors);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    precacheImage(
        const AssetImage("assets/images/influxdata-logo.png"), context);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
        title: 'Flutter Demo',
        theme: influxThemeData,
        home: FutureBuilder<AppState>(
            future: AppState.loadApp(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data!;
                return HomePage(
                  title: 'Flutter Demo Home Page',
                  client: data.iotCenterClient,
                  saveClient: AppState.saveClient,
                  sensors: data.sensors,
                );
              }
              return const InfluxIntroLogo();
            }));
  }
}
