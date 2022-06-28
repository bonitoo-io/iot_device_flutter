import 'dart:io';

import 'package:influxdb_client/api.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

const port = 5000;
const udpPort = 5001;
const testConnectionDefaultTimeout = Duration(seconds: 1);
const discoverTimeout = Duration(milliseconds: 1500);

Uri? uriTryParseNoProtocol(String url) => url.substring(0, 4) == "http"
    ? Uri.tryParse(url)
    : Uri.tryParse("http://" + url);

Future<String> fetch(String url, {post = false}) async {
  var uri = uriTryParseNoProtocol(url);

  if (uri == null) {
    throw Exception("invalid url $url");
  }

  var response = await (post ? http.post : http.get)(uri);
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return response.body;
  } else {
    throw Exception('Failed to fetch');
  }
}

Future<dynamic> fetchJson(String url, {post = false}) async =>
    jsonDecode(await fetch(url, post: post));

class NotConnectedException implements Exception {
  @override
  String toString() {
    return "Connect client first";
  }
}

class ClientConfig {
  String influxUrl = '';
  String influxOrg = '';
  String influxToken = '';
  String influxBucket = '';
  String createdAt = '';
  String id = '';

  ClientConfig();

  factory ClientConfig.fromMap(Map<String, dynamic> map) {
    final config = ClientConfig();

    config.influxUrl = map['influx_url'];
    config.influxOrg = map['influx_org'];
    config.influxToken = map['influx_token'];
    config.influxBucket = map['influx_bucket'];
    config.createdAt = map['createdAt'];
    config.id = map['id'];

    return config;
  }

  Map<String, dynamic> toMap() => {
        'influx_url': influxUrl,
        'influx_org': influxOrg,
        'influx_token': influxToken,
        'influx_bucket': influxBucket,
        'createdAt': createdAt,
        'id': id,
      };
}

class IotCenterClient {
  String iotCenterUrl;
  String clientID;
  String device;
  ClientConfig? config;

  InfluxDBClient? influxDBClient;
  WriteService? writeApi;

  bool get connected => influxDBClient != null;

  Future<bool> testConnection([Duration? timeout]) async {
    try {
      await fetchJson("$iotCenterUrl/api/health")
          .timeout(timeout ?? testConnectionDefaultTimeout);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> configure() async {
    final clientIDUri = Uri.encodeComponent(clientID);
    final url = "$iotCenterUrl/api/env/$clientIDUri";
    final setDevicePostUrl =
        "$iotCenterUrl/api/devices/$clientIDUri/type/$device";

    try {
      final rawConfig = await fetchJson(url);
      await fetch(setDevicePostUrl, post: true);
      config = ClientConfig.fromMap(rawConfig);

      /// Fix influx url for docker
      final influxUri = Uri.parse(config!.influxUrl);
      if (influxUri.host == "influxdb_v2") {
        final iotCenterHost = uriTryParseNoProtocol(iotCenterUrl)!.host;
        config!.influxUrl =
            config!.influxUrl.replaceFirst("influxdb_v2", iotCenterHost);
      }

      influxDBClient = InfluxDBClient(
          url: config!.influxUrl,
          token: config!.influxToken,
          bucket: config!.influxBucket,
          debug: false,
          org: config!.influxOrg);
      writeApi = influxDBClient!.getWriteService();
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<void> writePoint(Map<String, double> measurements,
      [Map<String, String>? sensors]) async {
    if (!connected) throw NotConnectedException();
    final point = Point("environment")
        .addTag("clientId", clientID)
        .addTag("device", device)
        .time(DateTime.now().toUtc());
    if (sensors != null) {
      for (var s in sensors.entries) {
        point.addTag("${s.key}Sensor", s.value);
      }
    }
    for (var m in measurements.entries) {
      point.addField(m.key, m.value);
    }
    await writeApi!.write(
      point,
      bucket: config!.influxBucket,
      org: config!.influxOrg,
    );
  }

  Future<void> disconnect() async {
    await writeApi?.close();
    writeApi = null;
    influxDBClient?.close();
    influxDBClient = null;
  }

  Future<void> dispose() async {
    await disconnect();
  }

  static Future<String?> tryObtainUrl(
      InternetAddress selfAddress, InternetAddress broadcast) async {
    final udpSocket = await RawDatagramSocket.bind(selfAddress, udpPort);
    try {
      udpSocket.broadcastEnabled = true;
      final urlF = udpSocket
          .map((event) => udpSocket.receive())
          .where((event) =>
              event != null &&
              String.fromCharCodes(event.data) == "IOT_CENTER_URL_RESPONSE")
          .map((event) => "${event!.address.address}:$port")
          .first;
      List<int> data = utf8.encode('IOT_CENTER_URL_REQUEST');
      udpSocket.send(data, broadcast, udpPort);
      return await urlF.timeout(discoverTimeout);
    } catch (e) {
      return null;
    } finally {
      udpSocket.close();
    }
  }

  IotCenterClient(
      {this.iotCenterUrl = "", this.clientID = "", this.device = "dart"});

  static IotCenterClient fromMap(Map<String, dynamic> map) {
    final iotCenterUrl = map['iotCenterUrl'] ?? "";
    final clientID = map['clientID'] ?? "";
    if (!(iotCenterUrl is String && clientID is String)) throw Error();

    final device = map['device'] ?? "dart";

    return IotCenterClient(
        iotCenterUrl: iotCenterUrl, clientID: clientID, device: device);
  }

  Map<String, dynamic> toMap() =>
      {'iotCenterUrl': iotCenterUrl, 'clientID': clientID, 'device': device};
}
