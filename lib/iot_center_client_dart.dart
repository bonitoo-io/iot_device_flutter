import 'dart:io';

import 'package:influxdb_client/api.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

const udpPort = 5001;
const discoverTimeout = 1500;

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

Future fetchJson(String url, {post = false}) async =>
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

  factory ClientConfig.fromJson(Map<String, dynamic> json) {
    final config = ClientConfig();

    config.influxUrl = json['influx_url'];
    config.influxOrg = json['influx_org'];
    config.influxToken = json['influx_token'];
    config.influxBucket = json['influx_bucket'];
    config.createdAt = json['createdAt'];
    config.id = json['id'];

    return config;
  }

  Map<String, dynamic> toJson() => {
        'influx_url': influxUrl,
        'influx_org': influxOrg,
        'influx_token': influxToken,
        'influx_bucket': influxBucket,
        'createdAt': createdAt,
        'id': id,
      };
}

class IotCenterClient {
  String iotCenterUrl = "";
  String clientID = "";
  String device;
  ClientConfig? config;

  InfluxDBClient? influxDBClient;
  WriteService? writeApi;

  bool get connected {
    return influxDBClient != null;
  }

  Future<bool> testConnection([Duration? timeout]) async {
    try {
      await fetchJson("$iotCenterUrl/api/health")
          .timeout(timeout ?? const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> configure() async {
    final url = "$iotCenterUrl/api/env/$clientID";
    final setDevicePostUrl = "$iotCenterUrl/api/devices/$clientID/type/$device";

    try {
      final rawConfig = await fetchJson(url);
      await fetch(setDevicePostUrl, post: true);
      config = ClientConfig.fromJson(rawConfig);

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

  writePoint(Map<String, double> measurements, [Map<String, String>? sensors]) {
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
    writeApi!.write(
      point,
      bucket: config!.influxBucket,
      org: config!.influxOrg,
    );
  }

  disconnect() async {
    writeApi?.close();
    writeApi = null;
    influxDBClient?.close();
    influxDBClient = null;
  }

  dispose() async {
    disconnect();
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
          .map((event) => "${event!.address.address}:5000")
          .first;
      List<int> data = utf8.encode('IOT_CENTER_URL_REQUEST');
      udpSocket.send(data, broadcast, udpPort);
      return await urlF.timeout(const Duration(milliseconds: discoverTimeout));
    } catch (e) {
      return null;
    } finally {
      udpSocket.close();
    }
  }

  IotCenterClient(this.iotCenterUrl, this.clientID, {this.device = "dart"});

  static IotCenterClient? fromJson(Map<String, dynamic> json) {
    final iotCenterUrl = json['iotCenterUrl'];
    final clientID = json['clientID'];
    if (!(iotCenterUrl is String && clientID is String)) return null;

    final device = json['device'] ?? "dart";

    return IotCenterClient(iotCenterUrl, clientID, device: device);
  }

  Map<String, dynamic> toJson() =>
      {'iotCenterUrl': iotCenterUrl, 'clientID': clientID, 'device': device};
}
