import 'package:flutter/material.dart';
import 'package:iot_device_flutter/components/influx_scaffold.dart';

import 'package:iot_device_flutter/iot_center_client_dart.dart';
import 'package:iot_device_flutter/main.dart';
import 'package:iot_device_flutter/sensors.dart';

import 'components/styles/utils.dart';

const iotCenterSharedPreferencesKey = "iot-center";
const defaultCenterUrl = "";
const clientIdPrefix = "mobile-";

String trimClientIdPrefix(String clientID) =>
    RegExp("^$clientIdPrefix").hasMatch(clientID)
        ? clientID.substring(clientIdPrefix.length)
        : clientID;

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.client, required this.sensors})
      : super(key: key);

  final IotCenterClient client;
  final List<SensorInfo> sensors;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final urlController = TextEditingController();
  final clientIdController = TextEditingController();
  final SensorsSubscriptionManager subscriptionManager =
      SensorsSubscriptionManager();
  late final IotCenterClient client;

  Future<void> connectClient() async {
    if (!await client.testConnection()) return;
    if (await client.configure()) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {});
    }
  }

  void onData(SensorMeasurement measure, SensorInfo sensor) {
    client.writePoint(
        SensorsSubscriptionManager.addNameToMeasure(sensor, measure));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    client = widget.client;

    urlController.text = client.iotCenterUrl;
    urlController.addListener(() {
      setState(() {
        subscriptionManager.unsubscribeAll();
        client.disconnect();
        client.iotCenterUrl = urlController.text;
      });
      AppState.saveClient(client);
    });

    clientIdController.text = trimClientIdPrefix(client.clientID);
    clientIdController.addListener(() {
      setState(() {
        subscriptionManager.unsubscribeAll();
        client.clientID = "$clientIdPrefix${clientIdController.text}";
      });
      AppState.saveClient(client);
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionForm = Container(
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
    );

    final lastDataSentText = Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: (subscriptionManager.lastDataRead != null)
            ? [
                const Text("Last data sent"),
                Text(
                    subscriptionManager.lastDataRead
                        .toString()
                        .padRight(26, "0")
                        .substring(0, 22),
                    style: textStyleMonospace)
              ]
            : [
                Text(client.connected
                    ? "Enable any sensor to send data"
                    : "Connect to iot-center-v2 first")
              ],
      ),
    );

    createSensorSwitchListTile(SensorInfo sensor) => SwitchListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sensor.name),
              Text(
                  subscriptionManager
                      .lastValueOf(sensor)
                      .entries
                      .map((entry) =>
                          "${entry.key}=${entry.value.toStringAsFixed(2)}")
                      .join(" "),
                  style: textStyleMonospace),
            ],
          ),
          value: subscriptionManager.isSubscribed(sensor),
          onChanged: (sensor.availeble || sensor.requestPermission != null)
              ? ((value) async {
                  if (value) {
                    await subscriptionManager.trySubscribe(sensor, onData);
                  } else {
                    subscriptionManager.unsubscribe(sensor);
                  }
                  setState(() {});
                })
              : null,
        );

    final sensorsListView = Scrollbar(
      isAlwaysShown: true,
      child: ListView(
        children: widget.sensors.map(createSensorSwitchListTile).toList(),
      ),
    );

    final notConnectedText = Container(
        padding: const EdgeInsets.all(16),
        child: Align(
            alignment: Alignment.topLeft,
            child: RichText(
              text: const TextSpan(children: [
                TextSpan(text: "This app is mobile client for "),
                TextSpan(
                    text: "iot-center-v2\n",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        "To start you will need iot-center-v2 running in your local network"),
                TextSpan(
                    text:
                        "\n\nYou can download iot-center-v2 at\nhttps://github.com/bonitoo-io/iot-center-v2")
              ]),
            )));

    return InfluxScaffold(
      body: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(child: connectionForm),
            Card(child: lastDataSentText),
            Expanded(
              child: Card(
                child: client.connected ? sensorsListView : notConnectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
