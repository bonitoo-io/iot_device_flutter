import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iot_device_flutter/components/influx_scaffold.dart';

import 'package:iot_device_flutter/iot_center_client_dart.dart';
import 'package:iot_device_flutter/main.dart';
import 'package:iot_device_flutter/sensors.dart';

const iotCenterSharedPreferencesKey = "iot-center";
const defaultCenterUrl = "";

/// replace localhost with 10.0.2.2 for android devices
String fixLocalhost(String? url) {
  url ??= "http://localhost:5000";
  if (defaultTargetPlatform == TargetPlatform.android &&
      url.startsWith("http://localhost")) {
    return url.replaceAll("/localhost", "/10.0.2.2");
  }
  return url;
}

const monospaceText = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
);

class HomePage extends StatefulWidget {
  const HomePage(
      {Key? key,
      required this.title,
      required this.client,
      this.saveClient,
      required this.sensors})
      : super(key: key);

  final String title;
  final IotCenterClient client;
  final Future Function(IotCenterClient client)? saveClient;
  final List<SensorInfo> sensors;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final urlController = TextEditingController();
  late final IotCenterClient client;
  final Map<SensorInfo, StreamSubscription<Map<String, double>>> subscriptions =
      {};

  Map<String, String> currentValues = {};
  DateTime? lastDataSent;

  isSubscribed(SensorInfo sensor) {
    return subscriptions.containsKey(sensor);
  }

  subscribe(SensorInfo sensor) {
    if (subscriptions[sensor] != null) return;
    setState(() {
      subscriptions[sensor] = sensor.stream!.listen((metrics) {
        final measurements = metrics.map((key, value) {
          final name = sensor.name + (key != "" ? "_$key" : "");
          return MapEntry(name, value);
        });
        setState(() {
          currentValues[sensor.name] = metrics.entries
              .map((entry) => "${entry.key}=${entry.value.toStringAsFixed(2)}")
              .reduce((value, element) => value + "  " + element);
          lastDataSent = DateTime.now();
        });
        client.writePoint(measurements);
      });
    });
  }

  unsubscribe(SensorInfo sensor) {
    setState(() {
      final subscriptionHandler = subscriptions[sensor];
      subscriptionHandler!.cancel();
      subscriptions.remove(sensor);
      currentValues.remove(sensor.name);
    });
  }

  connectClient() async {
    if (!await client.testConnection()) return;
    if (await client.configure()) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    client = widget.client;

    urlController.text = client.iotCenterUrl;
    urlController.addListener(() {
      setState(() {
        subscriptions.keys.toList().forEach(unsubscribe);
        client.disconnect();
        client.iotCenterUrl = urlController.text;
      });
      AppState.saveClient(client);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InfluxScaffold(
      body: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Column(children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: urlController,
                      ),
                    ),
                    TextButton(
                      child: !client.connected
                          ? const Text("Connect")
                          : const Text("Connected"),
                      onPressed: !client.connected ? connectClient : null,
                    ),
                  ],
                ),
              ]),
            ),
            Card(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: (lastDataSent != null)
                      ? [
                          const Text("Last data sent"),
                          Text(
                              lastDataSent
                                  .toString()
                                  .padRight(26, "0")
                                  .substring(0, 22),
                              style: monospaceText)
                        ]
                      : [
                          Text(client.connected
                              ? "Enable any sensor to send data"
                              : "Connect to iot-center-v2 first")
                        ],
                ),
              ),
            ),
            Expanded(
              child: Card(
                  child: Scrollbar(
                isAlwaysShown: true,
                child: ListView(
                  children: [
                    ...widget.sensors
                        .map((SensorInfo sensor) => SwitchListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sensor.name),
                                  Text(currentValues[sensor.name] ?? "",
                                      style: monospaceText),
                                ],
                              ),
                              value: isSubscribed(sensor),
                              onChanged: client.connected &&
                                      (sensor.availeble ||
                                          sensor.requestPermission != null)
                                  ? ((value) async {
                                      if (!sensor.availeble) {
                                        await sensor.requestPermission!();
                                        if (!sensor.availeble) {
                                          setState(() {});
                                          return;
                                        }
                                      }
                                      value
                                          ? subscribe(sensor)
                                          : unsubscribe(sensor);
                                    })
                                  : null,
                            ))
                        .toList(),
                  ],
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
