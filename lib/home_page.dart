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
const clientIdPrefix = "mobile-";

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
  final clientIdController = TextEditingController();
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

  unsubscribeAll() {
    subscriptions.keys.toList().forEach(unsubscribe);
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
        unsubscribeAll();
        client.disconnect();
        client.iotCenterUrl = urlController.text;
      });
      AppState.saveClient(client);
    });

    clientIdController.text =
        RegExp("^$clientIdPrefix").hasMatch(client.clientID)
            ? client.clientID.substring(clientIdPrefix.length)
            : client.clientID;
    clientIdController.addListener(() {
      setState(() {
        unsubscribeAll();
        client.clientID = "$clientIdPrefix${clientIdController.text}";
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
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(children: [
                  Table(
                    columnWidths: const {0: IntrinsicColumnWidth()},
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text("iot-center url: "),
                        ),
                        TextField(
                          controller: urlController,
                        )
                      ]),
                      TableRow(
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text("clientID: $clientIdPrefix"),
                          ),
                          Row(
                            children: [
                              // const Text(),
                              Expanded(
                                child: TextField(
                                  controller: clientIdController,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: Text(!client.connected ? "Connect" : "Connected"),
                      onPressed: !client.connected ? connectClient : null,
                    ),
                  ),
                ]),
              ),
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
                  child: client.connected
                      ? Scrollbar(
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
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                              alignment: Alignment.topLeft,
                              child: RichText(
                                text: const TextSpan(children: [
                                  // TODO: better explanation
                                  // TODO: show ip in iot-center in case when autodiscover not working ?
                                  TextSpan(
                                      text: "This app is mobile client for "),
                                  TextSpan(
                                      text: "iot-center-v2\n",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  TextSpan(
                                      text:
                                          "To start you will need iot-center-v2 running in your local network"),
                                  TextSpan(
                                      text:
                                          "\n\nYou can download iot-center-v2 at\nhttps://github.com/bonitoo-io/iot-center-v2")
                                ]),
                              )))),
            ),
          ],
        ),
      ),
    );
  }
}
