import 'package:influxdb_client/api.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

fetchJson(String url) async {
  var uri = Uri.tryParse(url) ?? Uri.tryParse("http://" + url);

  if (uri == null) {
    throw Exception("invalid url $url");
  }

  var response = await http.get(uri);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch');
  }
}

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

  final clientConfig = ClientConfig();

  configure() async {
    final url = "$iotCenterUrl/api/env/$clientID";
    try {
      final rawConfig = await fetchJson(url);
      config = ClientConfig.fromJson(rawConfig);
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

  writePoint(Map<String, double> measurements, Map<String, String>? sensors) {
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
      bucket: clientConfig.influxBucket,
      org: clientConfig.influxOrg,
    );
  }

  disconnect() async {
    writeApi?.close();
    writeApi = null;
    influxDBClient?.close();
    influxDBClient = null;
  }

  // TODO: dispose sensors and iotCenterClient when closing app
  dispose() async {
    disconnect();
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
